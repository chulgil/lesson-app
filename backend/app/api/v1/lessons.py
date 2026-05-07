"""Lesson and lesson-class endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.lesson import (
    BulkCancelLessonRequest,
    BulkCancelLessonResponse,
    LessonClassCreate,
    LessonClassResponse,
    LessonClassUpdate,
    LessonCreate,
    LessonFeedbackUpdate,
    LessonResponse,
    LessonStatusUpdate,
    LessonUpdate,
    MembershipCreate,
    MembershipResponse,
    MembershipUpdate,
)
from app.services.bulk_teacher_action_service import BulkTeacherActionService
from app.services.lesson_service import LessonService

router = APIRouter()


# ---------------------------------------------------------------------------
# Lesson CRUD
# ---------------------------------------------------------------------------


@router.get(
    "",
    response_model=PaginatedResponse[LessonResponse],
    status_code=status.HTTP_200_OK,
    summary="List lessons",
)
async def list_lessons(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    student_id: str | None = None,
    date: str | None = None,
    date_from: str | None = None,
    date_to: str | None = None,
    lesson_status: Annotated[str | None, Query(alias="status")] = None,
) -> PaginatedResponse[LessonResponse]:
    """List lessons with optional filters."""
    service = LessonService(db)
    return await service.get_all(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        student_id=student_id,
        date=date,
        date_from=date_from,
        date_to=date_to,
        status=lesson_status,
    )


@router.post(
    "",
    response_model=LessonResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a lesson (teacher only)",
)
async def create_lesson(
    body: LessonCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonResponse:
    """Create a new lesson."""
    service = LessonService(db)
    return await service.create(body, current_user)


@router.get(
    "/upcoming",
    response_model=list[LessonResponse],
    status_code=status.HTTP_200_OK,
    summary="Upcoming lessons",
)
async def upcoming_lessons(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    limit: int = 10,
) -> list[LessonResponse]:
    """Return the next N upcoming lessons for the current user."""
    service = LessonService(db)
    return await service.get_upcoming(current_user, limit=limit)


@router.get(
    "/recent",
    response_model=list[LessonResponse],
    status_code=status.HTTP_200_OK,
    summary="Recent completed lessons",
)
async def recent_lessons(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    limit: int = 10,
) -> list[LessonResponse]:
    """Return the last N completed lessons for the current user."""
    service = LessonService(db)
    return await service.get_recent(current_user, limit=limit)


@router.post(
    "/bulk-cancel",
    response_model=BulkCancelLessonResponse,
    status_code=status.HTTP_200_OK,
    summary="Bulk cancel teacher lessons",
)
async def bulk_cancel_lessons(
    body: BulkCancelLessonRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> BulkCancelLessonResponse:
    """Cancel selected students' lessons on a date and notify them."""
    service = BulkTeacherActionService(db)
    return await service.bulk_cancel_lessons(
        teacher_id=body.teacher_id,
        student_ids=body.student_ids,
        target_date=body.target_date,
        reason=body.reason,
        notification_title=body.notification_title,
        current_user=current_user,
    )


@router.get(
    "/{lesson_id}",
    response_model=LessonResponse,
    status_code=status.HTTP_200_OK,
    summary="Get lesson detail",
)
async def get_lesson(
    lesson_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonResponse:
    """Return a single lesson by ID."""
    service = LessonService(db)
    return await service.get_by_id(lesson_id, current_user)


@router.put(
    "/{lesson_id}",
    response_model=LessonResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a lesson (teacher only)",
)
async def update_lesson(
    lesson_id: str,
    body: LessonUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonResponse:
    """Update lesson fields."""
    service = LessonService(db)
    return await service.update(lesson_id, body, current_user)


@router.delete(
    "/{lesson_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a lesson",
)
async def delete_lesson(
    lesson_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Delete a lesson."""
    service = LessonService(db)
    await service.delete(lesson_id, current_user)


@router.patch(
    "/{lesson_id}/status",
    response_model=LessonResponse,
    status_code=status.HTTP_200_OK,
    summary="Change lesson status",
)
async def update_lesson_status(
    lesson_id: str,
    body: LessonStatusUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonResponse:
    """Change the status of a lesson (e.g. completed, cancelled)."""
    service = LessonService(db)
    return await service.update_status(lesson_id, body.status, current_user)


@router.put(
    "/{lesson_id}/feedback",
    response_model=LessonResponse,
    status_code=status.HTTP_200_OK,
    summary="Write lesson feedback",
)
async def update_lesson_feedback(
    lesson_id: str,
    body: LessonFeedbackUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonResponse:
    """Write or update feedback on a lesson."""
    service = LessonService(db)
    return await service.update_feedback(lesson_id, body, current_user)


# ---------------------------------------------------------------------------
# Lesson classes
# ---------------------------------------------------------------------------


@router.get(
    "-classes",
    response_model=PaginatedResponse[LessonClassResponse],
    status_code=status.HTTP_200_OK,
    summary="List lesson classes",
)
async def list_lesson_classes(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[LessonClassResponse]:
    """List all lesson classes for the current teacher."""
    service = LessonService(db)
    return await service.get_all_classes(
        current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.post(
    "-classes",
    response_model=LessonClassResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a lesson class",
)
async def create_lesson_class(
    body: LessonClassCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonClassResponse:
    """Create a new lesson class (academy / group)."""
    service = LessonService(db)
    return await service.create_class(body, current_user)


class ReorderRequest(BaseModel):
    """List of ordered class IDs."""

    ordered_ids: list[str]


@router.put(
    "-classes/reorder",
    status_code=status.HTTP_200_OK,
    summary="Reorder lesson classes",
)
async def reorder_lesson_classes(
    body: ReorderRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> dict:
    """Set the display order of lesson classes."""
    service = LessonService(db)
    await service.reorder_classes(body.ordered_ids, current_user)
    return {"message": "Reorder successful"}


@router.get(
    "-classes/{class_id}",
    response_model=LessonClassResponse,
    status_code=status.HTTP_200_OK,
    summary="Get lesson class detail",
)
async def get_lesson_class(
    class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonClassResponse:
    """Return a single lesson class."""
    service = LessonService(db)
    return await service.get_class_by_id(class_id, current_user)


@router.put(
    "-classes/{class_id}",
    response_model=LessonClassResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a lesson class",
)
async def update_lesson_class(
    class_id: str,
    body: LessonClassUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonClassResponse:
    """Update lesson class fields."""
    service = LessonService(db)
    return await service.update_class(class_id, body, current_user)


@router.delete(
    "-classes/{class_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Archive a lesson class",
)
async def delete_lesson_class(
    class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Archive (soft-delete) a lesson class."""
    service = LessonService(db)
    await service.delete_class(class_id, current_user)


@router.patch(
    "-classes/{class_id}/restore",
    response_model=LessonClassResponse,
    status_code=status.HTTP_200_OK,
    summary="Restore an archived lesson class",
)
async def restore_lesson_class(
    class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonClassResponse:
    """Restore a previously archived lesson class."""
    service = LessonService(db)
    return await service.restore_class(class_id, current_user)


# ---------------------------------------------------------------------------
# Memberships
# ---------------------------------------------------------------------------


@router.get(
    "-classes/{class_id}/memberships",
    response_model=list[MembershipResponse],
    status_code=status.HTTP_200_OK,
    summary="List memberships for a class",
)
async def list_memberships(
    class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> list[MembershipResponse]:
    """List all student memberships in a lesson class."""
    service = LessonService(db)
    return await service.get_memberships_by_class(class_id, current_user)


@router.get(
    "-classes/{class_id}/memberships/{membership_id}",
    response_model=MembershipResponse,
    status_code=status.HTTP_200_OK,
    summary="Get membership detail",
)
async def get_membership(
    class_id: str,
    membership_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> MembershipResponse:
    """Return a single membership by ID."""
    service = LessonService(db)
    return await service.get_membership_by_id(membership_id, current_user)


@router.post(
    "-classes/{class_id}/memberships",
    response_model=MembershipResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add student to class",
)
async def add_membership(
    class_id: str,
    body: MembershipCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> MembershipResponse:
    """Add a student membership to a lesson class."""
    service = LessonService(db)
    return await service.add_membership(class_id, body, current_user)


@router.put(
    "-classes/{class_id}/memberships/{membership_id}",
    response_model=MembershipResponse,
    status_code=status.HTTP_200_OK,
    summary="Update membership",
)
async def update_membership(
    class_id: str,
    membership_id: str,
    body: MembershipUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> MembershipResponse:
    """Update a class membership."""
    service = LessonService(db)
    return await service.update_membership(class_id, membership_id, body, current_user)


@router.delete(
    "-classes/{class_id}/memberships/{membership_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove student from class",
)
async def remove_membership(
    class_id: str,
    membership_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Remove a student membership from a lesson class."""
    service = LessonService(db)
    await service.remove_membership(class_id, membership_id, current_user)
