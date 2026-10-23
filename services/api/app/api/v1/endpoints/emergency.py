import json
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.db.session import get_db
from app.models.caregiver import CaregiverLink, CaregiverLinkStatus
from app.models.emergency import Alert, AlertType, EmergencyContact
from app.models.user import User
from app.schemas.emergency import (
    EmergencyContactCreate,
    EmergencyContactOut,
    SosRequest,
    SosResponse,
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
        notify_sms=payload.notify_sms,
        notify_call=payload.notify_call,
    )
    db.add(contact)
    await db.commit()
    await db.refresh(contact)

    return EmergencyContactOut.model_validate(contact)
