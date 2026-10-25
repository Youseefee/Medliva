import uuid
from datetime import datetime

from pydantic import BaseModel


class PairingCodeResponse(BaseModel):
    code: str
    expires_at: datetime


class PairCaregiverRequest(BaseModel):
    code: str


class MissedDoseAlertOut(BaseModel):
    schedule_id: uuid.UUID
    medication_id: uuid.UUID
    medication_name: str
    time_of_day: str
    scheduled_time: datetime


class LinkedPatientOut(BaseModel):
    patient_id: uuid.UUID
    name: str | None
    phone: str | None
    status: str
    linked_at: datetime | None
    today_taken_count: int = 0
    today_missed_count: int = 0
    active_alerts_count: int = 0
    missed_doses: list[MissedDoseAlertOut] = []


class LinkedCaregiverOut(BaseModel):
    caregiver_id: uuid.UUID
    name: str | None
    phone: str | None
    status: str
    linked_at: datetime | None
