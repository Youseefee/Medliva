from datetime import datetime
from typing import Any

from pydantic import BaseModel


class ReportShareCreate(BaseModel):
    scope: str = "full"
    expires_in_hours: int = 48


class ReportShareOut(BaseModel):
    token: str
    url: str
    expires_at: datetime


class PublicReportOut(BaseModel):
    patient_name: str
    patient_phone: str
    adherence_rate_pct: float
    total_doses: int
    taken_doses: int
    missed_doses_count: int
    active_medications: list[dict[str, Any]]
    recent_vitals: list[dict[str, Any]]
    recent_intake_logs: list[dict[str, Any]]
