import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.user import UserRole


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    phone: str
    name: str | None = None
    role: UserRole
    language: str
    timezone: str
    birth_date: date | None = None
    address: str | None = None
    created_at: datetime


class UserUpdateIn(BaseModel):
    name: str | None = Field(None, max_length=100)
    role: UserRole | None = None
    language: str | None = Field(None, max_length=10)
    timezone: str | None = Field(None, max_length=50)
    birth_date: date | None = None
    address: str | None = None

