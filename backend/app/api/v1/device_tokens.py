"""Device token endpoints for FCM push notification registration."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.common import SuccessResponse
from app.schemas.device_token import DeviceTokenCreate, DeviceTokenResponse
from app.services.device_token_service import DeviceTokenService

router = APIRouter()


@router.post(
    "",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register device token",
)
async def register_device_token(
    data: DeviceTokenCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> DeviceTokenResponse:
    """Register an FCM device token for push notifications."""
    service = DeviceTokenService(db)
    return await service.register(current_user.id, data)


@router.delete(
    "/{token}",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Unregister device token",
)
async def unregister_device_token(
    token: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SuccessResponse:
    """Remove an FCM device token (e.g., on logout)."""
    service = DeviceTokenService(db)
    await service.unregister(token)
    return SuccessResponse(message="Device token removed")
