"""Flat class membership endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.lesson import MembershipResponse
from app.services.lesson_service import LessonService

router = APIRouter()


class MembershipStatusUpdate(BaseModel):
    """Update membership status."""

    status: str


@router.get(
    "",
    response_model=list[MembershipResponse],
    status_code=status.HTTP_200_OK,
    summary="List memberships",
)
async def list_memberships(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
    class_id: str | None = None,
) -> list[MembershipResponse]:
    """List memberships by optional student/class filters."""
    service = LessonService(db)
    return await service.get_memberships(
        current_user,
        student_id=student_id,
        class_id=class_id,
    )


@router.get(
    "/{membership_id}",
    response_model=MembershipResponse,
    status_code=status.HTTP_200_OK,
    summary="Get membership by ID",
)
async def get_membership(
    membership_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> MembershipResponse:
    """Return a membership by ID."""
    service = LessonService(db)
    return await service.get_membership_by_id(membership_id, current_user)


@router.patch(
    "/{membership_id}/status",
    response_model=MembershipResponse,
    status_code=status.HTTP_200_OK,
    summary="Update membership status",
)
async def update_membership_status(
    membership_id: str,
    body: MembershipStatusUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> MembershipResponse:
    """Update only membership status."""
    service = LessonService(db)
    return await service.update_membership_status(membership_id, body.status, current_user)


@router.delete(
    "/{membership_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete membership",
)
async def delete_membership(
    membership_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a membership without requiring class_id context."""
    service = LessonService(db)
    await service.remove_membership_by_id(membership_id, current_user)
