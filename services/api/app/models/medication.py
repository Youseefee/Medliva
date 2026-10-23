import enum
import uuid
from datetime import date, datetime, time

from sqlalchemy import Boolean, Date, DateTime, Enum, Float, ForeignKey, Integer, String, Time
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdTimestampMixin


class MealRelation(enum.StrEnum):
    BEFORE_MEAL = "before_meal"
    AFTER_MEAL = "after_meal"
    WITH_MEAL = "with_meal"
    INDEPENDENT = "independent"


class IntakeStatus(enum.StrEnum):
    TAKEN = "taken"
    SNOOZED = "snoozed"
    MISSED = "missed"
    SKIPPED = "skipped"


class DrugCatalog(Base, IdTimestampMixin):
    __tablename__ = "drug_catalog"

    trade_name: Mapped[str] = mapped_column(String(150), index=True, nullable=False)
    active_ingredient: Mapped[str | None] = mapped_column(String(150), nullable=True)
    strength: Mapped[str | None] = mapped_column(String(50), nullable=True)
    form: Mapped[str | None] = mapped_column(String(50), default="قرص", nullable=True)
    manufacturer: Mapped[str | None] = mapped_column(String(100), nullable=True)
    price_egp: Mapped[float | None] = mapped_column(Float, nullable=True)


class Medication(Base, IdTimestampMixin):
    __tablename__ = "medications"

    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    drug_catalog_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("drug_catalog.id", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    trade_name: Mapped[str | None] = mapped_column(String(150), nullable=True)
    active_ingredient: Mapped[str | None] = mapped_column(String(150), nullable=True)
    form: Mapped[str] = mapped_column(String(50), default="قرص", nullable=False)
    strength: Mapped[str | None] = mapped_column(String(50), nullable=True)
    pill_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    stock_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    alert_threshold_days: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    expiry_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class Schedule(Base, IdTimestampMixin):
    __tablename__ = "schedules"

    medication_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("medications.id", ondelete="CASCADE"), index=True, nullable=False
    )
    time_of_day: Mapped[time] = mapped_column(Time, nullable=False)
    days_mask: Mapped[int] = mapped_column(
        Integer, default=127, nullable=False
    )  # 127 = 0b1111111 (all days)
    dose_amount: Mapped[float] = mapped_column(Float, default=1.0, nullable=False)
    meal_relation: Mapped[MealRelation] = mapped_column(
        Enum(MealRelation, name="meal_relation", native_enum=False),
        default=MealRelation.AFTER_MEAL,
        nullable=False,
    )
    instructions_ar: Mapped[str | None] = mapped_column(String(255), nullable=True)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class IntakeLog(Base, IdTimestampMixin):
    __tablename__ = "intake_logs"

    client_uuid: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    schedule_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("schedules.id", ondelete="CASCADE"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    scheduled_time: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), index=True, nullable=False
    )
    actual_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[IntakeStatus] = mapped_column(
        Enum(IntakeStatus, name="intake_status", native_enum=False),
        default=IntakeStatus.TAKEN,
        nullable=False,
    )
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    logged_offline: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
