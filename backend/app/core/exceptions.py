from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppException(Exception):
    """Base application exception."""

    def __init__(self, status_code: int, detail: str, code: str = "error"):
        self.status_code = status_code
        self.detail = detail
        self.code = code


class PhoneVerificationRequiredException(AppException):
    """Phone verification required for the requested action.

    Used as the E3 (subscription issuance) hard gate per
    docs/specs/user/phone_verification_policy.md §4.2. Frontend should
    intercept the 409 + ``phone_verification_required`` code and redirect to
    the verification flow.
    """

    def __init__(self, message: str = "Phone verification required"):
        super().__init__(409, message, "phone_verification_required")


class LastWriteWinsConflictException(AppException):
    """Last-Write-Wins conflict — the resource is newer than the client's base.

    Raised on an ``If-Unmodified-Since`` precondition failure (D4, #1119): the
    resource was modified after the timestamp the client edited from, so the
    write is rejected instead of clobbering the newer server state. The client
    (sync queue) marks the entry failed and surfaces a rejection SnackBar.
    Spec: docs/specs/sync/README.md §7.
    """

    def __init__(self, message: str = "서버의 최신 변경과 충돌해 반영되지 않았습니다"):
        super().__init__(412, message, "CONFLICT_LWW_REJECTED")


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
