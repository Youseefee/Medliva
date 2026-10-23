from pydantic import BaseModel


class ExtractedDrugOut(BaseModel):
    drug_trade_name: str
    dosage_mg: float | None = None
    frequency_per_day: int = 1
    meal_relation: str = "after_meal"
    times: list[str] = []
    inventory_pills: int = 30
    confidence_score: float = 0.95
    active_ingredient: str | None = None


class PrescriptionScanResponse(BaseModel):
    medications: list[ExtractedDrugOut]
    confidence: float = 0.95
