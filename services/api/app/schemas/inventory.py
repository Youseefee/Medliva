from typing import Any

from pydantic import BaseModel


class InventoryForecastOut(BaseModel):
    medications: list[dict[str, Any]]
    low_stock_count: int
    expired_count: int


class RefillOrderItem(BaseModel):
    name: str
    quantity: int = 1


class RefillOrderRequest(BaseModel):
    pharmacy_phone: str = "01000000000"
    items: list[RefillOrderItem]
    note: str | None = None


class RefillOrderOut(BaseModel):
    message_text: str
    whatsapp_url: str
