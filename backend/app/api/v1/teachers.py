"""Teacher endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.student import StudentResponse
from app.schemas.teacher import TeacherDashboardResponse, TeacherResponse, TeacherUpdate
from app.services.teacher_service import TeacherService

router = APIRouter()


@router.get(
    "",
    response_model=PaginatedResponse[TeacherResponse],
    status_code=status.HTTP_200_OK,
    summary="List teachers (search / explore)",
)
async def list_teachers(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    instrument: str | None = None,
    area: str | None = None,
    q: str | None = None,
) -> PaginatedResponse[TeacherResponse]:
    """Search / list teacher profiles."""
    service = TeacherService(db)
    return await service.get_all(
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        instrument=instrument,
        area=area,
        q=q,
    )


@router.get(
    "/{teacher_id}",
    response_model=TeacherResponse,
    status_code=status.HTTP_200_OK,
    summary="Get teacher detail",
)
async def get_teacher(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherResponse:
    """Return a single teacher profile by ID."""
    service = TeacherService(db)
    return await service.get_by_id(teacher_id)


@router.put(
    "/{teacher_id}",
    response_model=TeacherResponse,
    status_code=status.HTTP_200_OK,
    summary="Update teacher profile (owner only)",
)
async def update_teacher(
    teacher_id: str,
    body: TeacherUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherResponse:
    """Update teacher profile fields. Only the owner can modify."""
    service = TeacherService(db)
    return await service.update(teacher_id, body, current_user)


@router.get(
    "/{teacher_id}/students",
    response_model=PaginatedResponse[StudentResponse],
    status_code=status.HTTP_200_OK,
    summary="List students for a teacher",
)
async def get_teacher_students(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    student_status: Annotated[str | None, Query(alias="status")] = None,
    class_id: str | None = None,
) -> PaginatedResponse[StudentResponse]:
    """Return students linked to a teacher."""
    service = TeacherService(db)
    return await service.get_students(
        teacher_id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        status=student_status,
        class_id=class_id,
    )


@router.get(
    "/{teacher_id}/dashboard",
    response_model=TeacherDashboardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get teacher dashboard data",
)
async def get_teacher_dashboard(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherDashboardResponse:
    """Return aggregated dashboard data for the teacher."""
    service = TeacherService(db)
    return await service.get_dashboard(teacher_id, current_user)


# ---------------------------------------------------------------------------
# /teachers/me/* — Teacher-specific endpoints (선생님 전용)
# ---------------------------------------------------------------------------


@router.get(
    "/me/profile",
    response_model=TeacherResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my teacher profile",
)
async def get_my_profile(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherResponse:
    """Return the authenticated teacher's own profile."""
    service = TeacherService(db)
    return await service.get_by_user_id(current_user.id)


@router.get(
    "/me/dashboard",
    response_model=TeacherDashboardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my dashboard (teacher only)",
)
async def get_my_dashboard(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherDashboardResponse:
    """Return dashboard data for the authenticated teacher."""
    service = TeacherService(db)
    return await service.get_dashboard(current_user.id, current_user)


@router.get(
    "/me/students",
    response_model=PaginatedResponse[StudentResponse],
    status_code=status.HTTP_200_OK,
    summary="List my students (teacher only)",
)
async def list_my_students(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    pagination: Annotated[dict, Depends(get_pagination)],
    student_status: Annotated[str | None, Query(alias="status")] = None,
    class_id: str | None = None,
) -> PaginatedResponse[StudentResponse]:
    """Return students under the authenticated teacher."""
    service = TeacherService(db)
    return await service.get_students(
        current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        status=student_status,
        class_id=class_id,
    )


@router.post(
    "/me/students",
    response_model=StudentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register student (teacher only)",
)
async def create_my_student(
    body: StudentCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> StudentResponse:
    """Register a new student under the authenticated teacher."""
    from app.services.student_service import StudentService

    service = StudentService(db)
    return await service.create(body, current_user)


@router.put(
    "/me/profile",
    response_model=TeacherResponse,
    status_code=status.HTTP_200_OK,
    summary="Update my profile (teacher only)",
)
async def update_my_profile(
    body: TeacherUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherResponse:
    """Update the authenticated teacher's profile."""
    service = TeacherService(db)
    return await service.update(current_user.id, body, current_user)
