"""Flat subscription settings endpoints used by frontend repositories."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db
from app.models.user import User
from app.schemas.settings import SubscriptionSettingsResponse, SubscriptionSettingsUpdate
from app.services.settings_service import SettingsService

router = APIRouter()


@router.get(
    "/teacher/{teacher_id}",
    response_model=SubscriptionSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get subscription settings by teacher",
)
async def get_by_teacher(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SubscriptionSettingsResponse:
    service = SettingsService(db)
    result: SubscriptionSettingsResponse = await service.get_subscription_settings_by_teacher(teacher_id, current_user)
    return result


@router.get(
    "/organization/{organization_id}",
    response_model=SubscriptionSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get subscription settings by organization",
)
async def get_by_organization(
    organization_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SubscriptionSettingsResponse:
    service = SettingsService(db)
    result: SubscriptionSettingsResponse = await service.get_subscription_settings_by_organization(
        organization_id, current_user
    )
    return result


@router.post(
    "",
    response_model=SubscriptionSettingsResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create subscription settings",
)
async def create_subscription_settings(
    body: SubscriptionSettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionSettingsResponse:
    service = SettingsService(db)
    result: SubscriptionSettingsResponse = await service.create_subscription_settings(
        body.model_dump(exclude_none=True),
        current_user=current_user,
    )
    return result


@router.put(
    "/{settings_id}",
    response_model=SubscriptionSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Update subscription settings",
)
async def update_subscription_settings(
    settings_id: str,
    body: SubscriptionSettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionSettingsResponse:
    service = SettingsService(db)
    result: SubscriptionSettingsResponse = await service.update_subscription_settings_by_id(
        settings_id,
        body.model_dump(exclude_none=True),
        current_user=current_user,
    )
    return result
