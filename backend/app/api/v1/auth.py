"""Authentication endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
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
from app.schemas.recovery import (
    RecoveryCodesGenerateRequest,
    RecoveryCodesGenerateResponse,
    RecoveryCodesVerifyRequest,
    UserSessionListResponse,
    UserSessionResponse,
)
from app.schemas.user import RoleUpdate, UserResponse
from app.services.auth_service import AuthService
from app.services.recovery_service import RecoveryService
from app.services.session_service import SessionService

router = APIRouter()


@router.post(
    "/oauth/{provider}",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="OAuth login (Google / Kakao / Apple)",
)
async def oauth_login(
    provider: str,
    body: OAuthRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Exchange an OAuth authorization code or identity token for JWT tokens."""
    service = AuthService(db)
    return await service.oauth_login(provider, body)


@router.post(
    "/dev-login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Dev login (development environment only)",
)
async def dev_login(
    body: DevLoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Bypass OAuth and log in directly — only works when ENVIRONMENT=development."""
    service = AuthService(db)
    return await service.dev_login(body)


@router.post(
    "/token/refresh",
    response_model=RefreshTokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Refresh access token",
)
async def refresh_token(
    body: RefreshTokenRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> RefreshTokenResponse:
    """Generate a new access token using a refresh token."""
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
    "/recovery-codes/generate",
    response_model=RecoveryCodesGenerateResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate recovery codes",
)
async def generate_recovery_codes(
    body: RecoveryCodesGenerateRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> RecoveryCodesGenerateResponse:
    """Generate 10 new recovery codes for account recovery.

    Returns plaintext codes that should be saved by the user.
    Previous unused codes will be invalidated.
    """
    service = RecoveryService(db)
    codes = await service.generate_codes(current_user.id)
    return RecoveryCodesGenerateResponse(codes=codes)


@router.post(
    "/recovery-codes/verify",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify recovery code and get JWT tokens",
)
async def verify_recovery_code(
    body: RecoveryCodesVerifyRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Verify a recovery code and return JWT tokens.

    Used when user has lost OAuth access but has a recovery code.
    """
    recovery_service = RecoveryService(db)
    return await recovery_service.verify_any_code(body.code)


@router.get(
    "/sessions",
    response_model=UserSessionListResponse,
    status_code=status.HTTP_200_OK,
    summary="List active sessions",
)
async def list_sessions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserSessionListResponse:
    """Get list of all active sessions for current user."""
    service = SessionService(db)
    sessions = await service.list_sessions(current_user.id)
    return UserSessionListResponse(
        sessions=[UserSessionResponse.model_validate(s) for s in sessions],
        count=len(sessions),
    )


@router.delete(
    "/sessions/{session_id}",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke specific session",
)
async def revoke_session(
    session_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SuccessResponse:
    """Revoke a specific session by ID.

    The session must belong to the current user.
    """
    service = SessionService(db)
    success = await service.revoke_user_session(current_user.id, session_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    return SuccessResponse(message="Session revoked successfully")


@router.delete(
    "/sessions",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke all sessions except current",
)
async def revoke_all_sessions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_session_id: str | None = None,
) -> SuccessResponse:
    """Revoke all sessions except the current one.

    If current_session_id is not provided, all sessions will be revoked.
    """
    service = SessionService(db)

    if current_session_id:
        revoked_count = await service.revoke_all_except(current_user.id, current_session_id)
        return SuccessResponse(
            message=f"Revoked {revoked_count} session(s). Current session remains active."
        )
    revoked_count = await service.revoke_all(current_user.id)
    return SuccessResponse(
        message=f"Revoked all {revoked_count} session(s). You have been logged out from all devices."
    )
