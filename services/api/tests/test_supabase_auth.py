import json
import uuid
from unittest.mock import patch

import httpx
import pytest
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.deps import get_current_user
from app.core.errors import AppError
from app.models.user import User, UserRole


@pytest.fixture
def fake_settings():
    return Settings(
        supabase_url="https://test.supabase.co",
        supabase_publishable_key="sb_publishable_testkey",
    )


def _mock_response(
    status_code: int,
    json_data: dict | list | None = None,
    text: str = "",
) -> httpx.Response:
    request = httpx.Request("GET", "https://test.supabase.co/auth/v1/user")
    if json_data is not None:
        content = json.dumps(json_data).encode("utf-8")
        headers = {"content-type": "application/json"}
    else:
        content = text.encode("utf-8")
        headers = {"content-type": "text/plain"}
    return httpx.Response(
        status_code=status_code,
        content=content,
        headers=headers,
        request=request,
    )


@pytest.mark.asyncio
async def test_get_current_user_no_credentials(db_session: AsyncSession):
    with pytest.raises(AppError) as exc_info:
        await get_current_user(cred=None, db=db_session)
    assert exc_info.value.status_code == 401
    assert exc_info.value.code == "UNAUTHORIZED"


@pytest.mark.asyncio
async def test_get_current_user_unconfigured_auth(db_session: AsyncSession):
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="dummy-token")
    empty_settings = Settings(supabase_url="", supabase_publishable_key="")
    with patch("app.core.deps.get_settings", return_value=empty_settings):
        with pytest.raises(AppError) as exc_info:
            await get_current_user(cred=cred, db=db_session)
        assert exc_info.value.status_code == 503
        assert exc_info.value.code == "AUTH_NOT_CONFIGURED"


@pytest.mark.asyncio
async def test_get_current_user_network_error(db_session: AsyncSession, fake_settings):
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="dummy-token")
    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", side_effect=httpx.ConnectError("Connection refused")),
        pytest.raises(AppError) as exc_info,
    ):
        await get_current_user(cred=cred, db=db_session)
    assert exc_info.value.status_code == 503
    assert exc_info.value.code == "AUTH_PROVIDER_UNAVAILABLE"


@pytest.mark.asyncio
async def test_get_current_user_invalid_api_key(db_session: AsyncSession, fake_settings):
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="dummy-token")
    mock_resp = _mock_response(401, json_data={"message": "Invalid API key"})
    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", return_value=mock_resp),
        pytest.raises(AppError) as exc_info,
    ):
        await get_current_user(cred=cred, db=db_session)
    assert exc_info.value.status_code == 503
    assert exc_info.value.code == "AUTH_NOT_CONFIGURED"


@pytest.mark.asyncio
async def test_get_current_user_bad_jwt_403(db_session: AsyncSession, fake_settings):
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="malformed-jwt")
    mock_resp = _mock_response(
        403,
        json_data={"code": 403, "error_code": "bad_jwt", "msg": "invalid JWT"},
    )
    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", return_value=mock_resp),
        pytest.raises(AppError) as exc_info,
    ):
        await get_current_user(cred=cred, db=db_session)
    assert exc_info.value.status_code == 401
    assert exc_info.value.code == "TOKEN_INVALID"


@pytest.mark.asyncio
async def test_get_current_user_expired_jwt_401(db_session: AsyncSession, fake_settings):
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="expired-token")
    mock_resp = _mock_response(401, json_data={"code": 401, "msg": "Token expired"})
    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", return_value=mock_resp),
        pytest.raises(AppError) as exc_info,
    ):
        await get_current_user(cred=cred, db=db_session)
    assert exc_info.value.status_code == 401
    assert exc_info.value.code == "TOKEN_INVALID"


@pytest.mark.asyncio
async def test_get_current_user_upstream_500(db_session: AsyncSession, fake_settings):
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="any-token")
    mock_resp = _mock_response(500, json_data={"message": "Internal error"})
    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", return_value=mock_resp),
        pytest.raises(AppError) as exc_info,
    ):
        await get_current_user(cred=cred, db=db_session)
    assert exc_info.value.status_code == 503
    assert exc_info.value.code == "AUTH_PROVIDER_UNAVAILABLE"


@pytest.mark.asyncio
async def test_get_current_user_creates_patient(db_session: AsyncSession, fake_settings):
    uid = uuid.uuid4()
    auth_data = {
        "id": str(uid),
        "email": "newpatient@example.com",
        "phone": "+201011112222",
        "user_metadata": {"full_name": "مريض جديد", "role": "patient"},
    }
    mock_resp = _mock_response(200, json_data=auth_data)
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="valid-token")

    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", return_value=mock_resp),
    ):
        user = await get_current_user(cred=cred, db=db_session)

    assert user.id == uid
    assert user.email == "newpatient@example.com"
    assert user.phone == "+201011112222"
    assert user.name == "مريض جديد"
    assert user.role == UserRole.PATIENT


@pytest.mark.asyncio
async def test_get_current_user_creates_caregiver(db_session: AsyncSession, fake_settings):
    uid = uuid.uuid4()
    auth_data = {
        "id": str(uid),
        "email": "caregiver@example.com",
        "user_metadata": {"full_name": "مرافق معتمد", "role": "caregiver"},
    }
    mock_resp = _mock_response(200, json_data=auth_data)
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="valid-caregiver-token")

    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", return_value=mock_resp),
    ):
        user = await get_current_user(cred=cred, db=db_session)

    assert user.id == uid
    assert user.role == UserRole.CAREGIVER


@pytest.mark.asyncio
async def test_get_current_user_syncs_updated_profile(db_session: AsyncSession, fake_settings):
    uid = uuid.uuid4()
    user = User(
        id=uid,
        email="old@example.com",
        phone="+201000000000",
        name="مستخدم تجريبي",
        role=UserRole.PATIENT,
    )
    db_session.add(user)
    await db_session.commit()

    auth_data = {
        "id": str(uid),
        "email": "new@example.com",
        "phone": "+201099999999",
        "user_metadata": {"full_name": "مستخدم تجريبي"},
    }
    mock_resp = _mock_response(200, json_data=auth_data)
    cred = HTTPAuthorizationCredentials(scheme="Bearer", credentials="token")

    with (
        patch("app.core.deps.get_settings", return_value=fake_settings),
        patch("httpx.AsyncClient.get", return_value=mock_resp),
    ):
        synced_user = await get_current_user(cred=cred, db=db_session)

    assert synced_user.email == "new@example.com"
    assert synced_user.phone == "+201099999999"
