"""Schedule confirmation card endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.schedule_confirmation import (
    ScheduleConfirmationCardConfirm,
    ScheduleConfirmationCardCreate,
    ScheduleConfirmationCardDismissAll,
    ScheduleConfirmationCardDismissAllResponse,
    ScheduleConfirmationCardResponse,
    ScheduleConfirmationCardStatusUpdate,
)
from app.services.schedule_confirmation_service import ScheduleConfirmationService

router = APIRouter()


@router.post(
    "",
    response_model=ScheduleConfirmationCardResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create schedule confirmation card",
)
async def create_confirmation_card(
    body: ScheduleConfirmationCardCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleConfirmationCardResponse:
    """Teacher creates a schedule confirmation card for a student."""
    service = ScheduleConfirmationService(db)
    return await service.create_card(body, current_user)


@router.get(
    "",
    response_model=list[ScheduleConfirmationCardResponse],
    status_code=status.HTTP_200_OK,
    summary="List schedule confirmation cards",
)
async def list_confirmation_cards(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
    card_status: Annotated[str | None, Query(alias="status")] = None,
) -> list[ScheduleConfirmationCardResponse]:
    """List confirmation cards visible to the current user."""
    service = ScheduleConfirmationService(db)
    return await service.get_cards(
        current_user, student_id=student_id, card_status=card_status
    )


@router.get(
    "/by-subscription/{subscription_id}",
    response_model=ScheduleConfirmationCardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get schedule confirmation card by subscription ID",
)
async def get_confirmation_card_by_subscription(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleConfirmationCardResponse:
    """Return a single confirmation card by subscription ID."""
    service = ScheduleConfirmationService(db)
    return await service.get_card_by_subscription_id(subscription_id, current_user)


@router.post(
    "/dismiss-all",
    response_model=ScheduleConfirmationCardDismissAllResponse,
    status_code=status.HTTP_200_OK,
    summary="Dismiss all pending schedule confirmation cards",
)
async def dismiss_all_confirmation_cards(
    body: ScheduleConfirmationCardDismissAll,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleConfirmationCardDismissAllResponse:
    """Dismiss all pending confirmation cards for a visible student."""
    service = ScheduleConfirmationService(db)
    return await service.dismiss_all_pending(body, current_user)


@router.get(
    "/{card_id}",
    response_model=ScheduleConfirmationCardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get schedule confirmation card",
)
async def get_confirmation_card(
    card_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleConfirmationCardResponse:
    """Return a single confirmation card by ID."""
    service = ScheduleConfirmationService(db)
    return await service.get_card_by_id(card_id, current_user)


@router.patch(
    "/{card_id}/status",
    response_model=ScheduleConfirmationCardResponse,
    status_code=status.HTTP_200_OK,
    summary="Update schedule confirmation card status",
)
async def update_confirmation_card_status(
    card_id: str,
    body: ScheduleConfirmationCardStatusUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleConfirmationCardResponse:
    """Update confirmation card status from Flutter card actions."""
    service = ScheduleConfirmationService(db)
    return await service.update_card_status(card_id, body, current_user)


@router.patch(
    "/{card_id}/confirm",
    response_model=ScheduleConfirmationCardResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirm or reject a schedule confirmation card",
)
async def confirm_card(
    card_id: str,
    body: ScheduleConfirmationCardConfirm,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleConfirmationCardResponse:
    """Student confirms or rejects a schedule confirmation card."""
    service = ScheduleConfirmationService(db)
    return await service.confirm_card(card_id, body, current_user)
