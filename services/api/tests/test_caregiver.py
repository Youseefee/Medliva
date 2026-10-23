import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_caregiver_pairing_flow(client: AsyncClient):
    # 1. Patient requests OTP & verifies
    p_req = await client.post("/api/v1/auth/otp/request", json={"phone": "01099991111"})
    p_code = p_req.json()["dev_code"]
    p_auth = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "01099991111", "code": p_code, "name": "المريض أحمد"},
    )
    p_token = p_auth.json()["access_token"]
    p_headers = {"Authorization": f"Bearer {p_token}"}

    # Patient generates pairing code
    code_res = await client.post("/api/v1/caregiver/pairing-code", headers=p_headers)
    assert code_res.status_code == 200
    pairing_code = code_res.json()["code"]
    assert len(pairing_code) == 6

    # 2. Caregiver requests OTP & verifies
    c_req = await client.post("/api/v1/auth/otp/request", json={"phone": "01088882222"})
    c_code = c_req.json()["dev_code"]
    c_auth = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "01088882222", "code": c_code, "name": "المرافق سارة"},
    )
    c_token = c_auth.json()["access_token"]
    c_headers = {"Authorization": f"Bearer {c_token}"}
    await client.patch("/api/v1/me", json={"role": "caregiver"}, headers=c_headers)


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
