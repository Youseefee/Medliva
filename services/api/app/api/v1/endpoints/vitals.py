import json
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.db.session import get_db
from app.models.emergency import Alert, AlertType
from app.models.user import User
from app.models.vitals import VitalBand, VitalsLog, VitalType
from app.schemas.vitals import (
    VitalsCreate,
    VitalsOut,
)
from app.services.triage import triage_bp, triage_glucose, triage_pulse

router = APIRouter(tags=["vitals"])


@router.get("/patients/{patient_id}/vitals", response_model=list[VitalsOut])
async def list_vitals(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    type: str | None = Query(None, description="bp, glucose, or pulse"),
    limit: int = Query(50, ge=1, le=200),
) -> list[VitalsOut]:
    await check_patient_access(patient_id, current_user, db)

    stmt = select(VitalsLog).where(VitalsLog.patient_id == patient_id)
    if type:
        stmt = stmt.where(VitalsLog.type == VitalType(type))

    stmt = stmt.order_by(VitalsLog.recorded_at.desc()).limit(limit)
    res = await db.execute(stmt)
    records = res.scalars().all()

    return [
        VitalsOut(
            id=r.id,
            client_uuid=r.client_uuid,
            patient_id=r.patient_id,
            type=r.type.value,
            value_primary=r.value_primary,
            value_secondary=r.value_secondary,
            meal_context=r.meal_context,
            band=r.band.value,
            raw_transcript=r.raw_transcript,
            recorded_at=r.recorded_at,
        )
        for r in records
    ]


@router.post("/patients/{patient_id}/vitals", response_model=VitalsOut, status_code=201)
async def create_vital(
    patient_id: uuid.UUID,
    payload: VitalsCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> VitalsOut:
    await check_patient_access(patient_id, current_user, db)

    vital_type = VitalType(payload.type)
    if vital_type == VitalType.BP:
        band, _ = triage_bp(payload.value_primary, payload.value_secondary)
    elif vital_type == VitalType.GLUCOSE:
        band, _ = triage_glucose(payload.value_primary, payload.meal_context)
    else:
        band, _ = triage_pulse(payload.value_primary)

    vlog = VitalsLog(
        client_uuid=payload.client_uuid,
        patient_id=patient_id,
        type=vital_type,
        value_primary=payload.value_primary,
        value_secondary=payload.value_secondary,
        meal_context=payload.meal_context,
        band=VitalBand(band),
        raw_transcript=payload.raw_transcript,
    )
    db.add(vlog)

    # If critical, trigger Alert
    if band == "critical":
        alert_payload = {
            "type": vital_type.value,
            "value_primary": payload.value_primary,
            "value_secondary": payload.value_secondary,
        }
        alert = Alert(
            patient_id=patient_id,
            type=AlertType.CRITICAL_VITAL,
            tier=2,
            payload_json=json.dumps(alert_payload, ensure_ascii=False),
        )
        db.add(alert)

    await db.commit()
    await db.refresh(vlog)

    return VitalsOut(
        id=vlog.id,
        client_uuid=vlog.client_uuid,
        patient_id=vlog.patient_id,
        type=vlog.type.value,
        value_primary=vlog.value_primary,
        value_secondary=vlog.value_secondary,
        meal_context=vlog.meal_context,
        band=vlog.band.value,
        raw_transcript=vlog.raw_transcript,
        recorded_at=vlog.recorded_at,
    )
