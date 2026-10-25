import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_prescription_ocr_and_doctor_reports(client: AsyncClient, user_factory):
    patient = await user_factory(phone="+201077778888", name="مريض التقارير")
    patient_id = str(patient.id)
    headers = {"Authorization": f"Bearer {patient.id}"}

    # 1. Test Prescription Scan endpoint: without a prescription the service
    # never invents a medication.
    scan_res = await client.post("/api/v1/ai/scan-prescription", headers=headers)
    assert scan_res.status_code == 200
    scan_data = scan_res.json()
    assert scan_data["medications"] == []
    assert scan_data["confidence"] == 0.0
    assert scan_data["source"] == "text"

    # With a real prescription text the drugs are extracted.
    files = {"file": ("rx.txt", b"Glucophage 500mg", "text/plain")}
    scan_res = await client.post("/api/v1/ai/scan-prescription", headers=headers, files=files)
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

    # 4. Test authenticated report summary + access control (other users get 403)
    summary_res = await client.get(
        f"/api/v1/patients/{patient_id}/reports/summary",
        headers=headers,
    )
    assert summary_res.status_code == 200
    summary_data = summary_res.json()
    assert summary_data["patient_id"] == patient_id
    assert "adherence_rate_pct" in summary_data
    assert "active_medications" in summary_data
    assert "adherence_history" in summary_data
    assert "vitals_history" in summary_data

    # An unrelated account must be denied.
    unrelated_user = await user_factory(phone="+201055554444", name="مستخدم آخر")
    u2_headers = {"Authorization": f"Bearer {unrelated_user.id}"}

    forbidden_res = await client.get(
        f"/api/v1/patients/{patient_id}/reports/summary",
        headers=u2_headers,
    )
    assert forbidden_res.status_code == 403
