import uuid

from pydantic import BaseModel, ConfigDict


class EmergencyContactCreate(BaseModel):
    name: str
    phone: str
    relationship: str | None = None
    is_primary: bool = False
    notify_sms: bool = True
    notify_call: bool = True


class EmergencyContactOut(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    name: str
    phone: str
    relationship: str | None
    is_primary: bool

    model_config = ConfigDict(from_attributes=True)


class SosRequest(BaseModel):
    lat: float | None = None
    lng: float | None = None
    note: str | None = None


class SosResponse(BaseModel):
    status: str
    alert_id: uuid.UUID
    notified_contacts_count: int
