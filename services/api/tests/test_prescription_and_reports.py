import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_prescription_ocr_and_doctor_reports(client: AsyncClient):
    # Register patient
    p_req = await client.post("/api/v1/auth/otp/request", json={"phone": "01077778888"})
    p_code = p_req.json()["dev_code"]
    p_auth = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "01077778888", "code": p_code, "name": "مريض التقارير"},
    )
    p_token = p_auth.json()["access_token"]
    patient_id = p_auth.json()["user"]["id"]
    headers = {"Authorization": f"Bearer {p_token}"}


    # 1. Test Prescription Scan endpoint
    scan_res = await client.post("/api/v1/ai/scan-prescription", headers=headers)
    assert scan_res.status_code == 200
    scan_data = scan_res.json()
    assert len(scan_data["medications"]) >= 1
    assert scan_data["confidence"] >= 0.85
    assert "Glucophage" in scan_data["medications"][0]["drug_trade_name"]

    # 2. Test Report Share & Public Doctor Portal View
    share_res = await client.post(
        f"/api/v1/patients/{patient_id}/reports/share",
        json={"scope": "full", "expires_in_hours": 24},
        headers=headers,
    )
    assert share_res.status_code == 200
    share_data = share_res.json()
    token = share_data["token"]
    assert token is not None

    # Public doctor accesses report via token (NO auth header needed)
    public_res = await client.get(f"/api/v1/public/reports/{token}")
    assert public_res.status_code == 200
    pub_data = public_res.json()
    assert "adherence_rate_pct" in pub_data
    assert pub_data["patient_phone"] == "+201077778888"

    # 3. Test Emergency SOS trigger
    sos_res = await client.post(
        "/api/v1/emergency/sos",
        json={"lat": 30.0444, "lng": 31.2357, "note": "حالة طارئة"},
        headers=headers,
    )
    assert sos_res.status_code == 200
    assert sos_res.json()["status"] == "active"
