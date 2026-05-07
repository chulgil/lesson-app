"""Notification endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.schemas.notification import (
    NotificationPreferenceResponse,
    NotificationPreferenceUpdate,
    NotificationResponse,
    UnreadCountResponse,
)
from app.services.notification_service import NotificationService

router = APIRouter()


@router.get(
    "/preferences",
    response_model=NotificationPreferenceResponse,
    status_code=status.HTTP_200_OK,
    summary="Get notification preferences",
)
async def get_preferences(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> NotificationPreferenceResponse:
    """Return current user's notification preferences."""
    service = NotificationService(db)
    return await service.get_preferences(current_user)


@router.patch(
    "/preferences",
    response_model=NotificationPreferenceResponse,
    status_code=status.HTTP_200_OK,
    summary="Update notification preferences",
)
async def update_preferences(
    body: NotificationPreferenceUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> NotificationPreferenceResponse:
    """Patch current user's notification preferences."""
    service = NotificationService(db)
    return await service.update_preferences(current_user, body.settings)


@router.get(
    "",
    response_model=PaginatedResponse[NotificationResponse],
    status_code=status.HTTP_200_OK,
    summary="List notifications",
)
async def list_notifications(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    is_read: bool | None = None,
    notification_type: Annotated[str | None, Query(alias="type")] = None,
) -> PaginatedResponse[NotificationResponse]:
    """List notifications for the current user."""
    service = NotificationService(db)
    return await service.get_all(
        user_id=current_user.id,
        user_role=current_user.role,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        is_read=is_read,
        notification_type=notification_type,
    )


@router.patch(
    "/{notification_id}/read",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark notification as read",
)
async def mark_read(
    notification_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SuccessResponse:
    """Mark a single notification as read."""
    service = NotificationService(db)
    await service.mark_read(notification_id, current_user.id)
    return SuccessResponse(message="Notification marked as read")


@router.patch(
    "/read-all",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark all notifications as read",
)
async def mark_all_read(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SuccessResponse:
    """Mark all notifications for the current user as read."""
    service = NotificationService(db)
    await service.mark_all_read(current_user.id, current_user.role)
    return SuccessResponse(message="All notifications marked as read")


@router.get(
    "/unread-count",
    response_model=UnreadCountResponse,
    status_code=status.HTTP_200_OK,
    summary="Get unread notification count",
)
async def unread_count(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> UnreadCountResponse:
    """Return the number of unread notifications."""
    service = NotificationService(db)
    count = await service.get_unread_count(current_user.id, current_user.role)
    return UnreadCountResponse(count=count)
