import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.user import UserRole


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str | None = None
    phone: str | None = None
    name: str | None = None
    role: UserRole
    language: str
    timezone: str
    birth_date: date | None = None
    address: str | None = None
    created_at: datetime


class UserUpdateIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # NOTE: `role` is deliberately absent. A user must not be able to
    # change their own role through PATCH /me (previously a self-service
    # patient <-> caregiver switch, and the schema already rejected
    # `admin`). Role changes, if ever needed, belong to a separate
    # admin-only endpoint — there is currently no such endpoint, so
    # sending `role` now returns 422 (extra="forbid").
    name: str | None = Field(None, max_length=100)
    language: str | None = Field(None, max_length=10)
    timezone: str | None = Field(None, max_length=50)
    birth_date: date | None = None
    address: str | None = None
