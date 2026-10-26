from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel


class ReportShareCreate(BaseModel):
    # Only these scopes are honoured by GET /public/reports/{token}.
    # Unknown scopes are now rejected (422) instead of being silently
    # ignored: previously any scope string was stored and the public
    # view always returned the same data.
    # - "summary_30d": last 30 days, as sent by the mobile app.
    # - "full": a wider bounded view (last 90 days, more items).
    scope: Literal["full", "summary_30d"] = "full"
    expires_in_hours: int = 48


class ReportShareOut(BaseModel):
    token: str
    url: str
    expires_at: datetime


class PublicReportOut(BaseModel):
    patient_name: str
    patient_phone: str | None
    adherence_rate_pct: float
    total_doses: int
    taken_doses: int
    missed_doses_count: int
    active_medications: list[dict[str, Any]]
    recent_vitals: list[dict[str, Any]]
    recent_intake_logs: list[dict[str, Any]]


class ReportSummaryOut(BaseModel):
    patient_id: str
    patient_name: str
    patient_phone: str | None
    from_date: str
    to_date: str
    adherence_rate_pct: float
    total_doses: int
    taken_doses: int
    skipped_doses: int
    missed_doses_count: int
    active_medications: list[dict[str, Any]]
    adherence_history: list[dict[str, Any]]
    vitals_history: list[dict[str, Any]]
