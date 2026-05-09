"""Authentication endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.recovery import RecoveryCode
from app.models.user import User
from app.models.user_session import UserSession
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
    from app.core.security import create_access_token, create_refresh_token

    recovery_service = RecoveryService(db)

    # Find all unused recovery codes and check each one
    result = await db.execute(
        select(RecoveryCode).where(not RecoveryCode.is_used)
    )
    recovery_codes = result.scalars().all()

    # Check all recovery codes to find matching user
    for recovery_code in recovery_codes:
        if await recovery_service.verify_code(recovery_code.user_id, body.code):
            # Found valid code, get the user
            user_result = await db.execute(
                select(User).where(User.id == recovery_code.user_id)
            )
            user = user_result.scalar_one_or_none()

            if user is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found",
                )

            # Generate tokens
            access_token = create_access_token(
                data={"sub": user.id, "role": getattr(user.role, "value", None)}
            )
            refresh_token = create_refresh_token(data={"sub": user.id})

            return TokenResponse(
                access_token=access_token,
                refresh_token=refresh_token,
                token_type="bearer",
                user=UserResponse.model_validate(user),
            )

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid recovery code",
    )


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
    # Verify the session belongs to the current user
    result = await db.execute(
        select(UserSession).where(
            (UserSession.id == session_id) & (UserSession.user_id == current_user.id)
        )
    )
    session = result.scalar_one_or_none()

    if session is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    service = SessionService(db)
    success = await service.revoke_session(session_id)

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
    else:
        # Revoke all sessions
        stmt = update(UserSession).where(
            UserSession.user_id == current_user.id
        ).values(is_active=False)

        result = await db.execute(stmt)
        await db.commit()

        return SuccessResponse(
            message=f"Revoked all {result.rowcount} session(s). You have been logged out from all devices."
        )
