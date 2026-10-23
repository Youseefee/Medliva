import uuid
from datetime import datetime

from pydantic import BaseModel


class PairingCodeResponse(BaseModel):
    code: str
    expires_at: datetime


class PairCaregiverRequest(BaseModel):
    code: str


class LinkedPatientOut(BaseModel):
    patient_id: uuid.UUID
    name: str | None
    phone: str
    status: str
    linked_at: datetime | None
