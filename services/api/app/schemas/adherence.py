import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class IntakeLogCreate(BaseModel):
    client_uuid: str
    schedule_id: uuid.UUID
    scheduled_time: datetime
    actual_time: datetime | None = None
    status: str = "taken"  # "taken", "snoozed", "missed", "skipped"
    reason: str | None = None
    logged_offline: bool = False


class IntakeLogOut(BaseModel):
    id: uuid.UUID
    client_uuid: str
    schedule_id: uuid.UUID
    patient_id: uuid.UUID
    scheduled_time: datetime
    actual_time: datetime | None
    status: str
    reason: str | None
    logged_offline: bool

    model_config = ConfigDict(from_attributes=True)


class SyncItem(BaseModel):
    client_uuid: str
    entity: str  # "intake_log", "vitals_log", "medication"
    op: str  # "create", "update"
    payload: dict[str, Any]


class SyncBatchRequest(BaseModel):
    items: list[SyncItem]


class SyncBatchResponse(BaseModel):
    processed: int
    synced_client_uuids: list[str]
