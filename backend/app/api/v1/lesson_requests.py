"""Lesson request endpoints — student requests to reconnect with teacher."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.schemas.lesson_request import (
    LessonRequestCreate,
    LessonRequestResponse,
    LessonRequestStatusUpdate,
    LessonRequestUpdate,
)
from app.services.lesson_request_service import LessonRequestService

router = APIRouter()


@router.get(
    "",
    response_model=PaginatedResponse[LessonRequestResponse],
    status_code=status.HTTP_200_OK,
    summary="List lesson requests",
)
async def list_lesson_requests(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    teacher_id: str | None = None,
    student_id: str | None = None,
    request_status: Annotated[str | None, Query(alias="status")] = None,
) -> PaginatedResponse[LessonRequestResponse]:
    """List lesson requests filtered by teacher, student, or status."""
    service = LessonRequestService(db)
    return await service.get_all(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        teacher_id=teacher_id,
        student_id=student_id,
        request_status=request_status,
    )


@router.post(
    "",
    response_model=LessonRequestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create lesson request",
)
async def create_lesson_request(
    body: LessonRequestCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonRequestResponse:
    """Create a new lesson request from student to teacher."""
    service = LessonRequestService(db)
    return await service.create(body, current_user)


@router.get(
    "/{request_id}",
    response_model=LessonRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Get lesson request detail",
)
async def get_lesson_request(
    request_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonRequestResponse:
    """Return a single lesson request by ID."""
    service = LessonRequestService(db)
    return await service.get_by_id(request_id)


@router.put(
    "/{request_id}",
    response_model=LessonRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Update lesson request",
)
async def update_lesson_request(
    request_id: str,
    body: LessonRequestUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonRequestResponse:
    """Update a lesson request."""
    service = LessonRequestService(db)
    return await service.update(request_id, body, current_user)


@router.patch(
    "/{request_id}/status",
    response_model=LessonRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Change lesson request status",
)
async def update_lesson_request_status(
    request_id: str,
    body: LessonRequestStatusUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonRequestResponse:
    """Change the status of a lesson request."""
    service = LessonRequestService(db)
    return await service.update_status(request_id, body, current_user)


@router.delete(
    "/{request_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete lesson request",
)
async def delete_lesson_request(
    request_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a lesson request."""
    service = LessonRequestService(db)
    await service.delete(request_id, current_user)


@router.post(
    "/process-expired",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Process expired requests",
)
async def process_expired_requests(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SuccessResponse:
    """Mark expired lesson requests."""
    service = LessonRequestService(db)
    count = await service.process_expired()
    return SuccessResponse(message=f"Processed {count} expired requests")
