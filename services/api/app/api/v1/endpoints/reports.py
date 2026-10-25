import hashlib
import secrets
import uuid
from datetime import UTC, date, datetime, time, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.core.errors import AppError
from app.db.session import get_db
from app.models.medication import IntakeLog, IntakeStatus, Medication, Schedule
from app.models.reports import ReportShare
from app.models.user import User
from app.models.vitals import VitalsLog
from app.schemas.reports import (
    PublicReportOut,
    ReportShareCreate,
    ReportShareOut,
    ReportSummaryOut,
)

router = APIRouter(tags=["reports"])


def hash_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


@router.post("/patients/{patient_id}/reports/share", response_model=ReportShareOut)
async def create_report_share(
    patient_id: uuid.UUID,
    payload: ReportShareCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReportShareOut:
    await check_patient_access(patient_id, current_user, db)

    raw_token = secrets.token_urlsafe(32)
    token_hash = hash_token(raw_token)
    expires_at = datetime.now(UTC) + timedelta(hours=payload.expires_in_hours)

    share = ReportShare(
        patient_id=patient_id,
        token_hash=token_hash,
        scope=payload.scope,
        expires_at=expires_at,
        views_count=0,
        revoked=False,
    )
    db.add(share)
    await db.commit()

    return ReportShareOut(
        token=raw_token,
        url=f"/r/{raw_token}",
        expires_at=expires_at,
    )


@router.get("/public/reports/{token}", response_model=PublicReportOut)
async def get_public_report(
    token: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PublicReportOut:
    token_hash = hash_token(token)
    now = datetime.now(UTC)

    stmt = select(ReportShare).where(
        ReportShare.token_hash == token_hash,
        ReportShare.revoked == False,  # noqa: E712
    )
    res = await db.execute(stmt)
    share = res.scalar_one_or_none()

    if not share:
        raise AppError(404, "REPORT_EXPIRED", "رابط التقرير الطبي غير صالح أو انتهت صلاحيته")

    expires_at = share.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=UTC)

    if expires_at < now:
        raise AppError(404, "REPORT_EXPIRED", "رابط التقرير الطبي غير صالح أو انتهت صلاحيته")

    share.views_count += 1
    await db.commit()

    patient = await db.get(User, share.patient_id)
    if not patient:
        raise AppError(404, "PATIENT_NOT_FOUND", "المريض غير موجود")

    # Fetch active medications
    med_stmt = select(Medication).where(
        Medication.patient_id == patient.id,
        Medication.is_active == True,  # noqa: E712
    )
    med_res = await db.execute(med_stmt)
    medications = med_res.scalars().all()

    meds_list = []
    for med in medications:
        s_stmt = select(Schedule).where(Schedule.medication_id == med.id)
        s_res = await db.execute(s_stmt)
        scheds = s_res.scalars().all()
        meds_list.append(
            {
                "name": med.name,
                "dose_form": med.form,
                "strength": med.strength,
                "stock_count": med.stock_count,
                "times": [s.time_of_day.strftime("%H:%M") for s in scheds],
            }
        )

    # Fetch last 30 days intake logs
    thirty_days_ago = now - timedelta(days=30)
    intake_stmt = (
        select(IntakeLog)
        .where(
            IntakeLog.patient_id == patient.id,
            IntakeLog.scheduled_time >= thirty_days_ago,
        )
        .order_by(IntakeLog.scheduled_time.desc())
    )
    intake_res = await db.execute(intake_stmt)
    intake_logs = intake_res.scalars().all()

    total_doses = len(intake_logs)
    taken_doses = sum(1 for log in intake_logs if log.status == IntakeStatus.TAKEN)
    missed_doses = sum(1 for log in intake_logs if log.status == IntakeStatus.MISSED)
    adherence_pct = round((taken_doses / total_doses * 100), 1) if total_doses > 0 else 100.0

    # Fetch recent vitals
    vitals_stmt = (
        select(VitalsLog)
        .where(VitalsLog.patient_id == patient.id)
        .order_by(VitalsLog.recorded_at.desc())
        .limit(20)
    )
    vitals_res = await db.execute(vitals_stmt)
    vitals = vitals_res.scalars().all()

    vitals_list = [
        {
            "type": v.type.value,
            "value_primary": v.value_primary,
            "value_secondary": v.value_secondary,
            "meal_context": v.meal_context,
            "band": v.band.value,
            "recorded_at": v.recorded_at.isoformat(),
        }
        for v in vitals
    ]

    recent_logs_list = [
        {
            "scheduled_time": log.scheduled_time.isoformat(),
            "actual_time": log.actual_time.isoformat() if log.actual_time else None,
            "status": log.status.value,
            "reason": log.reason,
        }
        for log in intake_logs[:20]
    ]

    return PublicReportOut(
        patient_name=patient.name or "مريض Medliva",
        patient_phone=patient.phone,
        adherence_rate_pct=adherence_pct,
        total_doses=total_doses,
        taken_doses=taken_doses,
        missed_doses_count=missed_doses,
        active_medications=meds_list,
        recent_vitals=vitals_list,
        recent_intake_logs=recent_logs_list,
    )


@router.get("/patients/{patient_id}/reports/summary", response_model=ReportSummaryOut)
async def get_patient_report_summary(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    from_date: Annotated[date | None, Query(alias="from")] = None,
    to_date: Annotated[date | None, Query(alias="to")] = None,
) -> ReportSummaryOut:
    await check_patient_access(patient_id, current_user, db)

    patient = await db.get(User, patient_id)
    if not patient:
        raise AppError(404, "PATIENT_NOT_FOUND", "المريض غير موجود")

    end_d = to_date or datetime.now(UTC).date()
    start_d = from_date or (end_d - timedelta(days=30))
    start_dt = datetime.combine(start_d, time.min).replace(tzinfo=UTC)
    end_dt = datetime.combine(end_d, time.max).replace(tzinfo=UTC)

    med_stmt = select(Medication).where(
        Medication.patient_id == patient.id,
        Medication.is_active == True,  # noqa: E712
    )
    med_res = await db.execute(med_stmt)
    medications = med_res.scalars().all()
    med_by_id = {m.id: m for m in medications}

    meds_list = []
    sched_to_med_name: dict[uuid.UUID, str] = {}
    for med in medications:
        s_stmt = select(Schedule).where(Schedule.medication_id == med.id)
        s_res = await db.execute(s_stmt)
        scheds = s_res.scalars().all()
        for s in scheds:
            sched_to_med_name[s.id] = med.name
        meds_list.append(
            {
                "id": str(med.id),
                "name": med.name,
                "dose_form": med.form,
                "strength": med.strength,
                "stock_count": med.stock_count,
                "times": [s.time_of_day.strftime("%H:%M") for s in scheds],
            }
        )

    intake_stmt = (
        select(IntakeLog)
        .where(
            IntakeLog.patient_id == patient.id,
            IntakeLog.scheduled_time >= start_dt,
            IntakeLog.scheduled_time <= end_dt,
        )
        .order_by(IntakeLog.scheduled_time.desc())
    )
    intake_res = await db.execute(intake_stmt)
    intake_logs = intake_res.scalars().all()

    total_doses = len(intake_logs)
    taken_doses = sum(1 for log in intake_logs if log.status == IntakeStatus.TAKEN)
    skipped_doses = sum(1 for log in intake_logs if log.status == IntakeStatus.SKIPPED)
    missed_doses = sum(1 for log in intake_logs if log.status == IntakeStatus.MISSED)
    adherence_pct = round((taken_doses / total_doses * 100), 1) if total_doses > 0 else 100.0

    adherence_history = [
        {
            "schedule_id": str(log.schedule_id),
            "medication_name": sched_to_med_name.get(log.schedule_id, ""),
            "scheduled_time": log.scheduled_time.isoformat(),
            "actual_time": log.actual_time.isoformat() if log.actual_time else None,
            "status": log.status.value,
            "reason": log.reason,
        }
        for log in intake_logs
    ]

    vitals_stmt = (
        select(VitalsLog)
        .where(
            VitalsLog.patient_id == patient.id,
            VitalsLog.recorded_at >= start_dt,
            VitalsLog.recorded_at <= end_dt,
        )
        .order_by(VitalsLog.recorded_at.desc())
    )
    vitals_res = await db.execute(vitals_stmt)
    vitals = vitals_res.scalars().all()

    vitals_history = [
        {
            "type": v.type.value,
            "value_primary": v.value_primary,
            "value_secondary": v.value_secondary,
            "meal_context": v.meal_context,
            "band": v.band.value,
            "recorded_at": v.recorded_at.isoformat(),
        }
        for v in vitals
    ]

    _ = med_by_id
    return ReportSummaryOut(
        patient_id=str(patient.id),
        patient_name=patient.name or "مريض Medliva",
        patient_phone=patient.phone,
        from_date=start_d.isoformat(),
        to_date=end_d.isoformat(),
        adherence_rate_pct=adherence_pct,
        total_doses=total_doses,
        taken_doses=taken_doses,
        skipped_doses=skipped_doses,
        missed_doses_count=missed_doses,
        active_medications=meds_list,
        adherence_history=adherence_history,
        vitals_history=vitals_history,
    )
