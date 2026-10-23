import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class ScheduleCreate(BaseModel):
    time_of_day: str  # "HH:MM" e.g. "08:30"
    dose_amount: float = 1.0
    meal_relation: str = "after_meal"
    days_mask: int = 127
    instructions_ar: str | None = None


class ScheduleOut(BaseModel):
    id: uuid.UUID
    medication_id: uuid.UUID
    time_of_day: str
    dose_amount: float
    meal_relation: str
    days_mask: int
    instructions_ar: str | None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class MedicationCreate(BaseModel):
    name: str
    trade_name: str | None = None
    active_ingredient: str | None = None
    form: str = "قرص"
    strength: str | None = None
    stock_count: int = 0
    alert_threshold_days: int = 5
    expiry_date: date | None = None
    schedules: list[ScheduleCreate] = []


class MedicationUpdate(BaseModel):
    name: str | None = None
    stock_count: int | None = None
    alert_threshold_days: int | None = None
    expiry_date: date | None = None
    is_active: bool | None = None


class MedicationOut(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    name: str
    trade_name: str | None
    active_ingredient: str | None
    form: str
    strength: str | None
    stock_count: int
    alert_threshold_days: int
    expiry_date: date | None
    is_active: bool
    schedules: list[ScheduleOut] = []

    model_config = ConfigDict(from_attributes=True)


class TodayDoseOut(BaseModel):
    schedule_id: uuid.UUID
    medication_id: uuid.UUID
    medication_name: str
    time_of_day: str
    dose_amount: float
    meal_relation: str
    instructions_ar: str | None
    status: str  # "taken", "pending", "snoozed", "missed", "skipped"
    intake_log_id: uuid.UUID | None = None
    actual_time: datetime | None = None
