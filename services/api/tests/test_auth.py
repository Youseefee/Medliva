from httpx import AsyncClient


async def test_health_check(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["app"] == "CareElder API"


async def test_otp_flow_and_me_endpoints(client: AsyncClient):
    # 1. Request OTP
    req_resp = await client.post(
        "/api/v1/auth/otp/request",
        json={"phone": "01098765432"},
    )
    assert req_resp.status_code == 200
    req_data = req_resp.json()
    assert req_data["phone"] == "+201098765432"
    dev_code = req_data.get("dev_code")
    assert dev_code is not None

    # 2. Verify with invalid OTP -> should fail
    bad_resp = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "01098765432", "code": "000000"},
    )
    assert bad_resp.status_code == 400
    assert bad_resp.json()["error"]["code"] == "OTP_INVALID"

    # 3. Verify with valid OTP -> should succeed and create user
    verify_resp = await client.post(
        "/api/v1/auth/otp/verify",
        json={
            "phone": "01098765432",
            "code": dev_code,
            "role": "patient",
            "name": "عم أحمد",
        },
    )
    assert verify_resp.status_code == 200
    auth_data = verify_resp.json()
    assert auth_data["is_new_user"] is True
    access_token = auth_data["access_token"]
    refresh_token = auth_data["refresh_token"]
    assert auth_data["user"]["name"] == "عم أحمد"
    assert auth_data["user"]["role"] == "patient"
    assert auth_data["user"]["phone"] == "+201098765432"

    # 4. Access /me with access token
    headers = {"Authorization": f"Bearer {access_token}"}
    me_resp = await client.get("/api/v1/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["name"] == "عم أحمد"

    # 5. Update /me (PATCH)
    patch_resp = await client.patch(
        "/api/v1/me",
        headers=headers,
        json={"name": "الحاج أحمد الشريف", "timezone": "Africa/Cairo"},
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["name"] == "الحاج أحمد الشريف"

    # 6. Refresh token
    refresh_resp = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 200
    new_tokens = refresh_resp.json()
    assert "access_token" in new_tokens
    assert "refresh_token" in new_tokens


async def test_unauthorized_me(client: AsyncClient):
    resp = await client.get("/api/v1/me")
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "UNAUTHORIZED"
