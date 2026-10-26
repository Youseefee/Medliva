from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class AppError(Exception):
    """Domain error rendered as {"error": {"code", "message"}} (see docs/API_SPEC.md)."""

    def __init__(self, status_code: int, code: str, message: str) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.code = code
        self.message = message


def _error(status_code: int, code: str, message: str, **extra: object) -> JSONResponse:
    body: dict[str, object] = {"code": code, "message": message, **extra}
    return JSONResponse(status_code=status_code, content={"error": body})


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def _app_error(_: Request, exc: AppError) -> JSONResponse:
        return _error(exc.status_code, exc.code, exc.message)

    @app.exception_handler(StarletteHTTPException)
    async def _http_error(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        return _error(exc.status_code, f"HTTP_{exc.status_code}", str(exc.detail))

    @app.exception_handler(RequestValidationError)
    async def _validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
        details = [
            {"field": ".".join(str(p) for p in err["loc"][1:]), "message": err["msg"]}
            for err in exc.errors()
        ]
        return _error(422, "VALIDATION_ERROR", "البيانات المرسلة غير صحيحة", details=details)

    @app.exception_handler(ValueError)
    async def _value_error(_: Request, exc: ValueError) -> JSONResponse:
        # Enum / time conversions in endpoints (VitalType(...),
        # IntakeStatus(...), MealRelation(...), parse_time_str) raise
        # ValueError for invalid client input. That is a client error,
        # not a server crash: report it as 422 like other validation
        # errors instead of leaking a generic 500.
        return _error(422, "VALIDATION_ERROR", "قيمة غير صالحة في البيانات المرسلة")
