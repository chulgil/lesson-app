"""Teacher announcement endpoints."""

from __future__ import annotations

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.teacher_announcement import (
    TeacherAnnouncementCreate,
    TeacherAnnouncementDayOffsResponse,
    TeacherAnnouncementResponse,
)
from app.services.announcement_service import AnnouncementService

router = APIRouter()


@router.post(
    "",
    response_model=TeacherAnnouncementResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create teacher announcement",
)
async def create_teacher_announcement(
    body: TeacherAnnouncementCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherAnnouncementResponse:
    """Create a 휴강 or general announcement and notify eligible students."""
    service = AnnouncementService(db)
    return await service.create_announcement(body, current_user=current_user)


@router.get(
    "",
    response_model=list[TeacherAnnouncementResponse],
    status_code=status.HTTP_200_OK,
    summary="List teacher announcements",
)
async def list_teacher_announcements(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    teacher_id: str | None = None,
) -> list[TeacherAnnouncementResponse]:
    """List announcements for a teacher, newest first.

    If ``teacher_id`` is omitted, use the authenticated teacher profile.
    """
    service = AnnouncementService(db)
    return await service.list_announcements(teacher_id=teacher_id, current_user=current_user)


@router.get(
    "/day-offs",
    response_model=TeacherAnnouncementDayOffsResponse,
    status_code=status.HTTP_200_OK,
    summary="List teacher day-off dates",
)
async def list_teacher_day_offs(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    from_date: date,
    to_date: date,
    teacher_id: str | None = None,
) -> TeacherAnnouncementDayOffsResponse:
    """List day-off dates for a teacher in [from_date, to_date].

    If ``teacher_id`` is omitted, use the authenticated teacher profile.
    """
    service = AnnouncementService(db)
    return await service.list_day_offs(
        teacher_id=teacher_id,
        from_date=from_date,
        to_date=to_date,
        current_user=current_user,
    )
