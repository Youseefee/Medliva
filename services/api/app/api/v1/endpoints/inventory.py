import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import check_patient_access, get_current_user
from app.db.session import get_db
from app.models.medication import Medication, Schedule
from app.models.user import User
from app.schemas.inventory import (
    InventoryForecastOut,
    RefillOrderOut,
    RefillOrderRequest,
)
from app.services.inventory import (
    calculate_medication_forecast,
    generate_refill_order_text,
    generate_whatsapp_refill_url,
)

router = APIRouter(tags=["inventory"])


@router.get("/patients/{patient_id}/inventory/forecast", response_model=InventoryForecastOut)
async def get_inventory_forecast(
    patient_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> InventoryForecastOut:
    await check_patient_access(patient_id, current_user, db)

    # Fetch active medications
    med_stmt = select(Medication).where(
        Medication.patient_id == patient_id,
        Medication.is_active == True,  # noqa: E712
    )
    med_res = await db.execute(med_stmt)
    medications = med_res.scalars().all()

    med_forecasts = []
    low_stock_count = 0
    expired_count = 0

    for med in medications:
        sched_stmt = select(Schedule).where(Schedule.medication_id == med.id)
        sched_res = await db.execute(sched_stmt)
        schedules = sched_res.scalars().all()

        fc = calculate_medication_forecast(med, schedules)
        med_forecasts.append(fc)

        if fc["is_low_stock"]:
            low_stock_count += 1
        if fc["is_expired"]:
            expired_count += 1

    return InventoryForecastOut(
        medications=med_forecasts,
        low_stock_count=low_stock_count,
        expired_count=expired_count,
    )


@router.post("/patients/{patient_id}/inventory/refill-order", response_model=RefillOrderOut)
async def create_refill_order(
    patient_id: uuid.UUID,
    payload: RefillOrderRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> RefillOrderOut:
    await check_patient_access(patient_id, current_user, db)

    patient = await db.get(User, patient_id)
    patient_name = patient.name if patient and patient.name else "المريض"
    patient_address = patient.address if patient else None

    items_dicts = [{"name": it.name, "quantity": it.quantity} for it in payload.items]
    order_text = generate_refill_order_text(
        patient_name=patient_name,
        items=items_dicts,
        address=patient_address,
        note=payload.note,
    )
    whatsapp_url = generate_whatsapp_refill_url(
        pharmacy_phone=payload.pharmacy_phone,
        message_text=order_text,
    )

    return RefillOrderOut(message_text=order_text, whatsapp_url=whatsapp_url)
