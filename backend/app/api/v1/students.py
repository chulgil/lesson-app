"""Student endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from pydantic import BaseModel

from app.core.deps import get_current_student, get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.schemas.student import StudentCreate, StudentResponse, StudentStatsResponse, StudentSummaryResponse, StudentUpdate
from app.services.student_service import StudentService


# ---------------------------------------------------------------------------
# Student self-profile schema
# ---------------------------------------------------------------------------


class StudentProfileSetup(BaseModel):
    """Student self-profile setup (onboarding)."""

    name: str
    instrument: str
    level: str = "beginner"
    phone: str | None = None


class StudentProfileUpdate(BaseModel):
    """Student self-profile update."""

    name: str | None = None
    instrument: str | None = None
    level: str | None = None
    phone: str | None = None
    profile_image_url: str | None = None

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
    search: str | None = None,
) -> PaginatedResponse[StudentResponse]:
    """List students visible to the current user (teacher or parent)."""
    # Accept both 'q' and 'search' query params (frontend sends 'search')
    search_query = q or search
    service = StudentService(db)
    return await service.get_all(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        status=student_status,
        class_id=class_id,
        q=search_query,
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
    "/summary",
    response_model=StudentSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get student summary statistics",
)
async def get_student_summary(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> StudentSummaryResponse:
    """Return summary statistics (total, active, by instrument) for the teacher's students."""
    service = StudentService(db)
    return await service.get_summary(current_user)


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


class StudentStatusUpdate(BaseModel):
    """Payload to update only the student status."""

    status: str


@router.patch(
    "/{student_id}/status",
    response_model=StudentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update student status (teacher only)",
)
async def update_student_status(
    student_id: str,
    body: StudentStatusUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> StudentResponse:
    """Update only the status field of a student."""
    service = StudentService(db)
    return await service.update_status(student_id, body.status, current_user)


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


# ---------------------------------------------------------------------------
# /students/me/* — Student self-service endpoints (학생 자기 관리)
# ---------------------------------------------------------------------------


@router.post(
    "/me/profile",
    response_model=StudentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Setup my student profile (student onboarding)",
)
async def setup_my_profile(
    body: StudentProfileSetup,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> StudentResponse:
    """Create the student's own profile during onboarding.

    Unlike POST /students (teacher-only), this allows a student
    to set up their own profile after OAuth signup.
    """
    service = StudentService(db)
    return await service.setup_student_profile(body, current_user)


@router.get(
    "/me/profile",
    response_model=StudentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my student profile",
)
async def get_my_profile(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> StudentResponse:
    """Return the authenticated student's own profile."""
    service = StudentService(db)
    return await service.get_student_by_user_id(current_user.id)


@router.put(
    "/me/profile",
    response_model=StudentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update my student profile",
)
async def update_my_profile(
    body: StudentProfileUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> StudentResponse:
    """Update the authenticated student's own profile."""
    service = StudentService(db)
    return await service.update_student_profile(body, current_user)
