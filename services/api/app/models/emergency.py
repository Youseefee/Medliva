import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdTimestampMixin


class AlertType(enum.StrEnum):
    MISSED_DOSE = "missed_dose"
    CRITICAL_VITAL = "critical_vital"
    LOW_STOCK = "low_stock"
    EXPIRY = "expiry"
    SOS = "sos"


class EmergencyContact(Base, IdTimestampMixin):
    __tablename__ = "emergency_contacts"

    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str] = mapped_column(String(20), nullable=False)
    relationship: Mapped[str | None] = mapped_column(String(50), nullable=True)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    notify_sms: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    notify_call: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class Alert(Base, IdTimestampMixin):
    __tablename__ = "alerts"

    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    type: Mapped[AlertType] = mapped_column(
        Enum(AlertType, name="alert_type", native_enum=False),
        nullable=False,
    )
    tier: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    payload_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    acknowledged_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
