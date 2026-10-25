import uuid
from collections.abc import AsyncIterator
from typing import Annotated

import pytest
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.deps import get_current_user, security_scheme
from app.core.errors import AppError
from app.db.base import Base
from app.db.session import get_db
from app.main import create_app
from app.models.user import User, UserRole

# Test DB: in-memory sqlite
TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestSessionLocal = async_sessionmaker(test_engine, expire_on_commit=False)


@pytest.fixture
async def db_session() -> AsyncIterator[AsyncSession]:
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with TestSessionLocal() as session:
        yield session

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def client(db_session: AsyncSession) -> AsyncIterator[AsyncClient]:
    app = create_app()

    async def _get_test_db() -> AsyncIterator[AsyncSession]:
        yield db_session

    async def _get_test_user(
        cred: Annotated[HTTPAuthorizationCredentials | None, Depends(security_scheme)],
        db: Annotated[AsyncSession, Depends(get_db)],
    ) -> User:
        if not cred or not cred.credentials:
            raise AppError(401, "UNAUTHORIZED", "يرجى تسجيل الدخول أولاً")
        try:
            user_id = uuid.UUID(cred.credentials)
        except ValueError as exc:
            raise AppError(401, "TOKEN_INVALID", "رمز الدخول غير صالح") from exc
        user = await db.get(User, user_id)
        if user is None:
            raise AppError(401, "TOKEN_INVALID", "رمز الدخول غير صالح")
        return user

    app.dependency_overrides[get_db] = _get_test_db
    app.dependency_overrides[get_current_user] = _get_test_user

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
    ) as ac:
        yield ac


@pytest.fixture
def user_factory(db_session: AsyncSession):
    async def create_user(
        *,
        phone: str | None = None,
        email: str | None = None,
        name: str | None = None,
        role: UserRole = UserRole.PATIENT,
    ) -> User:
        user = User(
            id=uuid.uuid4(),
            phone=phone,
            email=email,
            name=name,
            role=role,
        )
        db_session.add(user)
        await db_session.commit()
        return user

    return create_user
