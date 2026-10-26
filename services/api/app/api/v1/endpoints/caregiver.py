import secrets
import uuid
from datetime import UTC, datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.exc import MultipleResultsFound
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.core.errors import AppError
from app.db.session import get_db
from app.models.caregiver import CaregiverLink, CaregiverLinkStatus
from app.models.user import User, UserRole
from app.schemas.caregiver import (
    LinkedCaregiverOut,
    LinkedPatientOut,
    MissedDoseAlertOut,
    PairCaregiverRequest,
    PairingCodeResponse,
)
from app.services.adherence_service import compute_patient_adherence_and_alerts

router = APIRouter(prefix="/caregiver", tags=["caregiver"])

# Patient scoped caregiver routes (the /caregiver prefix does not apply).
patient_router = APIRouter(tags=["caregiver"])


@router.post("/pairing-code", response_model=PairingCodeResponse)
async def generate_pairing_code(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PairingCodeResponse:
    if current_user.role != UserRole.PATIENT:
        raise AppError(400, "INVALID_ROLE", "يجب أن يكون الحساب من نوع مريض لتوليد رمز الاقتران")

    # secrets (not random) for a code that authenticates a pairing.
    code = f"{secrets.randbelow(900000) + 100000}"
    expires_at = datetime.now(UTC) + timedelta(minutes=10)

    # Find existing pending link or create new
    stmt = select(CaregiverLink).where(
        CaregiverLink.patient_id == current_user.id,
        CaregiverLink.status == CaregiverLinkStatus.PENDING,
    )
    result = await db.execute(stmt)
    try:
        link = result.scalar_one_or_none()
    except MultipleResultsFound:
        raise AppError(
            400,
            "PAIRING_CODE_CONFLICT",
            "يوجد أكثر من طلب اقتران معلق؛ أعد توليد الرمز وحاول مجددًا",
        ) from None

    if link:
        link.pairing_code = code
        link.pairing_code_expires_at = expires_at
    else:
        link = CaregiverLink(
            patient_id=current_user.id,
            pairing_code=code,
            pairing_code_expires_at=expires_at,
            status=CaregiverLinkStatus.PENDING,
        )
        db.add(link)

    await db.commit()
    return PairingCodeResponse(code=code, expires_at=expires_at)


@router.post("/pair", response_model=LinkedPatientOut)
async def pair_caregiver_with_patient(
    payload: PairCaregiverRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> LinkedPatientOut:
    if current_user.role != UserRole.CAREGIVER:
        raise AppError(400, "INVALID_ROLE", "يجب أن يكون الحساب من نوع مرافق لربط مريض")

    stmt = select(CaregiverLink).where(
        CaregiverLink.pairing_code == payload.code.strip(),
        CaregiverLink.status == CaregiverLinkStatus.PENDING,
    )
    result = await db.execute(stmt)
    try:
        link = result.scalar_one_or_none()
    except MultipleResultsFound:
        # A duplicated code must not surface as a generic 500: tell the
        # caregiver the code is ambiguous and to ask for a fresh one.
        raise AppError(
            400,
            "PAIRING_CODE_CONFLICT",
            "رمز الاقتران مكرر؛ اطلب رمزًا جديدًا من المريض وحاول مجددًا",
        ) from None

    now = datetime.now(UTC)
    if not link:
        raise AppError(400, "INVALID_CODE", "رمز الاقتران غير صحيح أو منتهي الصلاحية")

    exp = link.pairing_code_expires_at
    if exp and exp.tzinfo is None:
        exp = exp.replace(tzinfo=UTC)

    if not exp or exp < now:
        raise AppError(400, "INVALID_CODE", "رمز الاقتران غير صحيح أو منتهي الصلاحية")

    if link.patient_id == current_user.id:
        raise AppError(400, "CANNOT_PAIR_SELF", "لا يمكنك الاقتران بنفسك")

    link.caregiver_id = current_user.id
    link.status = CaregiverLinkStatus.ACTIVE
    link.linked_at = now
    link.pairing_code = None
    link.pairing_code_expires_at = None

    # Fetch patient details
    patient = await db.get(User, link.patient_id)
    await db.commit()

    return LinkedPatientOut(
        patient_id=link.patient_id,
        name=patient.name if patient else None,
        phone=patient.phone if patient else "",
        status=link.status.value,
        linked_at=link.linked_at,
    )


async def _compute_patient_adherence_and_alerts(
    patient_id: uuid.UUID,
    db: AsyncSession,
    now_utc: datetime,
) -> tuple[int, int, list[MissedDoseAlertOut]]:
    taken_count, _, missed_doses = await compute_patient_adherence_and_alerts(
        patient_id, db, now_utc
    )
    return (
        taken_count,
        len(missed_doses),
        [
            MissedDoseAlertOut(
                schedule_id=dose.schedule_id,
                medication_id=dose.medication_id,
                medication_name=dose.medication_name,
                time_of_day=dose.time_of_day,
                scheduled_time=dose.scheduled_time,
            )
            for dose in missed_doses
        ],
    )


@router.get("/patients", response_model=list[LinkedPatientOut])
async def list_linked_patients(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    now: Annotated[datetime | None, Query()] = None,
) -> list[LinkedPatientOut]:
    ref_now = now or datetime.now(UTC)
    if ref_now.tzinfo is None:
        ref_now = ref_now.replace(tzinfo=UTC)

    stmt = (
        select(CaregiverLink, User)
        .join(User, CaregiverLink.patient_id == User.id)
        .where(
            CaregiverLink.caregiver_id == current_user.id,
            CaregiverLink.status == CaregiverLinkStatus.ACTIVE,
        )
    )
    result = await db.execute(stmt)
    rows = result.all()

    output = []
    for link, patient in rows:
        taken_cnt, missed_cnt, missed_doses = await _compute_patient_adherence_and_alerts(
            patient.id, db, ref_now
        )
        output.append(
            LinkedPatientOut(
                patient_id=patient.id,
                name=patient.name,
                phone=patient.phone,
                status=link.status.value,
                linked_at=link.linked_at,
                today_taken_count=taken_cnt,
                today_missed_count=missed_cnt,
                active_alerts_count=missed_cnt,
                missed_doses=missed_doses,
            )
        )
    return output


@router.get("/alerts", response_model=list[MissedDoseAlertOut])
async def list_caregiver_alerts(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    now: Annotated[datetime | None, Query()] = None,
) -> list[MissedDoseAlertOut]:
    patients = await list_linked_patients(current_user=current_user, db=db, now=now)
    alerts: list[MissedDoseAlertOut] = []
    for p in patients:
        alerts.extend(p.missed_doses)
    return alerts


@patient_router.get(
    "/patients/{patient_id}/caregivers",
    response_model=list[LinkedCaregiverOut],
)
async def list_patient_caregivers(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[LinkedCaregiverOut]:
    """The caregivers monitoring a patient (patient side view)."""
    await check_patient_access(patient_id, current_user, db)

    stmt = (
        select(CaregiverLink, User)
        .join(User, CaregiverLink.caregiver_id == User.id)
        .where(
            CaregiverLink.patient_id == patient_id,
            CaregiverLink.status == CaregiverLinkStatus.ACTIVE,
        )
    )
    result = await db.execute(stmt)
    rows = result.all()

    return [
        LinkedCaregiverOut(
            caregiver_id=caregiver.id,
            name=caregiver.name,
            phone=caregiver.phone,
            status=link.status.value,
            linked_at=link.linked_at,
        )
        for link, caregiver in rows
    ]
