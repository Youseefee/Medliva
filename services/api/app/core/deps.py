import uuid
from typing import Annotated

import httpx
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.errors import AppError
from app.db.session import get_db
from app.models.user import User, UserRole

security_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    cred: Annotated[HTTPAuthorizationCredentials | None, Depends(security_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    if not cred or not cred.credentials:
        raise AppError(401, "UNAUTHORIZED", "يرجى تسجيل الدخول أولاً")

    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_publishable_key:
        raise AppError(503, "AUTH_NOT_CONFIGURED", "إعدادات المصادقة غير مكتملة")

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(
                f"{settings.supabase_url.rstrip('/')}/auth/v1/user",
                headers={
                    "apikey": settings.supabase_publishable_key,
                    "Authorization": f"Bearer {cred.credentials}",
                },
            )
    except httpx.RequestError as exc:
        raise AppError(503, "AUTH_PROVIDER_UNAVAILABLE", "تعذر الاتصال بخدمة تسجيل الدخول") from exc

    if response.status_code == 401:
        raise AppError(401, "TOKEN_INVALID", "رمز الدخول غير صالح أو منتهي")
    if response.status_code != 200:
        raise AppError(503, "AUTH_PROVIDER_UNAVAILABLE", "تعذر التحقق من تسجيل الدخول")

    try:
        auth_user = response.json()
        if not isinstance(auth_user, dict):
            raise TypeError("Supabase Auth response must be an object")
        user_id = uuid.UUID(auth_user["id"])
    except (KeyError, TypeError, ValueError) as exc:
        raise AppError(401, "TOKEN_INVALID", "بيانات حساب Supabase غير صالحة") from exc

    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        metadata = auth_user.get("user_metadata") or {}
        raw_role = str(metadata.get("role") or "patient").lower()
        selected_role = (
            UserRole.CAREGIVER if raw_role == UserRole.CAREGIVER.value else UserRole.PATIENT
        )
        user = User(
            id=user_id,
            email=auth_user.get("email"),
            phone=auth_user.get("phone") or None,
            name=metadata.get("full_name") or metadata.get("name"),
            role=selected_role,
        )
        db.add(user)
        try:
            await db.commit()
            await db.refresh(user)
        except IntegrityError:
            await db.rollback()
            result = await db.execute(stmt)
            user = result.scalar_one_or_none()
            if not user:
                raise AppError(409, "PROFILE_CONFLICT", "تعذر إنشاء ملف الحساب") from None

    return user


def require_role(*roles: UserRole):
    async def role_checker(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if current_user.role not in roles:
            raise AppError(403, "FORBIDDEN", "ليس لديك الصلاحية للقيام بهذا الإجراء")
        return current_user

    return role_checker


async def check_patient_access(
    patient_id: uuid.UUID,
    current_user: User,
    db: AsyncSession,
) -> bool:
    if current_user.id == patient_id or current_user.role == UserRole.ADMIN:
        return True

    from app.models.caregiver import CaregiverLink, CaregiverLinkStatus

    stmt = select(CaregiverLink).where(
        CaregiverLink.caregiver_id == current_user.id,
        CaregiverLink.patient_id == patient_id,
        CaregiverLink.status == CaregiverLinkStatus.ACTIVE,
    )
    result = await db.execute(stmt)
    link = result.scalar_one_or_none()
    if not link:
        raise AppError(403, "FORBIDDEN", "لا تملك صلاحية الوصول لبيانات هذا المريض")
    return True
