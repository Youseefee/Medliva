import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdTimestampMixin


class VitalType(enum.StrEnum):
    BP = "bp"
    GLUCOSE = "glucose"
    PULSE = "pulse"


class VitalBand(enum.StrEnum):
    NORMAL = "normal"
    BORDERLINE = "borderline"
    CRITICAL = "critical"


class VitalsLog(Base, IdTimestampMixin):
    __tablename__ = "vitals_logs"

    client_uuid: Mapped[str | None] = mapped_column(
        String(64), unique=True, index=True, nullable=True
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    type: Mapped[VitalType] = mapped_column(
        Enum(VitalType, name="vital_type", native_enum=False),
        nullable=False,
    )
    value_primary: Mapped[float] = mapped_column(Float, nullable=False)
    value_secondary: Mapped[float | None] = mapped_column(Float, nullable=True)
    meal_context: Mapped[str | None] = mapped_column(String(50), nullable=True)
    band: Mapped[VitalBand] = mapped_column(
        Enum(VitalBand, name="vital_band", native_enum=False),
        default=VitalBand.NORMAL,
        nullable=False,
    )
    raw_transcript: Mapped[str | None] = mapped_column(Text, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True, nullable=False
    )
