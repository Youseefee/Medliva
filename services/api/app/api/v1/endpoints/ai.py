import re
from typing import Annotated, Any

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.medication import DrugCatalog
from app.models.user import User
from app.schemas.prescription import ExtractedDrugOut, PrescriptionScanResponse
from app.schemas.vitals import VoiceVitalsRequest, VoiceVitalsResponse
from app.services.ai_service import (
    match_drug_in_catalog,
    parse_voice_vitals,
    scan_prescription_text,
)
from app.services.gemini_vision import (
    extract_medications_from_image,
    looks_like_image,
)

router = APIRouter(prefix="/ai", tags=["ai"])


def _parse_dosage_mg(val: Any) -> float | None:
    if val is None:
        return None
    if isinstance(val, (int, float)):
        return float(val)
    if isinstance(val, str):
        digits = re.findall(r"\d+(?:\.\d+)?", val)
        if digits:
            try:
                return float(digits[0])
            except ValueError:
                return None
    return None


def _text_hint(raw_bytes: bytes, filename: str | None) -> str:
    """Best effort text of an uploaded file (OCR layer, file name, ...)."""
    hint = ""
    if raw_bytes:
        try:
            decoded = raw_bytes.decode("utf-8", errors="ignore")
        except (UnicodeDecodeError, AttributeError):
            decoded = ""
        if any(c.isalpha() for c in decoded):
            hint = decoded
    if not hint and filename:
        hint = filename
    return hint


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

    raw_bytes = b""
    if file is not None:
        raw_bytes = await file.read()

    # 2. Optional Gemini Vision OCR for real prescription photos.
    extracted_items: list[dict[str, Any]] = []
    source = "text"

    settings = get_settings()
    if raw_bytes and settings.gemini_api_key and looks_like_image(raw_bytes):
        vision_items = await extract_medications_from_image(raw_bytes, settings.gemini_api_key)
        if vision_items:
            extracted_items = vision_items
            source = "gemini_vision"

    # 3. Fallback: text based extraction (OCR text, file name, manual input).
    if not extracted_items:
        extracted_items = scan_prescription_text(
            _text_hint(raw_bytes, file.filename if file is not None else None)
        )
        source = "text"

    output_items = []
    for item in extracted_items:
        match, conf = match_drug_in_catalog(item.get("drug_trade_name", ""), catalog_dicts)
        default_conf = 0.90 if source == "gemini_vision" else 0.5
        confidence = conf if conf > 0.5 else item.get("confidence_score", default_conf)
        dosage = _parse_dosage_mg(item.get("dosage_mg"))
        output_items.append(
            ExtractedDrugOut(
                drug_trade_name=(match["trade_name"] if match else item.get("drug_trade_name", "")),
                dosage_mg=dosage,
                frequency_per_day=item.get("frequency_per_day", 1),
                meal_relation=item.get("meal_relation", "after_meal"),
                times=item.get("times", []),
                inventory_pills=item.get("inventory_pills", 30),
                confidence_score=confidence,
                active_ingredient=(
                    match.get("active_ingredient") if match else item.get("active_ingredient")
                ),
            )
        )

    overall_confidence = 0.0
    if output_items:
        overall_confidence = sum(item.confidence_score for item in output_items) / len(output_items)

    return PrescriptionScanResponse(
        medications=output_items,
        confidence=round(overall_confidence, 2),
        source=source,
    )


@router.post("/parse-voice-vitals", response_model=VoiceVitalsResponse)
async def parse_voice_vitals_endpoint(
    payload: VoiceVitalsRequest,
    current_user: Annotated[User, Depends(get_current_user)],
) -> VoiceVitalsResponse:
    result = parse_voice_vitals(payload.transcript)
    return VoiceVitalsResponse(
        transcript=result["transcript"],
        type=result["type"],
        value_primary=result["value_primary"],
        value_secondary=result["value_secondary"],
        meal_context=result["meal_context"],
        band=result["band"],
        message_ar=result["message_ar"],
    )
