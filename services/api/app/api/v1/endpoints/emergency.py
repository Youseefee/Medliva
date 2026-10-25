import json
import uuid
from datetime import UTC, datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.db.session import get_db
from app.models.caregiver import CaregiverLink, CaregiverLinkStatus
from app.models.emergency import Alert, AlertType, EmergencyContact
from app.models.user import User
from app.schemas.emergency import (
    AlertOut,
    EmergencyContactCreate,
    EmergencyContactOut,
    SosRequest,
    SosResponse,
)
from app.services.adherence_service import (
    MISSED_DOSE_GRACE_MINUTES,
    MissedDose,
    compute_patient_adherence_and_alerts,
)

router = APIRouter(tags=["emergency"])


@router.post("/emergency/sos", response_model=SosResponse)
async def trigger_emergency_sos(
    payload: SosRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SosResponse:
    # Patient triggers SOS
    patient_id = current_user.id

    # Count contacts and caregivers to notify
    c_stmt = select(EmergencyContact).where(EmergencyContact.patient_id == patient_id)
    c_res = await db.execute(c_stmt)
    contacts = c_res.scalars().all()

    cg_stmt = select(CaregiverLink).where(
        CaregiverLink.patient_id == patient_id,
        CaregiverLink.status == CaregiverLinkStatus.ACTIVE,
    )
    cg_res = await db.execute(cg_stmt)
    caregivers = cg_res.scalars().all()

    notified_count = len(contacts) + len(caregivers)

    sos_payload = {
        "lat": payload.lat,
        "lng": payload.lng,
        "note": payload.note,
        "patient_name": current_user.name,
        "patient_phone": current_user.phone,
    }

    alert = Alert(
        patient_id=patient_id,
        type=AlertType.SOS,
        tier=3,  # Highest tier
        payload_json=json.dumps(sos_payload, ensure_ascii=False),
    )
    db.add(alert)
    await db.commit()
    await db.refresh(alert)

    return SosResponse(
        status="active",
        alert_id=alert.id,
        notified_contacts_count=notified_count,
    )


@router.get("/patients/{patient_id}/alerts", response_model=list[AlertOut])
async def list_patient_alerts(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: int = Query(default=50, ge=1, le=200),
    now: Annotated[datetime | None, Query()] = None,
) -> list[AlertOut]:
    """Recent alerts of a patient (SOS, critical vitals, low stock, missed doses)."""
    await check_patient_access(patient_id, current_user, db)

    ref_now = now or datetime.now(UTC)
    if ref_now.tzinfo is None:
        ref_now = ref_now.replace(tzinfo=UTC)

    stmt = (
        select(Alert)
        .where(Alert.patient_id == patient_id)
        .order_by(Alert.created_at.desc(), Alert.sent_at.desc())
        .limit(limit)
    )
    res = await db.execute(stmt)
    stored = [AlertOut.model_validate(alert) for alert in res.scalars().all()]

    # Missed doses are derived from today's schedule instead of being stored,
    # so they are exposed here with a deterministic id per dose and day.
    _, _, missed_doses = await compute_patient_adherence_and_alerts(patient_id, db, ref_now)
    derived = [_missed_dose_alert(patient_id, dose) for dose in missed_doses]

    alerts = [*stored, *derived]
    alerts.sort(
        key=lambda alert: (
            alert.created_at.replace(tzinfo=UTC)
            if alert.created_at.tzinfo is None
            else alert.created_at,
            alert.id,
        ),
        reverse=True,
    )
    return alerts[:limit]


def _missed_dose_alert(patient_id: uuid.UUID, dose: MissedDose) -> AlertOut:
    escalated_at = dose.scheduled_time + timedelta(minutes=MISSED_DOSE_GRACE_MINUTES)
    return AlertOut(
        id=uuid.uuid5(
            uuid.NAMESPACE_URL,
            f"medliva:missed-dose:{patient_id}:{dose.schedule_id}:"
            f"{dose.scheduled_time.date().isoformat()}",
        ),
        patient_id=patient_id,
        type=AlertType.MISSED_DOSE,
        tier=1,
        payload={
            "schedule_id": str(dose.schedule_id),
            "medication_id": str(dose.medication_id),
            "medication_name": dose.medication_name,
            "time_of_day": dose.time_of_day,
            "scheduled_time": dose.scheduled_time.isoformat(),
        },
        sent_at=escalated_at,
        acknowledged_at=None,
        created_at=escalated_at,
    )


@router.get("/patients/{patient_id}/contacts", response_model=list[EmergencyContactOut])
async def list_emergency_contacts(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[EmergencyContactOut]:
    await check_patient_access(patient_id, current_user, db)

    stmt = select(EmergencyContact).where(EmergencyContact.patient_id == patient_id)
    res = await db.execute(stmt)
    contacts = res.scalars().all()

    return [EmergencyContactOut.model_validate(c) for c in contacts]


@router.post("/patients/{patient_id}/contacts", response_model=EmergencyContactOut, status_code=201)
async def create_emergency_contact(
    patient_id: uuid.UUID,
    payload: EmergencyContactCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> EmergencyContactOut:
    await check_patient_access(patient_id, current_user, db)

    contact = EmergencyContact(
        patient_id=patient_id,
        name=payload.name,
        phone=payload.phone,
        relationship=payload.relationship,
        is_primary=payload.is_primary,
        notify_call=payload.notify_call,
    )
    db.add(contact)
    await db.commit()
    await db.refresh(contact)

    return EmergencyContactOut.model_validate(contact)
