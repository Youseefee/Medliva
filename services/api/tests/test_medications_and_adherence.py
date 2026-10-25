import uuid
from datetime import UTC, datetime

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_medications_crud_and_adherence(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201033334444", name="مريض السكر")
    patient_id = str(patient.id)
    headers = {"Authorization": f"Bearer {patient.id}"}

    # 1. Create medication with schedules
    med_res = await client.post(
        f"/api/v1/patients/{patient_id}/medications",
        json={
            "name": "Glucophage 500mg",
            "trade_name": "Glucophage",
            "strength": "500mg",
            "stock_count": 30,
            "alert_threshold_days": 5,
            "schedules": [
                {
                    "time_of_day": "08:30",
                    "dose_amount": 1.0,
                    "meal_relation": "after_meal",
                    "instructions_ar": "قرص بعد الإفطار",
                },
                {
                    "time_of_day": "20:30",
                    "dose_amount": 1.0,
                    "meal_relation": "after_meal",
                    "instructions_ar": "قرص بعد العشاء",
                },
            ],
        },
        headers=headers,
    )
    assert med_res.status_code == 201
    med_data = med_res.json()
    assert len(med_data["schedules"]) == 2
    sched_id = med_data["schedules"][0]["id"]

    # 2. Get today's doses
    today_res = await client.get(f"/api/v1/patients/{patient_id}/today", headers=headers)
    assert today_res.status_code == 200
    today_doses = today_res.json()
    assert len(today_doses) == 2
    assert today_doses[0]["status"] == "pending"

    # 3. Log adherence (Taken) -> should decrement stock from 30 to 29
    now_iso = datetime.now(UTC).isoformat()
    client_uuid = str(uuid.uuid4())
    log_res = await client.post(
        "/api/v1/adherence/log",
        json={
            "client_uuid": client_uuid,
            "schedule_id": sched_id,
            "scheduled_time": now_iso,
            "status": "taken",
        },
        headers=headers,
    )
    assert log_res.status_code == 200
    assert log_res.json()["status"] == "taken"

    # Verify medication stock reduced
    meds_list = await client.get(f"/api/v1/patients/{patient_id}/medications", headers=headers)
    assert meds_list.status_code == 200
    assert meds_list.json()[0]["stock_count"] == 29

    # Idempotent logging test (same client_uuid should return existing log)
    dup_res = await client.post(
        "/api/v1/adherence/log",
        json={
            "client_uuid": client_uuid,
            "schedule_id": sched_id,
            "scheduled_time": now_iso,
            "status": "taken",
        },
        headers=headers,
    )
    assert dup_res.status_code == 200
    # Stock should remain 29, not decremented twice!
    meds_list_again = await client.get(
        f"/api/v1/patients/{patient_id}/medications", headers=headers
    )
    assert meds_list_again.json()[0]["stock_count"] == 29

    # 4. Batch offline sync test
    offline_uuid = str(uuid.uuid4())
    batch_res = await client.post(
        "/api/v1/sync/batch",
        json={
            "items": [
                {
                    "client_uuid": offline_uuid,
                    "entity": "intake_log",
                    "op": "create",
                    "payload": {
                        "schedule_id": sched_id,
                        "scheduled_time": now_iso,
                        "status": "taken",
                    },
                }
            ]
        },
        headers=headers,
    )
    assert batch_res.status_code == 200
    assert batch_res.json()["processed"] == 1
    # Stock should now be 28
    meds_check = await client.get(f"/api/v1/patients/{patient_id}/medications", headers=headers)
    assert meds_check.json()[0]["stock_count"] == 28

    # 5. Verify today's doses reflects the logged intake
    today_after = await client.get(f"/api/v1/patients/{patient_id}/today", headers=headers)
    assert today_after.status_code == 200
    statuses = [d["status"] for d in today_after.json()]
    assert "taken" in statuses

    # 6. Verify low stock alert when stock drops to threshold
    med_id = med_data["id"]
    await client.patch(
        f"/api/v1/medications/{med_id}",
        json={"stock_count": 6},
        headers=headers,
    )
    # Logging 1 dose drops stock to 5 (<= alert_threshold_days of 5)
    log_low = await client.post(
        "/api/v1/adherence/log",
        json={
            "client_uuid": str(uuid.uuid4()),
            "schedule_id": sched_id,
            "scheduled_time": now_iso,
            "status": "taken",
        },
        headers=headers,
    )
    assert log_low.status_code == 200

    alerts_res = await client.get(f"/api/v1/patients/{patient_id}/alerts", headers=headers)
    assert alerts_res.status_code == 200
    low_alert = next((a for a in alerts_res.json() if a["type"] == "low_stock"), None)
    assert low_alert is not None
    assert low_alert["payload"]["name"] == "Glucophage 500mg"
    assert low_alert["payload"]["stock_count"] == 5


@pytest.mark.asyncio
async def test_sync_batch_triggers_alerts_and_preserves_timestamp(
    client: AsyncClient, user_factory
):
    patient = await user_factory(phone="+201044445555", name="مريض مزامنة")
    patient_id = str(patient.id)
    headers = {"Authorization": f"Bearer {patient.id}"}

    # Create medication with stock 2, alert threshold 3
    med_res = await client.post(
        f"/api/v1/patients/{patient_id}/medications",
        json={
            "name": "Concor 5mg",
            "stock_count": 4,
            "alert_threshold_days": 3,
            "schedules": [{"time_of_day": "09:00", "dose_amount": 2.0}],
        },
        headers=headers,
    )
    assert med_res.status_code == 201
    sched_id = med_res.json()["schedules"][0]["id"]

    # Sync offline batch with:
    # 1. Dose taken (stock drops from 4 to 2, which is <= 3 threshold -> low stock alert)
    # 2. Critical glucose vital (350 mg/dL -> critical vital alert)
    intake_uuid = str(uuid.uuid4())
    vital_uuid = str(uuid.uuid4())
    past_recorded_at = "2026-10-23T07:15:00Z"

    batch_res = await client.post(
        "/api/v1/sync/batch",
        json={
            "items": [
                {
                    "client_uuid": intake_uuid,
                    "entity": "intake_log",
                    "op": "create",
                    "payload": {
                        "schedule_id": sched_id,
                        "scheduled_time": "2026-10-23T09:00:00Z",
                        "status": "taken",
                    },
                },
                {
                    "client_uuid": vital_uuid,
                    "entity": "vitals_log",
                    "op": "create",
                    "payload": {
                        "patient_id": patient_id,
                        "type": "glucose",
                        "value_primary": 350.0,
                        "meal_context": "fasting",
                        "recorded_at": past_recorded_at,
                    },
                },
            ]
        },
        headers=headers,
    )
    assert batch_res.status_code == 200
    assert batch_res.json()["processed"] == 2

    # Verify vitals recorded_at was preserved
    vitals_res = await client.get(f"/api/v1/patients/{patient_id}/vitals", headers=headers)
    assert vitals_res.status_code == 200
    vitals = vitals_res.json()
    assert len(vitals) == 1
    assert "2026-10-23T07:15:00" in vitals[0]["recorded_at"]
    assert vitals[0]["band"] == "critical"

    # Verify both low_stock and critical_vital alerts were generated
    alerts_res = await client.get(f"/api/v1/patients/{patient_id}/alerts", headers=headers)
    assert alerts_res.status_code == 200
    alerts = alerts_res.json()
    types = {a["type"] for a in alerts}
    assert "low_stock" in types
    assert "critical_vital" in types
