"""Teacher endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.review import TeacherReviewSummary
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.teacher import (  # noqa: F401  Certificate * 는 endpoint decorator response_model 에서 사용 — ruff 가 일부 detect 못함.
    TeacherCertificateCreate,
    TeacherCertificateResponse,
    TeacherCertificateUpdate,
    TeacherDashboardResponse,
    TeacherPublicProfileResponse,
    TeacherResponse,
    TeacherUpdate,
)
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
    # Phase 44 (2026-06-10 audit) — 다중 instruments 필터 지원.
    instruments: Annotated[list[str] | None, Query()] = None,
    area: str | None = None,
    q: str | None = None,
    lesson_type: str | None = None,
    min_experience: Annotated[int | None, Query(ge=0)] = None,
    has_verified_certificate: bool | None = None,
    # spec teacher_registration.md §4.2 — feeRange 필터.
    fee_min: Annotated[int | None, Query(ge=0)] = None,
    fee_max: Annotated[int | None, Query(ge=0)] = None,
) -> PaginatedResponse[TeacherResponse]:
    """Search / list teacher profiles."""
    service = TeacherService(db)
    # 단수 instrument backward-compat — 다중 instruments 가 우선.
    effective_instruments = instruments or ([instrument] if instrument else None)
    return await service.get_all(
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        instrument=instrument,
        instruments=effective_instruments,
        area=area,
        q=q,
        lesson_type=lesson_type,
        min_experience=min_experience,
        has_verified_certificate=has_verified_certificate,
        fee_min=fee_min,
        fee_max=fee_max,
    )


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
        current_user,
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
    return await service.upsert_for_user(current_user.id, body, current_user)


# ---------------------------------------------------------------------------
# Certificate CRUD — teacher_registration.md §3 (자격증 업로드 → 검토 → 승인/반려)
# ---------------------------------------------------------------------------


@router.get(
    "/me/certificates",
    response_model=list[TeacherCertificateResponse],
    status_code=status.HTTP_200_OK,
    summary="List my certificates (teacher only)",
)
async def list_my_certificates(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> list[TeacherCertificateResponse]:
    """Return certificates owned by the authenticated teacher (any status)."""
    service = TeacherService(db)
    return await service.list_my_certificates(current_user.id)


@router.post(
    "/me/certificates",
    response_model=TeacherCertificateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit certificate for review (teacher only)",
)
async def create_my_certificate(
    body: TeacherCertificateCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherCertificateResponse:
    """Submit a new certificate. status = ``pending`` until reviewed (별도 admin endpoint)."""
    service = TeacherService(db)
    return await service.create_my_certificate(current_user.id, body.model_dump(exclude_unset=True))


@router.patch(
    "/me/certificates/{certificate_id}",
    response_model=TeacherCertificateResponse,
    status_code=status.HTTP_200_OK,
    summary="Update / re-submit certificate (teacher only)",
)
async def update_my_certificate(
    certificate_id: str,
    body: TeacherCertificateUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherCertificateResponse:
    """Re-submit certificate. approved 상태는 차단 (409). status reset → ``pending``."""
    service = TeacherService(db)
    return await service.update_my_certificate(current_user.id, certificate_id, body.model_dump(exclude_unset=True))


@router.delete(
    "/me/certificates/{certificate_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete certificate (teacher only)",
)
async def delete_my_certificate(
    certificate_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Delete own certificate. approved 상태도 삭제 허용 — 본인 self-revoke."""
    service = TeacherService(db)
    await service.delete_my_certificate(current_user.id, certificate_id)


@router.get(
    "/public/{teacher_id}",
    response_model=TeacherPublicProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get public teacher profile (no auth required)",
)
async def get_public_teacher_profile(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TeacherPublicProfileResponse:
    """Return public-facing teacher profile for web sharing.

    No authentication required. Only returns profile data safe for public viewing.
    Sensitive fields (phone, banking info, email) are excluded.
    """
    service = TeacherService(db)
    return await service.get_public_profile(teacher_id)


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
        current_user,
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


# Phase 44 (2026-06-10 audit) — RESTful alias for /reviews/{teacher_id}.
@router.get(
    "/{teacher_id}/reviews",
    response_model=PaginatedResponse,
    status_code=status.HTTP_200_OK,
    summary="List reviews for a teacher (RESTful alias)",
)
async def list_teacher_reviews_alias(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
):
    """spec discovery audit (2026-06-10) — /reviews/{id} alias."""
    from app.services.review_service import ReviewService

    service = ReviewService(db)
    return await service.get_reviews(
        teacher_id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.get(
    "/{teacher_id}/reviews/summary",
    response_model=TeacherReviewSummary,
    status_code=status.HTTP_200_OK,
    summary="Get review summary for a teacher (RESTful alias)",
)
async def get_teacher_review_summary_alias(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherReviewSummary:
    """spec discovery audit (2026-06-10) — /reviews/{id}/summary alias."""
    from app.services.review_service import ReviewService

    service = ReviewService(db)
    data = await service.get_review_summary(teacher_id)
    return TeacherReviewSummary.model_validate(data)
