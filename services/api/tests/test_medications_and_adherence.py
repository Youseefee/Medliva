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
