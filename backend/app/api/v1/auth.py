"""Authentication endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
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
from app.schemas.user import RoleUpdate, UserResponse
from app.services.auth_service import AuthService

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
    body: LogoutRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SuccessResponse:
    """Invalidate the given refresh token."""
    service = AuthService(db)
    await service.logout(current_user.id, body.refresh_token)
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
    from app.models.user import UserRole

    if current_user.role is not None:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Role is already set. Contact support to change it.",
        )

    role_enum = UserRole(body.role)
    current_user.role = role_enum
    db.add(current_user)

    # Auto-create role-specific profile
    service = AuthService(db)
    await service._ensure_role_profile(current_user, role_enum)

    await db.flush()
    await db.commit()
    await db.refresh(current_user)
    return UserResponse.model_validate(current_user)
