import enum
from datetime import date

from sqlalchemy import Date, Enum, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdTimestampMixin


class UserRole(enum.StrEnum):
    PATIENT = "patient"
    CAREGIVER = "caregiver"
    ADMIN = "admin"


class User(Base, IdTimestampMixin):
    __tablename__ = "users"

    email: Mapped[str | None] = mapped_column(String(320), unique=True, index=True, nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, index=True, nullable=True)
    name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role", native_enum=False),
        default=UserRole.PATIENT,
        nullable=False,
    )
    language: Mapped[str] = mapped_column(String(10), default="ar", nullable=False)
    timezone: Mapped[str] = mapped_column(String(50), default="Africa/Cairo", nullable=False)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
