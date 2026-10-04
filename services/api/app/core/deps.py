import uuid
from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AppError
from app.core.security import decode_token
from app.db.session import get_db
from app.models.user import User, UserRole

security_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    cred: Annotated[HTTPAuthorizationCredentials | None, Depends(security_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    if not cred or not cred.credentials:
        raise AppError(401, "UNAUTHORIZED", "يرجى تسجيل الدخول أولاً")

    payload = decode_token(cred.credentials, expected_type="access")
    user_id_raw = payload.get("sub")
    if not user_id_raw:
        raise AppError(401, "TOKEN_INVALID", "رمز الدخول غير صالح")

    try:
        user_id = uuid.UUID(user_id_raw)
    except ValueError as e:
        raise AppError(401, "TOKEN_INVALID", "معرف المستخدم في الرمز غير صالح") from e

    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise AppError(404, "USER_NOT_FOUND", "المستخدم غير موجود")

    return user


def require_role(*roles: UserRole):
    async def role_checker(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if current_user.role not in roles:
            raise AppError(403, "FORBIDDEN", "ليس لديك الصلاحية للقيام بهذا الإجراء")
        return current_user

    return role_checker
