"""Parent endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_parent, get_db
from app.models.user import User
from app.schemas.lesson import LessonResponse
from app.schemas.parent import ParentChildResponse, ParentConnectChildRequest, ParentResponse, ParentUpdate
from app.schemas.practice import PracticeStatsResponse
from app.services.parent_service import ParentService

router = APIRouter()


@router.get(
    "/me",
    response_model=ParentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get parent profile",
)
async def get_parent_profile(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ParentResponse:
    """Return the parent profile for the current user."""
    service = ParentService(db)
    return await service.get_profile(current_user)


@router.put(
    "/me",
    response_model=ParentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update parent profile",
)
async def update_parent_profile(
    body: ParentUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ParentResponse:
    """Update the parent profile."""
    service = ParentService(db)
    return await service.update_profile(body, current_user)


@router.get(
    "/me/children",
    response_model=list[ParentChildResponse],
    status_code=status.HTTP_200_OK,
    summary="List children",
)
async def list_children(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> list[ParentChildResponse]:
    """Return a list of the parent's linked children."""
    service = ParentService(db)
    return await service.get_children(current_user)


@router.post(
    "/me/children",
    response_model=ParentChildResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Link child via invite code",
)
async def connect_child(
    body: ParentConnectChildRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ParentChildResponse:
    """Link a child to the parent using an invite code."""
    service = ParentService(db)
    return await service.connect_child(body.invite_code, current_user)


@router.get(
    "/me/children/{student_id}/lessons",
    response_model=list[LessonResponse],
    status_code=status.HTTP_200_OK,
    summary="Child's lessons",
)
async def get_child_lessons(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
    date_from: str | None = None,
    date_to: str | None = None,
) -> list[LessonResponse]:
    """Return lessons for a linked child."""
    service = ParentService(db)
    return await service.get_child_lessons(
        student_id,
        current_user,
        date_from=date_from,
        date_to=date_to,
    )


@router.get(
    "/me/children/{student_id}/practice",
    response_model=PracticeStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Child's practice stats",
)
async def get_child_practice(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
    year: int | None = None,
    month: int | None = None,
) -> PracticeStatsResponse:
    """Return practice statistics for a linked child."""
    service = ParentService(db)
    return await service.get_child_practice(
        student_id,
        current_user,
        year=year,
        month=month,
    )
