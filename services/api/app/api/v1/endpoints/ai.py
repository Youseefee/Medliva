from typing import Annotated

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.medication import DrugCatalog
from app.models.user import User
from app.schemas.prescription import ExtractedDrugOut, PrescriptionScanResponse
from app.services.ai_service import match_drug_in_catalog, scan_prescription_mock

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/scan-prescription", response_model=PrescriptionScanResponse)
async def scan_prescription(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    file: UploadFile | None = File(None),
) -> PrescriptionScanResponse:
    # 1. Fetch any drug catalog items in DB to augment candidates
    cat_stmt = select(DrugCatalog)
    cat_res = await db.execute(cat_stmt)
    db_drugs = cat_res.scalars().all()

    catalog_dicts = None
    if db_drugs:
        catalog_dicts = [
            {
                "trade_name": d.trade_name,
                "active_ingredient": d.active_ingredient,
                "form": d.form or "قرص",
                "strength": d.strength,
            }
            for d in db_drugs
        ]

    # Run OCR & extraction pipeline
    extracted_items = scan_prescription_mock()

    output_items = []
    for item in extracted_items:
        match, conf = match_drug_in_catalog(item["drug_trade_name"], catalog_dicts)
        output_items.append(
            ExtractedDrugOut(
                drug_trade_name=match["trade_name"] if match else item["drug_trade_name"],
                dosage_mg=item.get("dosage_mg"),
                frequency_per_day=item.get("frequency_per_day", 1),
                meal_relation=item.get("meal_relation", "after_meal"),
                times=item.get("times", []),
                inventory_pills=item.get("inventory_pills", 30),
                confidence_score=conf if conf > 0.5 else item.get("confidence_score", 0.95),
                active_ingredient=(
                    match.get("active_ingredient") if match else item.get("active_ingredient")
                ),
            )
        )

    return PrescriptionScanResponse(medications=output_items, confidence=0.96)
