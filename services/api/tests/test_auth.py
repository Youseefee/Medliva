from httpx import AsyncClient

from app.models.user import UserRole


async def test_health_check(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["app"] == "Medliva API"


async def test_me_profile_and_role_protection(client: AsyncClient, user_factory):
    user = await user_factory(
        email="ahmed@example.com",
        phone="+201098765432",
        name="عم أحمد",
        role=UserRole.PATIENT,
    )
    headers = {"Authorization": f"Bearer {user.id}"}

    me_response = await client.get("/api/v1/me", headers=headers)
    assert me_response.status_code == 200
    assert me_response.json()["id"] == str(user.id)
    assert me_response.json()["email"] == "ahmed@example.com"
    assert me_response.json()["name"] == "عم أحمد"
    assert me_response.json()["role"] == "patient"

    update_response = await client.patch(
        "/api/v1/me",
        headers=headers,
        json={"name": "الحاج أحمد الشريف", "timezone": "Africa/Cairo"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["name"] == "الحاج أحمد الشريف"

    role_response = await client.patch(
        "/api/v1/me",
        headers=headers,
        json={"role": "admin"},
    )
    assert role_response.status_code == 422


async def test_unauthorized_me(client: AsyncClient):
    response = await client.get("/api/v1/me")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "UNAUTHORIZED"
