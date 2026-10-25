import json
import uuid
from datetime import UTC, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, model_validator

from app.models.emergency import Alert, AlertType


class EmergencyContactCreate(BaseModel):
    name: str
    phone: str
    relationship: str | None = None
    is_primary: bool = False
    notify_call: bool = True


class EmergencyContactOut(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    name: str
    phone: str
    relationship: str | None
    is_primary: bool

    model_config = ConfigDict(from_attributes=True)


class AlertOut(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    type: AlertType
    tier: int
    payload: dict[str, Any] | None = None
    sent_at: datetime
    acknowledged_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def _parse_payload_json(cls, data: Any) -> Any:
        """Expose the stored JSON blob as a real object for the clients."""
        if not isinstance(data, Alert):
            return data

        payload: dict[str, Any] | None = None
        if data.payload_json:
            try:
                decoded = json.loads(data.payload_json)
            except json.JSONDecodeError:
                decoded = None
            if isinstance(decoded, dict):
                payload = decoded

        created_at = data.created_at
        if created_at is not None and created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=UTC)

        sent_at = data.sent_at
        if sent_at is not None and sent_at.tzinfo is None:
            sent_at = sent_at.replace(tzinfo=UTC)

        ack_at = data.acknowledged_at
        if ack_at is not None and ack_at.tzinfo is None:
            ack_at = ack_at.replace(tzinfo=UTC)

        return {
            "id": data.id,
            "patient_id": data.patient_id,
            "type": data.type,
            "tier": data.tier,
            "payload": payload,
            "sent_at": sent_at or created_at,
            "acknowledged_at": ack_at,
            "created_at": created_at,
        }


class SosRequest(BaseModel):
    lat: float | None = None
    lng: float | None = None
    note: str | None = None


class SosResponse(BaseModel):
    status: str
    alert_id: uuid.UUID
    notified_contacts_count: int
