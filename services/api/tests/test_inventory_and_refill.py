import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_inventory_forecast_and_refill(client: AsyncClient):
    # Register patient
    p_req = await client.post("/api/v1/auth/otp/request", json={"phone": "01055556666"})
    p_code = p_req.json()["dev_code"]
    p_auth = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "01055556666", "code": p_code, "name": "مريض القلب"},
    )
    p_token = p_auth.json()["access_token"]
    patient_id = p_auth.json()["user"]["id"]
    headers = {"Authorization": f"Bearer {p_token}"}


    # Add medication with stock 4 and daily dose 2
    # (2 doses per day -> 2 days remaining <= threshold 5)
    await client.post(
        f"/api/v1/patients/{patient_id}/medications",
        json={
            "name": "Concor 5mg",
            "stock_count": 4,
            "alert_threshold_days": 5,
            "schedules": [
                {"time_of_day": "08:00", "dose_amount": 1.0},
                {"time_of_day": "20:00", "dose_amount": 1.0},
            ],
        },
        headers=headers,
    )

    # Check forecast
    fc_res = await client.get(f"/api/v1/patients/{patient_id}/inventory/forecast", headers=headers)
    assert fc_res.status_code == 200
    fc = fc_res.json()
    assert fc["low_stock_count"] == 1
    assert fc["medications"][0]["days_remaining"] == 2
    assert fc["medications"][0]["is_low_stock"] is True

    # Generate WhatsApp refill order
    refill_res = await client.post(
        f"/api/v1/patients/{patient_id}/inventory/refill-order",
        json={
            "pharmacy_phone": "01012345678",
            "items": [{"name": "Concor 5mg", "quantity": 2}],
            "note": "توصيل عاجل من فضلك",
        },
        headers=headers,
    )
    assert refill_res.status_code == 200
    refill_data = refill_res.json()
    assert "https://wa.me/201012345678" in refill_data["whatsapp_url"]
    assert "Concor 5mg: 2 عبوة" in refill_data["message_text"]
