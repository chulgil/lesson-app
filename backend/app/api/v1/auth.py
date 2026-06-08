"""Authentication endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Body, Depends, Header, status  # noqa: F401  (Header used in string Annotated below)
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.rate_limit import (  # noqa: F401  사용되는 곳이 데코레이터 `dependencies=` 리스트라 ruff 가 detect 못함.
    auth_dev_login_rate_limit,
    auth_oauth_rate_limit,
    auth_refresh_rate_limit,
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
