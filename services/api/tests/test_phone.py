import pytest

from app.core.errors import AppError
from app.core.phone import normalize_eg_phone


def test_normalize_eg_phone_standard():
    assert normalize_eg_phone("01012345678") == "+201012345678"
    assert normalize_eg_phone("01112345678") == "+201112345678"
    assert normalize_eg_phone("01212345678") == "+201212345678"
    assert normalize_eg_phone("01512345678") == "+201512345678"


def test_normalize_eg_phone_variations():
    assert normalize_eg_phone("+201012345678") == "+201012345678"
    assert normalize_eg_phone("201012345678") == "+201012345678"
    assert normalize_eg_phone("00201012345678") == "+201012345678"
    assert normalize_eg_phone(" 010-1234-5678 ") == "+201012345678"


def test_normalize_eg_phone_invalid():
    with pytest.raises(AppError) as exc_info:
        normalize_eg_phone("01312345678")  # Invalid operator
    assert exc_info.value.code == "INVALID_PHONE"

    with pytest.raises(AppError):
        normalize_eg_phone("12345")

    with pytest.raises(AppError):
        normalize_eg_phone("abc")
