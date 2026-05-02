"""Lesson schedule change endpoints — request/approve/reject schedule changes."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.schedule_ext import (
    LessonScheduleChangeCreate,
    LessonScheduleChangeRespondRequest,
    LessonScheduleChangeResponse,
)
from app.services.schedule_ext_service import ScheduleExtService

router = APIRouter()


@router.post(
    "",
    response_model=LessonScheduleChangeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create schedule change request",
)
async def create_schedule_change(
    body: LessonScheduleChangeCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonScheduleChangeResponse:
    """Create a new lesson schedule change request."""
    service = ScheduleExtService(db)
    return await service.create_schedule_change(
        data=body.model_dump(), teacher_id=current_user.id
    )


@router.get(
    "/pending",
    response_model=PaginatedResponse[LessonScheduleChangeResponse],
    status_code=status.HTTP_200_OK,
    summary="List pending schedule changes",
)
async def get_pending_changes(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[LessonScheduleChangeResponse]:
    """List pending schedule change requests for the current teacher."""
    service = ScheduleExtService(db)
    return await service.get_pending_changes(
        teacher_id=current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.patch(
    "/{change_id}/respond",
    response_model=LessonScheduleChangeResponse,
    status_code=status.HTTP_200_OK,
    summary="Respond to schedule change",
)
async def respond_to_schedule_change(
    change_id: str,
    body: LessonScheduleChangeRespondRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonScheduleChangeResponse:
    """Approve, reject, or propose alternative for a schedule change request."""
    service = ScheduleExtService(db)
    return await service.respond_to_schedule_change(
        change_id=change_id,
        action=body.action,
        response_message=body.response_message,
    )
