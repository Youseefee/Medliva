import json
from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.emergency import Alert, AlertType
from app.models.user import UserRole


@pytest.mark.asyncio
async def test_caregiver_pairing_flow(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201099991111", name="المريض أحمد")
    p_headers = {"Authorization": f"Bearer {patient.id}"}

    # Patient generates pairing code
    code_res = await client.post("/api/v1/caregiver/pairing-code", headers=p_headers)
    assert code_res.status_code == 200
    pairing_code = code_res.json()["code"]
    assert len(pairing_code) == 6

    caregiver = await user_factory(
        phone="+201088882222", name="المرافق سارة", role=UserRole.CAREGIVER
    )
    c_headers = {"Authorization": f"Bearer {caregiver.id}"}

    # Caregiver pairs with code
    pair_res = await client.post(
        "/api/v1/caregiver/pair",
        json={"code": pairing_code},
        headers=c_headers,
    )
    assert pair_res.status_code == 200
    assert pair_res.json()["status"] == "active"

    # Caregiver lists patients
    list_res = await client.get("/api/v1/caregiver/patients", headers=c_headers)
    assert list_res.status_code == 200
    patients = list_res.json()
    assert len(patients) == 1
    assert patients[0]["phone"] == "+201099991111"


@pytest.mark.asyncio
async def test_patient_sees_their_linked_caregivers(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201077773333", name="المريض عمرو")
    patient_id = str(patient.id)
    p_headers = {"Authorization": f"Bearer {patient.id}"}

    code_res = await client.post("/api/v1/caregiver/pairing-code", headers=p_headers)
    pairing_code = code_res.json()["code"]

    caregiver = await user_factory(
        phone="+201066664444", name="المرافق هالة", role=UserRole.CAREGIVER
    )
    c_headers = {"Authorization": f"Bearer {caregiver.id}"}
    pair_res = await client.post(
        "/api/v1/caregiver/pair", json={"code": pairing_code}, headers=c_headers
    )
    assert pair_res.status_code == 200

    # The patient sees who monitors them.
    res = await client.get(f"/api/v1/patients/{patient_id}/caregivers", headers=p_headers)
    assert res.status_code == 200
    caregivers = res.json()
    assert len(caregivers) == 1
    assert caregivers[0]["name"] == "المرافق هالة"
    assert caregivers[0]["caregiver_id"] == str(caregiver.id)
    assert caregivers[0]["status"] == "active"

    # An unrelated user does not.
    stranger = await user_factory(phone="+201055557777", name="مستخدم غريب")
    stranger_res = await client.get(
        f"/api/v1/patients/{patient_id}/caregivers",
        headers={"Authorization": f"Bearer {stranger.id}"},
    )
    assert stranger_res.status_code == 403


@pytest.mark.asyncio
async def test_caregiver_missed_dose_15min_escalation(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201077771111", name="عم حسن")
    patient_id = str(patient.id)
    p_headers = {"Authorization": f"Bearer {patient.id}"}

    # 2. Caregiver setup & pair
    code_res = await client.post("/api/v1/caregiver/pairing-code", headers=p_headers)
    pairing_code = code_res.json()["code"]

    caregiver = await user_factory(phone="+201066662222", name="مريم", role=UserRole.CAREGIVER)
    c_headers = {"Authorization": f"Bearer {caregiver.id}"}
    await client.post("/api/v1/caregiver/pair", json={"code": pairing_code}, headers=c_headers)

    # 3. Create medication scheduled at 08:00
    med_res = await client.post(
        f"/api/v1/patients/{patient_id}/medications",
        headers=p_headers,
        json={
            "name": "Concor 5mg",
            "stock_count": 30,
            "schedules": [{"time_of_day": "08:00", "dose_amount": 1.0}],
        },
    )
    assert med_res.status_code == 201
    schedule_id = med_res.json()["schedules"][0]["id"]

    # Case A: On-time window (08:10, < 15 min after 08:00) -> not missed
    res_before_15m = await client.get(
        "/api/v1/caregiver/patients",
        params={"now": "2026-10-23T08:10:00Z"},
        headers=c_headers,
    )
    assert res_before_15m.status_code == 200
    p_data = res_before_15m.json()[0]
    assert p_data["today_taken_count"] == 0
    assert p_data["today_missed_count"] == 0
    assert p_data["active_alerts_count"] == 0

    # Case B: Missed (08:16, >= 15 min after 08:00 with no log) -> missed alert exposed
    res_after_15m = await client.get(
        "/api/v1/caregiver/patients",
        params={"now": "2026-10-23T08:16:00Z"},
        headers=c_headers,
    )
    assert res_after_15m.status_code == 200
    p_missed = res_after_15m.json()[0]
    assert p_missed["today_taken_count"] == 0
    assert p_missed["today_missed_count"] == 1
    assert p_missed["active_alerts_count"] == 1
    assert len(p_missed["missed_doses"]) == 1

    alerts_res = await client.get(
        "/api/v1/caregiver/alerts",
        params={"now": "2026-10-23T08:16:00Z"},
        headers=c_headers,
    )
    assert alerts_res.status_code == 200
    assert len(alerts_res.json()) == 1

    # Case C: Logged late (patient logs taken at 08:25) -> alert cleared, counted as taken
    log_res = await client.post(
        "/api/v1/adherence/log",
        headers=p_headers,
        json={
            "client_uuid": "late-log-uuid-1",
            "schedule_id": schedule_id,
            "scheduled_time": "2026-10-23T08:00:00Z",
            "actual_time": "2026-10-23T08:25:00Z",
            "status": "taken",
        },
    )
    assert log_res.status_code == 200

    res_logged_late = await client.get(
        "/api/v1/caregiver/patients",
        params={"now": "2026-10-23T08:30:00Z"},
        headers=c_headers,
    )
    assert res_logged_late.status_code == 200
    p_late = res_logged_late.json()[0]
    assert p_late["today_taken_count"] == 1
    assert p_late["today_missed_count"] == 0
    assert p_late["active_alerts_count"] == 0


@pytest.mark.asyncio
async def test_patient_alerts_are_visible_to_the_caregiver_only(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201055551111", name="المريض نادية")
    patient_id = str(patient.id)
    p_headers = {"Authorization": f"Bearer {patient.id}"}

    # The patient triggers an SOS -> an alert row is stored.
    sos_res = await client.post(
        "/api/v1/emergency/sos",
        headers=p_headers,
        json={"lat": 30.0444, "lng": 31.2357, "note": "دوران مفاجئ"},
    )
    assert sos_res.status_code == 200
    alert_id = sos_res.json()["alert_id"]

    # The patient reads their own alerts.
    own_res = await client.get(
        f"/api/v1/patients/{patient_id}/alerts",
        headers=p_headers,
    )
    assert own_res.status_code == 200
    own_alerts = own_res.json()
    assert len(own_alerts) == 1
    assert own_alerts[0]["id"] == alert_id
    assert own_alerts[0]["type"] == "sos"
    assert own_alerts[0]["tier"] == 3
    assert own_alerts[0]["payload"]["note"] == "دوران مفاجئ"

    # A paired caregiver reads the same alerts.
    code_res = await client.post("/api/v1/caregiver/pairing-code", headers=p_headers)
    pairing_code = code_res.json()["code"]

    caregiver = await user_factory(
        phone="+201044441111", name="المرافق هدى", role=UserRole.CAREGIVER
    )
    c_headers = {"Authorization": f"Bearer {caregiver.id}"}
    pair_res = await client.post(
        "/api/v1/caregiver/pair", json={"code": pairing_code}, headers=c_headers
    )
    assert pair_res.status_code == 200

    caregiver_res = await client.get(
        f"/api/v1/patients/{patient_id}/alerts",
        headers=c_headers,
    )
    assert caregiver_res.status_code == 200
    caregiver_alerts = caregiver_res.json()
    assert len(caregiver_alerts) == 1
    assert caregiver_alerts[0]["id"] == alert_id
    assert caregiver_alerts[0]["type"] == "sos"

    # An unrelated user gets nothing.
    stranger = await user_factory(phone="+201033331111", name="مستخدم غريب")
    stranger_res = await client.get(
        f"/api/v1/patients/{patient_id}/alerts",
        headers={"Authorization": f"Bearer {stranger.id}"},
    )
    assert stranger_res.status_code == 403


@pytest.mark.asyncio
async def test_patient_alerts_are_ordered_newest_first(
    client: AsyncClient, user_factory, db_session: AsyncSession
):
    patient = await user_factory(phone="+201022221111", name="المريض عصام")
    patient_id = str(patient.id)
    p_headers = {"Authorization": f"Bearer {patient.id}"}

    now = datetime.now(UTC)
    older = Alert(
        patient_id=patient.id,
        type=AlertType.LOW_STOCK,
        tier=1,
        payload_json=json.dumps({"drug": "Concor"}),
        sent_at=now - timedelta(minutes=5),
        created_at=now - timedelta(minutes=5),
    )
    newer = Alert(
        patient_id=patient.id,
        type=AlertType.CRITICAL_VITAL,
        tier=3,
        payload_json=json.dumps({"type": "bp"}),
        sent_at=now,
        created_at=now,
    )
    db_session.add_all([older, newer])
    await db_session.commit()

    res = await client.get(f"/api/v1/patients/{patient_id}/alerts", headers=p_headers)
    assert res.status_code == 200
    alerts = res.json()
    assert len(alerts) == 2
    assert alerts[0]["id"] == str(newer.id)
    assert alerts[0]["type"] == "critical_vital"
    assert alerts[0]["payload"] == {"type": "bp"}
    assert alerts[1]["id"] == str(older.id)
    assert alerts[1]["type"] == "low_stock"


@pytest.mark.asyncio
async def test_missed_dose_is_exposed_as_an_alert(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201011114444", name="المريض سمير")
    patient_id = str(patient.id)
    p_headers = {"Authorization": f"Bearer {patient.id}"}

    med_res = await client.post(
        f"/api/v1/patients/{patient_id}/medications",
        headers=p_headers,
        json={
            "name": "Concor 5mg",
            "stock_count": 30,
            "schedules": [{"time_of_day": "08:00", "dose_amount": 1.0}],
        },
    )
    assert med_res.status_code == 201

    # Before the 15 minute grace period the dose is not missed yet.
    early = await client.get(
        f"/api/v1/patients/{patient_id}/alerts",
        params={"now": "2026-10-23T08:10:00Z"},
        headers=p_headers,
    )
    assert early.status_code == 200
    assert [a for a in early.json() if a["type"] == "missed_dose"] == []

    # After the grace period it shows up as a missed dose alert.
    late = await client.get(
        f"/api/v1/patients/{patient_id}/alerts",
        params={"now": "2026-10-23T08:16:00Z"},
        headers=p_headers,
    )
    assert late.status_code == 200
    missed = [a for a in late.json() if a["type"] == "missed_dose"]
    assert len(missed) == 1
    assert missed[0]["payload"]["medication_name"] == "Concor 5mg"
    assert missed[0]["payload"]["time_of_day"] == "08:00"

    # Taking the dose clears the missed dose alert.
    log_res = await client.post(
        "/api/v1/adherence/log",
        headers=p_headers,
        json={
            "client_uuid": "late-log-uuid-2",
            "schedule_id": med_res.json()["schedules"][0]["id"],
            "scheduled_time": "2026-10-23T08:00:00Z",
            "actual_time": "2026-10-23T08:20:00Z",
            "status": "taken",
        },
    )
    assert log_res.status_code == 200

    after = await client.get(
        f"/api/v1/patients/{patient_id}/alerts",
        params={"now": "2026-10-23T08:25:00Z"},
        headers=p_headers,
    )
    assert after.status_code == 200
    assert [a for a in after.json() if a["type"] == "missed_dose"] == []
