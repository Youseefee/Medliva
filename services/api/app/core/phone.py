import re

from app.core.errors import AppError

_EG_MOBILE = re.compile(r"^\+201[0125]\d{8}$")


def normalize_eg_phone(raw: str) -> str:
    """Normalize Egyptian mobile numbers to E.164 (+201XXXXXXXXX).

    Accepts: 01012345678, 201012345678, +201012345678, 00201012345678 (spaces/dashes ignored).
    """
    digits = re.sub(r"[\s\-()]", "", raw)
    if digits.startswith("00"):
        digits = "+" + digits[2:]
    if digits.startswith("0"):
        digits = "+20" + digits[1:]
    elif digits.startswith("20"):
        digits = "+" + digits
    if not _EG_MOBILE.match(digits):
        raise AppError(422, "INVALID_PHONE", "رقم الموبايل غير صحيح")
    return digits
