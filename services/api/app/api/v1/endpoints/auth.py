import uuid
from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.errors import AppError
from app.core.phone import normalize_eg_phone
from app.core.security import (
    as_utc,
    create_token,
    decode_token,
    generate_otp,
    hash_otp,
    utcnow,
    verify_otp_hash,
)
from app.db.session import get_db
from app.models.user import OtpChallenge, User
from app.schemas.auth import (
    AuthTokensOut,
    OtpRequestIn,
    OtpRequestOut,
    OtpVerifyIn,
    TokenRefreshIn,
    TokenRefreshOut,
)
from app.schemas.user import UserOut

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()


@router.post("/otp/request", response_model=OtpRequestOut)
async def request_otp(
    body: OtpRequestIn,
    db: AsyncSession = Depends(get_db),
) -> OtpRequestOut:
    phone = normalize_eg_phone(body.phone)
    now = utcnow()

    # Check cooldown on latest challenge
    stmt = (
        select(OtpChallenge)
        .where(OtpChallenge.phone == phone)
        .order_by(desc(OtpChallenge.created_at))
        .limit(1)
    )
    result = await db.execute(stmt)
    latest = result.scalar_one_or_none()

    if latest:
        created_at_utc = as_utc(latest.created_at)
        seconds_passed = (now - created_at_utc).total_seconds()
        if seconds_passed < settings.otp_resend_cooldown_seconds:
            remaining = int(settings.otp_resend_cooldown_seconds - seconds_passed)
            raise AppError(
                429,
                "COOLDOWN_ACTIVE",
                f"يرجى الانتظار {remaining} ثانية قبل إعادة إرسال الرمز",
            )

    code = generate_otp(settings.otp_length)
    code_hash = hash_otp(phone, code)
    expires_at = now + timedelta(seconds=settings.otp_ttl_seconds)

    challenge = OtpChallenge(
        phone=phone,
        code_hash=code_hash,
        expires_at=expires_at,
        attempts=0,
    )
    db.add(challenge)
    await db.commit()

    dev_code = code if settings.otp_return_in_response else None
    return OtpRequestOut(
        phone=phone,
        expires_in=settings.otp_ttl_seconds,
        dev_code=dev_code,
    )


@router.post("/otp/verify", response_model=AuthTokensOut)
async def verify_otp(
    body: OtpVerifyIn,
    db: AsyncSession = Depends(get_db),
) -> AuthTokensOut:
    phone = normalize_eg_phone(body.phone)
    now = utcnow()

    # Find active unconsumed challenge
    stmt = (
        select(OtpChallenge)
        .where(
            OtpChallenge.phone == phone,
            OtpChallenge.consumed_at.is_(None),
        )
        .order_by(desc(OtpChallenge.created_at))
        .limit(1)
    )
    result = await db.execute(stmt)
    challenge = result.scalar_one_or_none()

    if not challenge or as_utc(challenge.expires_at) < now:
        raise AppError(400, "OTP_NOT_FOUND", "رمز التحقق منتهي الصلاحية أو غير موجود")

    if challenge.attempts >= settings.otp_max_attempts:
        raise AppError(400, "OTP_MAX_ATTEMPTS", "تم تجاوز الحد الأقصى للمحاولات، اطلب رمزاً جديداً")

    if not verify_otp_hash(phone, body.code.strip(), challenge.code_hash):
        challenge.attempts += 1
        await db.commit()
        remaining_attempts = settings.otp_max_attempts - challenge.attempts
        raise AppError(
            400,
            "OTP_INVALID",
            f"رمز التحقق غير صحيح. المحاولات المتبقية: {max(0, remaining_attempts)}",
        )

    # Mark consumed
    challenge.consumed_at = now

    # Find or create user
    user_stmt = select(User).where(User.phone == phone)
    user_res = await db.execute(user_stmt)
    user = user_res.scalar_one_or_none()

    is_new = False
    if not user:
        is_new = True
        user = User(
            phone=phone,
            name=body.name.strip() if body.name else None,
            role=body.role,
        )
        db.add(user)

    await db.commit()
    await db.refresh(user)

    access_token = create_token(user.id, user.role.value, "access")
    refresh_token = create_token(user.id, user.role.value, "refresh")

    return AuthTokensOut(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        is_new_user=is_new,
        user=UserOut.model_validate(user),
    )


@router.post("/refresh", response_model=TokenRefreshOut)
async def refresh_tokens(
    body: TokenRefreshIn,
    db: AsyncSession = Depends(get_db),
) -> TokenRefreshOut:
    payload = decode_token(body.refresh_token, expected_type="refresh")
    user_id_raw = payload.get("sub")
    if not user_id_raw:
        raise AppError(401, "TOKEN_INVALID", "رمز الدخول غير صالح")

    try:
        user_id = uuid.UUID(user_id_raw)
    except ValueError as e:
        raise AppError(401, "TOKEN_INVALID", "معرف المستخدم غير صالح") from e

    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()

    if not user:
        raise AppError(404, "USER_NOT_FOUND", "المستخدم غير موجود")

    new_access = create_token(user.id, user.role.value, "access")
    new_refresh = create_token(user.id, user.role.value, "refresh")

    return TokenRefreshOut(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
    )
