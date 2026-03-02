"""Student endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.schemas.student import StudentCreate, StudentResponse, StudentStatsResponse, StudentUpdate
from app.services.student_service import StudentService

router = APIRouter()


@router.get(
    "",
    response_model=PaginatedResponse[StudentResponse],
    status_code=status.HTTP_200_OK,
    summary="List students",
)
async def list_students(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    student_status: Annotated[str | None, Query(alias="status")] = None,
    class_id: str | None = None,
    q: str | None = None,
) -> PaginatedResponse[StudentResponse]:
    """List students visible to the current user (teacher or parent)."""
    service = StudentService(db)
    return await service.get_all(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        status=student_status,
        class_id=class_id,
        q=q,
    )


@router.post(
    "",
    response_model=StudentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create student (teacher only)",
)
async def create_student(
    body: StudentCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> StudentResponse:
    """Register a new student under the current teacher."""
    service = StudentService(db)
    return await service.create(body, current_user)


@router.get(
    "/{student_id}",
    response_model=StudentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get student detail",
)
async def get_student(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> StudentResponse:
    """Return a single student by ID."""
    service = StudentService(db)
    return await service.get_by_id(student_id, current_user)


@router.put(
    "/{student_id}",
    response_model=StudentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update student (teacher only)",
)
async def update_student(
    student_id: str,
    body: StudentUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> StudentResponse:
    """Update student fields."""
    service = StudentService(db)
    return await service.update(student_id, body, current_user)


@router.delete(
    "/{student_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete student (soft delete, teacher only)",
)
async def delete_student(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Soft-delete a student."""
    service = StudentService(db)
    await service.delete(student_id, current_user)


@router.get(
    "/{student_id}/stats",
    response_model=StudentStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get student statistics",
)
async def get_student_stats(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> StudentStatsResponse:
    """Return aggregated statistics for a student."""
    service = StudentService(db)
    return await service.get_stats(student_id, current_user)
