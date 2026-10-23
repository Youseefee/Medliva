import random
from datetime import UTC, datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.core.errors import AppError
from app.db.session import get_db
from app.models.caregiver import CaregiverLink, CaregiverLinkStatus
from app.models.user import User, UserRole
from app.schemas.caregiver import LinkedPatientOut, PairCaregiverRequest, PairingCodeResponse

router = APIRouter(prefix="/caregiver", tags=["caregiver"])


@router.post("/pairing-code", response_model=PairingCodeResponse)
async def generate_pairing_code(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PairingCodeResponse:
    if current_user.role != UserRole.PATIENT:
        raise AppError(400, "INVALID_ROLE", "يجب أن يكون الحساب من نوع مريض لتوليد رمز الاقتران")

    code = f"{random.randint(100000, 999999)}"
    expires_at = datetime.now(UTC) + timedelta(minutes=10)

    # Find existing pending link or create new
    stmt = select(CaregiverLink).where(
        CaregiverLink.patient_id == current_user.id,
        CaregiverLink.status == CaregiverLinkStatus.PENDING,
    )
    result = await db.execute(stmt)
    link = result.scalar_one_or_none()

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
    link = result.scalar_one_or_none()

    now = datetime.now(UTC)
    exp = link.pairing_code_expires_at
    if exp and exp.tzinfo is None:
        exp = exp.replace(tzinfo=UTC)

    if not link or not exp or exp < now:
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


@router.get("/patients", response_model=list[LinkedPatientOut])
async def list_linked_patients(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[LinkedPatientOut]:
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
        output.append(
            LinkedPatientOut(
                patient_id=patient.id,
                name=patient.name,
                phone=patient.phone,
                status=link.status.value,
                linked_at=link.linked_at,
            )
        )
    return output
