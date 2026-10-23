import hashlib
import hmac
import secrets
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

import jwt

from app.core.config import get_settings
from app.core.errors import AppError

TokenType = Literal["access", "refresh"]


def utcnow() -> datetime:
    return datetime.now(UTC)


def as_utc(dt: datetime) -> datetime:
    """SQLite drops tzinfo; treat naive datetimes as UTC."""
    return dt.replace(tzinfo=UTC) if dt.tzinfo is None else dt


def generate_otp(length: int) -> str:
    return "".join(secrets.choice("0123456789") for _ in range(length))


def hash_otp(phone: str, code: str) -> str:
    key = get_settings().jwt_secret.encode()
    return hmac.new(key, f"{phone}:{code}".encode(), hashlib.sha256).hexdigest()


def hash_refresh_token(token: str) -> str:
    """Store only a one-way fingerprint of refresh tokens in the database."""
    return hashlib.sha256(token.encode()).hexdigest()


def verify_otp_hash(phone: str, code: str, expected_hash: str) -> bool:
    return hmac.compare_digest(hash_otp(phone, code), expected_hash)


def create_token(user_id: uuid.UUID, role: str, token_type: TokenType) -> str:
    s = get_settings()
    now = utcnow()
    ttl = (
        timedelta(minutes=s.access_token_expire_minutes)
        if token_type == "access"
        else timedelta(days=s.refresh_token_expire_days)
    )
    payload = {
        "sub": str(user_id),
        "role": role,
        "type": token_type,
        "iat": now,
        "exp": now + ttl,
        "jti": uuid.uuid4().hex,
    }
    return jwt.encode(payload, s.jwt_secret, algorithm=s.jwt_algorithm)


def decode_token(token: str, expected_type: TokenType) -> dict[str, Any]:
    s = get_settings()
    try:
        payload = jwt.decode(token, s.jwt_secret, algorithms=[s.jwt_algorithm])
    except jwt.ExpiredSignatureError as e:
        raise AppError(401, "TOKEN_EXPIRED", "انتهت صلاحية الجلسة") from e
    except jwt.InvalidTokenError as e:
        raise AppError(401, "TOKEN_INVALID", "رمز الدخول غير صالح") from e
    if payload.get("type") != expected_type:
        raise AppError(401, "TOKEN_INVALID", "نوع رمز الدخول غير صحيح")
    return payload
