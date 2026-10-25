import uuid
from datetime import UTC, datetime, time
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.core.errors import AppError
from app.db.session import get_db
from app.models.medication import IntakeLog, MealRelation, Medication, Schedule
from app.models.user import User
from app.schemas.medication import (
    MedicationCreate,
    MedicationOut,
    MedicationUpdate,
    ScheduleCreate,
    ScheduleOut,
    TodayDoseOut,
)

router = APIRouter(tags=["medications"])


def parse_time_str(val: str) -> time:
    parts = val.split(":")
    return time(int(parts[0]), int(parts[1]))


@router.get("/patients/{patient_id}/medications", response_model=list[MedicationOut])
async def list_medications(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[MedicationOut]:
    await check_patient_access(patient_id, current_user, db)

    stmt = select(Medication).where(
        Medication.patient_id == patient_id,
        Medication.is_active == True,  # noqa: E712
    )
    result = await db.execute(stmt)
    medications = result.scalars().all()

    output = []
    for med in medications:
        sched_stmt = select(Schedule).where(
            Schedule.medication_id == med.id,
            Schedule.is_active == True,  # noqa: E712
        )
        sched_res = await db.execute(sched_stmt)
        schedules = sched_res.scalars().all()

        output.append(
            MedicationOut(
                id=med.id,
                patient_id=med.patient_id,
                name=med.name,
                trade_name=med.trade_name,
                active_ingredient=med.active_ingredient,
                form=med.form,
                strength=med.strength,
                stock_count=med.stock_count,
                alert_threshold_days=med.alert_threshold_days,
                expiry_date=med.expiry_date,
                is_active=med.is_active,
                schedules=[
                    ScheduleOut(
                        id=s.id,
                        medication_id=s.medication_id,
                        time_of_day=s.time_of_day.strftime("%H:%M"),
                        dose_amount=s.dose_amount,
                        meal_relation=s.meal_relation.value,
                        days_mask=s.days_mask,
                        instructions_ar=s.instructions_ar,
                        is_active=s.is_active,
                    )
                    for s in schedules
                ],
            )
        )
    return output


@router.post("/patients/{patient_id}/medications", response_model=MedicationOut, status_code=201)
async def create_medication(
    patient_id: uuid.UUID,
    payload: MedicationCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MedicationOut:
    await check_patient_access(patient_id, current_user, db)

    med = Medication(
        patient_id=patient_id,
        name=payload.name,
        trade_name=payload.trade_name,
        active_ingredient=payload.active_ingredient,
        form=payload.form,
        strength=payload.strength,
        stock_count=payload.stock_count,
        alert_threshold_days=payload.alert_threshold_days,
        expiry_date=payload.expiry_date,
        is_active=True,
    )
    db.add(med)
    await db.flush()

    created_schedules: list[Schedule] = []
    for s in payload.schedules:
        sched = Schedule(
            medication_id=med.id,
            time_of_day=parse_time_str(s.time_of_day),
            dose_amount=s.dose_amount,
            meal_relation=MealRelation(s.meal_relation),
            days_mask=s.days_mask,
            instructions_ar=s.instructions_ar,
            is_active=True,
        )
        db.add(sched)
        created_schedules.append(sched)

    await db.commit()
    await db.refresh(med)

    return MedicationOut(
        id=med.id,
        patient_id=med.patient_id,
        name=med.name,
        trade_name=med.trade_name,
        active_ingredient=med.active_ingredient,
        form=med.form,
        strength=med.strength,
        stock_count=med.stock_count,
        alert_threshold_days=med.alert_threshold_days,
        expiry_date=med.expiry_date,
        is_active=med.is_active,
        schedules=[
            ScheduleOut(
                id=s.id,
                medication_id=s.medication_id,
                time_of_day=s.time_of_day.strftime("%H:%M"),
                dose_amount=s.dose_amount,
                meal_relation=s.meal_relation.value,
                days_mask=s.days_mask,
                instructions_ar=s.instructions_ar,
                is_active=s.is_active,
            )
            for s in created_schedules
        ],
    )


@router.patch("/medications/{medication_id}", response_model=MedicationOut)
async def update_medication(
    medication_id: uuid.UUID,
    payload: MedicationUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MedicationOut:
    med = await db.get(Medication, medication_id)
    if not med:
        raise AppError(404, "MEDICATION_NOT_FOUND", "الدواء غير موجود")

    await check_patient_access(med.patient_id, current_user, db)

    if payload.name is not None:
        med.name = payload.name
    if payload.stock_count is not None:
        med.stock_count = payload.stock_count
    if payload.alert_threshold_days is not None:
        med.alert_threshold_days = payload.alert_threshold_days
    if payload.expiry_date is not None:
        med.expiry_date = payload.expiry_date
    if payload.is_active is not None:
        med.is_active = payload.is_active

    await db.commit()
    await db.refresh(med)

    sched_stmt = select(Schedule).where(Schedule.medication_id == med.id)
    sched_res = await db.execute(sched_stmt)
    schedules = sched_res.scalars().all()

    return MedicationOut(
        id=med.id,
        patient_id=med.patient_id,
        name=med.name,
        trade_name=med.trade_name,
        active_ingredient=med.active_ingredient,
        form=med.form,
        strength=med.strength,
        stock_count=med.stock_count,
        alert_threshold_days=med.alert_threshold_days,
        expiry_date=med.expiry_date,
        is_active=med.is_active,
        schedules=[
            ScheduleOut(
                id=s.id,
                medication_id=s.medication_id,
                time_of_day=s.time_of_day.strftime("%H:%M"),
                dose_amount=s.dose_amount,
                meal_relation=s.meal_relation.value,
                days_mask=s.days_mask,
                instructions_ar=s.instructions_ar,
                is_active=s.is_active,
            )
            for s in schedules
        ],
    )


@router.delete("/medications/{medication_id}")
async def delete_medication(
    medication_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict[str, str]:
    med = await db.get(Medication, medication_id)
    if not med:
        raise AppError(404, "MEDICATION_NOT_FOUND", "الدواء غير موجود")

    await check_patient_access(med.patient_id, current_user, db)
    med.is_active = False
    await db.commit()
    return {"status": "success", "message": "تم حذف الدواء بنجاح"}


@router.get("/medications/{medication_id}/schedules", response_model=list[ScheduleOut])
async def list_schedules(
    medication_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ScheduleOut]:
    med = await db.get(Medication, medication_id)
    if not med:
        raise AppError(404, "MEDICATION_NOT_FOUND", "الدواء غير موجود")

    await check_patient_access(med.patient_id, current_user, db)

    stmt = select(Schedule).where(Schedule.medication_id == medication_id)
    res = await db.execute(stmt)
    schedules = res.scalars().all()

    return [
        ScheduleOut(
            id=s.id,
            medication_id=s.medication_id,
            time_of_day=s.time_of_day.strftime("%H:%M"),
            dose_amount=s.dose_amount,
            meal_relation=s.meal_relation.value,
            days_mask=s.days_mask,
            instructions_ar=s.instructions_ar,
            is_active=s.is_active,
        )
        for s in schedules
    ]


@router.post("/medications/{medication_id}/schedules", response_model=ScheduleOut, status_code=201)
async def create_schedule(
    medication_id: uuid.UUID,
    payload: ScheduleCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ScheduleOut:
    med = await db.get(Medication, medication_id)
    if not med:
        raise AppError(404, "MEDICATION_NOT_FOUND", "الدواء غير موجود")

    await check_patient_access(med.patient_id, current_user, db)

    sched = Schedule(
        medication_id=med.id,
        time_of_day=parse_time_str(payload.time_of_day),
        dose_amount=payload.dose_amount,
        meal_relation=MealRelation(payload.meal_relation),
        days_mask=payload.days_mask,
        instructions_ar=payload.instructions_ar,
        is_active=True,
    )
    db.add(sched)
    await db.commit()
    await db.refresh(sched)

    return ScheduleOut(
        id=sched.id,
        medication_id=sched.medication_id,
        time_of_day=sched.time_of_day.strftime("%H:%M"),
        dose_amount=sched.dose_amount,
        meal_relation=sched.meal_relation.value,
        days_mask=sched.days_mask,
        instructions_ar=sched.instructions_ar,
        is_active=sched.is_active,
    )


@router.get("/patients/{patient_id}/today", response_model=list[TodayDoseOut])
async def get_today_doses(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    now: Annotated[datetime | None, Query()] = None,
) -> list[TodayDoseOut]:
    await check_patient_access(patient_id, current_user, db)

    # Fetch active medications for patient
    med_stmt = select(Medication).where(
        Medication.patient_id == patient_id,
        Medication.is_active == True,  # noqa: E712
    )
    med_res = await db.execute(med_stmt)
    medications = {m.id: m for m in med_res.scalars().all()}

    if not medications:
        return []

    sched_stmt = select(Schedule).where(
        Schedule.medication_id.in_(list(medications.keys())),
        Schedule.is_active == True,  # noqa: E712
    )
    sched_res = await db.execute(sched_stmt)
    schedules = sched_res.scalars().all()

    ref_now = now or datetime.now(UTC)
    if ref_now.tzinfo is None:
        ref_now = ref_now.replace(tzinfo=UTC)

    today_date = ref_now.date()
    start_of_today = datetime.combine(today_date, time.min).replace(tzinfo=UTC)
    end_of_today = datetime.combine(today_date, time.max).replace(tzinfo=UTC)

    # Fetch intake logs for today
    logs_stmt = select(IntakeLog).where(
        IntakeLog.patient_id == patient_id,
        IntakeLog.scheduled_time >= start_of_today,
        IntakeLog.scheduled_time <= end_of_today,
    )
    logs_res = await db.execute(logs_stmt)
    intake_logs = {log.schedule_id: log for log in logs_res.scalars().all()}

    output = []
    # Sort schedules by time
    schedules_sorted = sorted(schedules, key=lambda s: s.time_of_day)

    for s in schedules_sorted:
        med = medications[s.medication_id]
        log = intake_logs.get(s.id)

        output.append(
            TodayDoseOut(
                schedule_id=s.id,
                medication_id=med.id,
                medication_name=med.name,
                time_of_day=s.time_of_day.strftime("%H:%M"),
                dose_amount=s.dose_amount,
                meal_relation=s.meal_relation.value,
                instructions_ar=s.instructions_ar,
                status=log.status.value if log else "pending",
                intake_log_id=log.id if log else None,
                actual_time=log.actual_time if log else None,
            )
        )

    return output
