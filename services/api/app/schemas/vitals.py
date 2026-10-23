import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class VitalsCreate(BaseModel):
    client_uuid: str | None = None
    type: str  # "bp", "glucose", "pulse"
    value_primary: float
    value_secondary: float | None = None
    meal_context: str | None = None
    raw_transcript: str | None = None


class VitalsOut(BaseModel):
    id: uuid.UUID
    client_uuid: str | None
    patient_id: uuid.UUID
    type: str
    value_primary: float
    value_secondary: float | None
    meal_context: str | None
    band: str
    raw_transcript: str | None
    recorded_at: datetime

    model_config = ConfigDict(from_attributes=True)


class VoiceVitalsRequest(BaseModel):
    transcript: str


class VoiceVitalsResponse(BaseModel):
    transcript: str
    type: str
    value_primary: float
    value_secondary: float | None
    meal_context: str | None
    band: str
    message_ar: str
