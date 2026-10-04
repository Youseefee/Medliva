from pydantic import BaseModel, Field

from app.models.user import UserRole
from app.schemas.user import UserOut


class OtpRequestIn(BaseModel):
    phone: str = Field(..., description="رقم الهاتف (مصري: مثلاً 01012345678 أو +20...)")


class OtpRequestOut(BaseModel):
    phone: str
    expires_in: int
    dev_code: str | None = None


class OtpVerifyIn(BaseModel):
    phone: str
    code: str = Field(..., min_length=4, max_length=10)
    role: UserRole = Field(default=UserRole.PATIENT, description="الدور في حالة المستخدم الجديد")
    name: str | None = Field(default=None, max_length=100)


class AuthTokensOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    is_new_user: bool = False
    user: UserOut


class TokenRefreshIn(BaseModel):
    refresh_token: str


class TokenRefreshOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
