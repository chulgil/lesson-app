"""Authentication endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Body, Depends, Header, status  # noqa: F401  (Header used in string Annotated below)
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import (  # noqa: F401  get_current_teacher used in Depends()
    get_current_teacher,
    get_current_user,
    get_db,
)
from app.core.rate_limit import (  # noqa: F401  사용되는 곳이 데코레이터 `dependencies=` 리스트라 ruff 가 detect 못함.
    auth_dev_login_rate_limit,
    auth_oauth_rate_limit,
    auth_refresh_rate_limit,
    rate_limit,
)
from app.models.user import User
from app.schemas.auth import (
    DevLoginRequest,
    LogoutRequest,
    OAuthRequest,
    RefreshTokenRequest,
    RefreshTokenResponse,
    TokenResponse,
)
from app.schemas.common import SuccessResponse
from app.schemas.user import RoleUpdate, TermsConsentRequest, UserResponse
from app.services.auth_service import AuthService

# ── Phone OTP schemas (#709) ─────────────────────────────────────────────────


class PhoneOtpRequestBody(BaseModel):
    """SMS OTP 발송 요청."""

    phone_number: str = Field(..., min_length=10, max_length=15, description="수신 전화번호 (숫자만)")


class PhoneOtpVerifyBody(BaseModel):
    """SMS OTP 검증 요청."""

    phone_number: str = Field(..., min_length=10, max_length=15)
    code: str = Field(..., min_length=6, max_length=6, description="6자리 인증번호")


router = APIRouter()


@router.post(
    "/oauth/{provider}",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="OAuth login (Google / Kakao / Apple)",
    dependencies=[auth_oauth_rate_limit],
)
async def oauth_login(
    provider: str,
    body: OAuthRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Exchange an OAuth authorization code or identity token for JWT tokens.

    per-IP rate limit (20/min) — credential-stuffing / token-replay 방어.
    """
    service = AuthService(db)
    return await service.oauth_login(provider, body)


@router.post(
    "/dev-login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Dev login (development env, or beta with X-Internal-API-Key)",
    dependencies=[auth_dev_login_rate_limit],
)
async def dev_login(
    body: DevLoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    internal_api_key: Annotated[str | None, Header(alias="X-Internal-API-Key")] = None,
) -> TokenResponse:
    """Bypass OAuth and log in directly.

    Allowed in `development` unconditionally, and in `beta` if the request carries
    a valid `X-Internal-API-Key` header matching `settings.INTERNAL_API_KEY`.
    Production always rejects.

    per-IP rate limit (10/min) — beta dev-login bruteforce 차단.
    """
    service = AuthService(db)
    return await service.dev_login(body, internal_api_key=internal_api_key)


@router.post(
    "/token/refresh",
    response_model=RefreshTokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Refresh access token",
    dependencies=[auth_refresh_rate_limit],
)
async def refresh_token(
    body: RefreshTokenRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> RefreshTokenResponse:
    """Generate a new access token using a refresh token.

    per-IP rate limit (20/min) — jti / refresh_token bruteforce 추측 차단.
    """
    service = AuthService(db)
    return await service.refresh_token(body.refresh_token)


@router.post(
    "/logout",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Logout (invalidate refresh token)",
)
async def logout(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    body: LogoutRequest | None = None,
) -> SuccessResponse:
    """Invalidate the given refresh token.

    Body is optional — if no refresh_token is provided,
    only the client-side token clearing takes effect.
    """
    refresh_token = body.refresh_token if body and body.refresh_token else None
    if refresh_token:
        service = AuthService(db)
        await service.logout(current_user.id, refresh_token)
    return SuccessResponse(message="Logged out successfully")


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current user info",
)
async def get_me(
    current_user: Annotated[User, Depends(get_current_user)],
) -> UserResponse:
    """Return the currently authenticated user."""
    return UserResponse.model_validate(current_user)


@router.patch(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Update current user role (onboarding)",
)
async def update_my_role(
    body: RoleUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserResponse:
    """Set the role for a newly registered user (role must be null)."""
    service = AuthService(db)
    user = await service.update_new_user_role(current_user, body.role)
    return UserResponse.model_validate(user)


@router.post(
    "/consent",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Record terms agreement and optional marketing consent",
)
async def accept_terms(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    body: Annotated[TermsConsentRequest, Body()] = TermsConsentRequest(),
) -> UserResponse:
    """#430 G1 B2 — 약관 동의 영속 저장.

    호출 자체가 필수 묶음(서비스 이용약관 + 개인정보 처리방침) 동의를
    의미한다. `marketing_consent` 는 정보통신망법 제50조에 따라 별도로
    기록된다.
    """
    service = AuthService(db)
    user = await service.accept_terms(current_user, body.marketing_consent)
    return UserResponse.model_validate(user)


# ── Phone OTP endpoints (#709) ────────────────────────────────────────────────
# 인증된 선생님 계정에만 귀속. 본인 teacher 행에만 코드를 발급/검증한다.

_phone_otp_request_rate_limit = Depends(rate_limit("phone_otp_request", max_requests=10, window_seconds=60))
_phone_otp_verify_rate_limit = Depends(rate_limit("phone_otp_verify", max_requests=20, window_seconds=60))


@router.post(
    "/phone/request-code",
    status_code=status.HTTP_200_OK,
    summary="SMS OTP 발송 요청 (#709)",
    dependencies=[_phone_otp_request_rate_limit],
)
async def phone_request_code(
    body: PhoneOtpRequestBody,
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """6자리 OTP를 생성해 SMS로 발송한다. TTL 3분, 쿨다운 60초, 일일 5회 한도."""
    from app.services.phone_verification_service import PhoneVerificationService

    service = PhoneVerificationService(db)
    return await service.request_code_for_user(current_user.id, body.phone_number)


@router.post(
    "/phone/verify-code",
    status_code=status.HTTP_200_OK,
    summary="SMS OTP 검증 (#709)",
    dependencies=[_phone_otp_verify_rate_limit],
)
async def phone_verify_code(
    body: PhoneOtpVerifyBody,
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """OTP 코드를 검증하고 성공 시 teacher.is_phone_verified=True로 세팅한다."""
    from app.services.phone_verification_service import PhoneVerificationService

    service = PhoneVerificationService(db)
    return await service.verify_code_for_user(current_user.id, body.phone_number, body.code)
