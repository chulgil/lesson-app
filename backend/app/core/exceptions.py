from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppException(Exception):
    """Base application exception."""

    def __init__(self, status_code: int, detail: str, code: str = "error"):
        self.status_code = status_code
        self.detail = detail
        self.code = code


class NotFoundException(AppException):
    """Resource not found."""

    def __init__(self, resource: str, resource_id: str = ""):
        detail = f"{resource} not found"
        if resource_id:
            detail = f"{resource} not found: {resource_id}"
        super().__init__(404, detail, "not_found")


class ForbiddenException(AppException):
    """Access forbidden."""

    def __init__(self, message: str = "Forbidden"):
        super().__init__(403, message, "forbidden")


class UnauthorizedException(AppException):
    """Authentication required."""

    def __init__(self, message: str = "Unauthorized"):
        super().__init__(401, message, "unauthorized")


class ValidationException(AppException):
    """Validation error."""

    def __init__(self, message: str = "Validation error"):
        super().__init__(422, message, "validation_error")


class PhoneVerificationRequiredException(AppException):
    """Phone verification required for the requested action.

    Used as the E3 (subscription issuance) hard gate per
    docs/specs/user/phone_verification_policy.md §4.2. Frontend should
    intercept the 409 + ``phone_verification_required`` code and redirect to
    the verification flow.
    """

    def __init__(self, message: str = "Phone verification required"):
        super().__init__(409, message, "phone_verification_required")


def register_exception_handlers(app: FastAPI) -> None:
    """Register custom exception handlers on the FastAPI app."""

    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": {
                    "code": exc.code,
                    "detail": exc.detail,
                }
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        return JSONResponse(
            status_code=500,
            content={
                "error": {
                    "code": "internal_error",
                    "detail": "Internal server error",
                }
            },
        )
