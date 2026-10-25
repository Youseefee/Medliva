import pytest
from httpx import AsyncClient


async def _login_user(user_factory, phone: str, name: str) -> tuple[str, dict[str, str]]:
    user = await user_factory(phone=phone, name=name)
    return str(user.id), {"Authorization": f"Bearer {user.id}"}


@pytest.mark.asyncio
async def test_all_patient_routes_reject_unrelated_user_with_403(client: AsyncClient, user_factory):
    owner_id, owner_headers = await _login_user(user_factory, "+201011112222", "المريض الأصلي")
    _, stranger_headers = await _login_user(user_factory, "+201033334444", "مستخدم آخر")

    # Owner creates a medication with a schedule so we can also test medication_id routes
    med_res = await client.post(
        f"/api/v1/patients/{owner_id}/medications",
        headers=owner_headers,
        json={
            "name": "Panadol",
            "stock_count": 20,
            "schedules": [{"time_of_day": "09:00", "dose_amount": 1.0}],
        },
    )
    assert med_res.status_code == 201
    med_id = med_res.json()["id"]
    sched_id = med_res.json()["schedules"][0]["id"]

    # 1. GET /patients/{patient_id}/medications
    r = await client.get(f"/api/v1/patients/{owner_id}/medications", headers=stranger_headers)
    assert r.status_code == 403

    # 2. POST /patients/{patient_id}/medications
    r = await client.post(
        f"/api/v1/patients/{owner_id}/medications",
        headers=stranger_headers,
        json={"name": "Unauthorized Med"},
    )
    assert r.status_code == 403

    # 3. PATCH /medications/{medication_id}
    r = await client.patch(
        f"/api/v1/medications/{med_id}",
        headers=stranger_headers,
        json={"name": "Hacked"},
    )
    assert r.status_code == 403

    # 4. DELETE /medications/{medication_id}
    r = await client.delete(f"/api/v1/medications/{med_id}", headers=stranger_headers)
    assert r.status_code == 403

    # 5. GET /medications/{medication_id}/schedules
    r = await client.get(f"/api/v1/medications/{med_id}/schedules", headers=stranger_headers)
    assert r.status_code == 403

    # 6. POST /medications/{medication_id}/schedules
    r = await client.post(
        f"/api/v1/medications/{med_id}/schedules",
        headers=stranger_headers,
        json={"time_of_day": "21:00", "dose_amount": 1.0},
    )
    assert r.status_code == 403

    # 7. GET /patients/{patient_id}/today
    r = await client.get(f"/api/v1/patients/{owner_id}/today", headers=stranger_headers)
    assert r.status_code == 403

    # 8. POST /adherence/log (for owner's schedule)
    r = await client.post(
        "/api/v1/adherence/log",
        headers=stranger_headers,
        json={
            "client_uuid": "stranger-log-1",
            "schedule_id": sched_id,
            "scheduled_time": "2026-10-23T09:00:00Z",
            "status": "taken",
        },
    )
    assert r.status_code == 403

    # 9. POST /sync/batch (intake_log for owner's schedule)
    r = await client.post(
        "/api/v1/sync/batch",
        headers=stranger_headers,
        json={
            "items": [
                {
                    "entity": "intake_log",
                    "op": "create",
                    "client_uuid": "stranger-sync-1",
                    "payload": {
                        "schedule_id": sched_id,
                        "scheduled_time": "2026-10-23T09:00:00Z",
                        "status": "taken",
                    },
                }
            ]
        },
    )
    assert r.status_code == 403

    # 10. POST /sync/batch (vitals_log for owner's patient_id)
    r = await client.post(
        "/api/v1/sync/batch",
        headers=stranger_headers,
        json={
            "items": [
                {
                    "entity": "vitals_log",
                    "op": "create",
                    "client_uuid": "stranger-sync-vital-1",
                    "payload": {
                        "patient_id": owner_id,
                        "type": "bp",
                        "value_primary": 120.0,
                        "value_secondary": 80.0,
                    },
                }
            ]
        },
    )
    assert r.status_code == 403

    # 11. GET /patients/{patient_id}/vitals
    r = await client.get(f"/api/v1/patients/{owner_id}/vitals", headers=stranger_headers)
    assert r.status_code == 403

    # 12. POST /patients/{patient_id}/vitals
    r = await client.post(
        f"/api/v1/patients/{owner_id}/vitals",
        headers=stranger_headers,
        json={
            "client_uuid": "stranger-vital-1",
            "type": "glucose",
            "value_primary": 110.0,
        },
    )
    assert r.status_code == 403

    # 13. GET /patients/{patient_id}/inventory/forecast
    r = await client.get(
        f"/api/v1/patients/{owner_id}/inventory/forecast",
        headers=stranger_headers,
    )
    assert r.status_code == 403

    # 14. POST /patients/{patient_id}/inventory/refill-order
    r = await client.post(
        f"/api/v1/patients/{owner_id}/inventory/refill-order",
        headers=stranger_headers,
        json={
            "pharmacy_phone": "01000000000",
            "items": [{"name": "Panadol", "quantity": 1}],
        },
    )
    assert r.status_code == 403

    # 15. GET /patients/{patient_id}/contacts
    r = await client.get(f"/api/v1/patients/{owner_id}/contacts", headers=stranger_headers)
    assert r.status_code == 403

    # 16. POST /patients/{patient_id}/contacts
    r = await client.post(
        f"/api/v1/patients/{owner_id}/contacts",
        headers=stranger_headers,
        json={"name": "Fake Contact", "phone": "01099998888", "relationship": "ابن"},
    )
    assert r.status_code == 403

    # 17. POST /patients/{patient_id}/reports/share
    r = await client.post(
        f"/api/v1/patients/{owner_id}/reports/share",
        headers=stranger_headers,
        json={"expires_in_hours": 24},
    )
    assert r.status_code == 403

    # 18. GET /patients/{patient_id}/reports/summary
    r = await client.get(
        f"/api/v1/patients/{owner_id}/reports/summary",
        headers=stranger_headers,
    )
    assert r.status_code == 403

    # 19. GET /patients/{patient_id}/alerts
    r = await client.get(
        f"/api/v1/patients/{owner_id}/alerts",
        headers=stranger_headers,
    )
    assert r.status_code == 403

    # 20. GET /patients/{patient_id}/caregivers
    r = await client.get(
        f"/api/v1/patients/{owner_id}/caregivers",
        headers=stranger_headers,
    )
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_invalid_supabase_identity_is_rejected(client: AsyncClient):
    res = await client.get(
        "/api/v1/me",
        headers={"Authorization": "Bearer invalid-user-id"},
    )
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "TOKEN_INVALID"
