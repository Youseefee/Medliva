from pydantic import BaseModel, ConfigDict, Field

from app.schemas.user import UserOut


class OtpRequestIn(BaseModel):
    phone: str = Field(..., description="رقم الهاتف (مصري: مثلاً 01012345678 أو +20...)")


class OtpRequestOut(BaseModel):
    phone: str
    expires_in: int
    dev_code: str | None = None


class OtpVerifyIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    phone: str
    code: str = Field(..., min_length=4, max_length=10)
    name: str | None = Field(default=None, max_length=100)


class AuthTokensOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    is_new_user: bool = False
    user: UserOut


class TokenRefreshIn(BaseModel):
    refresh_token: str = Field(..., min_length=1)


class TokenRefreshOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
