import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.medication import DrugCatalog, IntakeLog, Medication, Schedule
from app.models.vitals import VitalsLog
from app.services.ai_service import COMMON_EGYPTIAN_DRUGS
from scripts.seed_demo_data import DEMO_DRUGS, seed_demo_data


@pytest.mark.asyncio
async def test_seed_demo_data_populates_the_catalog_and_a_patient(
    db_session: AsyncSession, user_factory
):
    patient = await user_factory(phone="+201099900011", name="مريض العرض")
    patient_id = patient.id

    summary = await seed_demo_data(db_session, patient_id=patient_id, days=7)

    assert summary["drug_catalog_created"] == len(COMMON_EGYPTIAN_DRUGS)
    assert summary["medications"] == len(DEMO_DRUGS)
    # Concor (1 time) + Glucophage (2) + Augmentin (2)
    assert summary["schedules"] == 5
    assert summary["vitals_created"] == 14  # 7 days x (bp + glucose)
    assert summary["intake_logs_created"] == 35  # 7 days x 5 schedules

    catalog_count = await db_session.scalar(select(func.count()).select_from(DrugCatalog))
    assert catalog_count == len(COMMON_EGYPTIAN_DRUGS)

    medications = (
        (await db_session.execute(select(Medication).where(Medication.patient_id == patient_id)))
        .scalars()
        .all()
    )
    assert {m.name for m in medications} == set(DEMO_DRUGS)
    assert all(m.stock_count > 0 for m in medications)

    schedules = (
        (
            await db_session.execute(
                select(Schedule).join(Medication).where(Medication.patient_id == patient_id)
            )
        )
        .scalars()
        .all()
    )
    assert len(schedules) == 5

    vitals = (
        (await db_session.execute(select(VitalsLog).where(VitalsLog.patient_id == patient_id)))
        .scalars()
        .all()
    )
    assert len(vitals) == 14
    assert {v.type for v in vitals} == {"bp", "glucose"}

    logs = (
        (await db_session.execute(select(IntakeLog).where(IntakeLog.patient_id == patient_id)))
        .scalars()
        .all()
    )
    assert len(logs) == 35
    assert {log.status for log in logs} <= {"taken", "skipped", "missed"}


@pytest.mark.asyncio
async def test_seed_demo_data_is_idempotent(db_session: AsyncSession, user_factory):
    patient = await user_factory(phone="+201099900022", name="مريض العرض 2")
    patient_id = patient.id

    await seed_demo_data(db_session, patient_id=patient_id, days=7)
    second = await seed_demo_data(db_session, patient_id=patient_id, days=7)

    assert second["drug_catalog_created"] == 0
    assert second["vitals_created"] == 0
    assert second["intake_logs_created"] == 0

    catalog_count = await db_session.scalar(select(func.count()).select_from(DrugCatalog))
    assert catalog_count == len(COMMON_EGYPTIAN_DRUGS)

    medications = (
        (await db_session.execute(select(Medication).where(Medication.patient_id == patient_id)))
        .scalars()
        .all()
    )
    assert len(medications) == len(DEMO_DRUGS)

    logs = (
        (await db_session.execute(select(IntakeLog).where(IntakeLog.patient_id == patient_id)))
        .scalars()
        .all()
    )
    assert len(logs) == 35


@pytest.mark.asyncio
async def test_seed_demo_data_without_patient_only_seeds_the_catalog(
    db_session: AsyncSession,
):
    summary = await seed_demo_data(db_session)

    assert summary["drug_catalog_created"] == len(COMMON_EGYPTIAN_DRUGS)
    assert "medications" not in summary

    medications = (await db_session.execute(select(func.count()).select_from(Medication))).scalar()
    assert medications == 0
