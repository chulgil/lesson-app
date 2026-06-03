"""Teacher service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import String, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.student import StudentResponse
from app.schemas.teacher import (
    TeacherCareerResponse,
    TeacherCertificateResponse,
    TeacherDashboardResponse,
    TeacherEducationResponse,
    TeacherPublicProfileResponse,
    TeacherResponse,
    TeacherUpdate,
)


class TeacherService:
    """Handle teacher profile and dashboard operations."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _enrich_response(self, teacher: Any) -> TeacherResponse:
        """Build TeacherResponse with user, education, career, certificates."""
        from app.models.teacher import TeacherCareer, TeacherCertificate, TeacherEducation
        from app.models.user import User
        from app.schemas.user import UserResponse

        # Load user info
        user = await self.db.get(User, teacher.user_id)

        education = await self.db.scalars(
            select(TeacherEducation)
            .where(TeacherEducation.teacher_id == teacher.id)
            .order_by(TeacherEducation.sort_order)
        )
        career = await self.db.scalars(
            select(TeacherCareer)
            .where(TeacherCareer.teacher_id == teacher.id)
            .order_by(TeacherCareer.sort_order)
        )
        certificates = await self.db.scalars(
            select(TeacherCertificate)
            .where(TeacherCertificate.teacher_id == teacher.id)
        )

        response = TeacherResponse.model_validate(teacher)
        if user:
            response.user = UserResponse.model_validate(user)
        response.education = [TeacherEducationResponse.model_validate(e) for e in education.all()]
        response.career = [TeacherCareerResponse.model_validate(c) for c in career.all()]
        response.certificates = [TeacherCertificateResponse.model_validate(c) for c in certificates.all()]
        return response

    async def get_all(
        self,
        *,
        page: int,
        size: int,
        offset: int,
        instrument: str | None = None,
        area: str | None = None,
        q: str | None = None,
        lesson_type: str | None = None,
        min_experience: int | None = None,
        has_verified_certificate: bool | None = None,
    ) -> PaginatedResponse[TeacherResponse]:
        """List / search teachers with pagination."""
        from app.models.teacher import CertificateStatus, Teacher, TeacherCertificate
        from app.models.user import User

        query = select(Teacher)

        if instrument:
            # JSON array contains check (SQLite: use LIKE, PostgreSQL: use @>)
            query = query.where(Teacher.instruments.cast(String).ilike(f"%{instrument}%"))
        if area:
            query = query.where(Teacher.lesson_areas.cast(String).ilike(f"%{area}%"))
        if lesson_type:
            query = query.where(Teacher.lesson_types.cast(String).ilike(f"%{lesson_type}%"))
        if min_experience is not None:
            query = query.where(Teacher.experience_years >= min_experience)
        if has_verified_certificate is True:
            approved_certificate_exists = (
                select(TeacherCertificate.id)
                .where(
                    TeacherCertificate.teacher_id == Teacher.id,
                    TeacherCertificate.status == CertificateStatus.approved,
                )
                .exists()
            )
            query = query.where(approved_certificate_exists)
        if q:
            query = query.join(User, User.id == Teacher.user_id).where(
                or_(
                    User.name.ilike(f"%{q}%"),
                    Teacher.introduction.ilike(f"%{q}%"),
                    Teacher.instruments.cast(String).ilike(f"%{q}%"),
                    Teacher.lesson_areas.cast(String).ilike(f"%{q}%"),
                )
            )

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [await self._enrich_response(t) for t in result.all()]

        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_by_id(self, teacher_id: str) -> TeacherResponse:
        """Return a single teacher by ID."""
        from app.models.teacher import Teacher

        teacher = await self.db.get(Teacher, teacher_id)
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
        return await self._enrich_response(teacher)

    async def get_by_user_id(self, user_id: str) -> TeacherResponse:
        """Return a teacher profile by the owning user ID."""
        from app.models.teacher import Teacher

        teacher = await self.db.scalar(
            select(Teacher).where(Teacher.user_id == user_id)
        )
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher profile not found")
        return await self._enrich_response(teacher)

    async def get_public_profile(self, teacher_id: str) -> TeacherPublicProfileResponse:
        """Return public-facing teacher profile by teacher ID. No auth required."""
        from app.models.teacher import Teacher, TeacherCareer, TeacherEducation
        from app.models.user import User

        teacher = await self.db.get(Teacher, teacher_id)
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")

        user = await self.db.get(User, teacher.user_id)

        education_rows = await self.db.scalars(
            select(TeacherEducation)
            .where(TeacherEducation.teacher_id == teacher.id)
            .order_by(TeacherEducation.sort_order)
        )
        career_rows = await self.db.scalars(
            select(TeacherCareer)
            .where(TeacherCareer.teacher_id == teacher.id)
            .order_by(TeacherCareer.sort_order)
        )

        return TeacherPublicProfileResponse(
            id=teacher.id,
            name=user.name if user else "",
            profile_image_url=user.profile_image_url if user else None,
            instruments=teacher.instruments or [],
            introduction=teacher.introduction,
            experience_years=teacher.experience_years,
            lesson_areas=teacher.lesson_areas or [],
            lesson_types=teacher.lesson_types or [],
            fee_min=teacher.fee_min,
            fee_max=teacher.fee_max,
            fee_duration=teacher.fee_duration,
            teaching_style=teacher.teaching_style,
            specialties=teacher.specialties or [],
            portfolio_video_urls=teacher.portfolio_video_urls or [],
            is_phone_verified=teacher.is_phone_verified,
            background_image=teacher.background_image,
            education=[TeacherEducationResponse.model_validate(e) for e in education_rows.all()],
            career=[TeacherCareerResponse.model_validate(c) for c in career_rows.all()],
        )

    async def update(self, teacher_id: str, data: TeacherUpdate, current_user: Any) -> TeacherResponse:
        """Update teacher profile (owner only)."""
        from app.models.teacher import Teacher
        from app.services.user_service import UserService

        teacher = await self.db.get(Teacher, teacher_id)
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
        if teacher.user_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not the profile owner")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(teacher, key, value)
        await self.db.flush()
        await self.db.refresh(teacher)
        await UserService(self.db).complete_onboarding_quest(current_user, "teacher.profile")
        return await self._enrich_response(teacher)

    async def upsert_for_user(self, user_id: str, data: TeacherUpdate, current_user: Any) -> TeacherResponse:
        """Create or update the teacher profile owned by a user."""
        from app.models.teacher import Teacher

        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == user_id))
        if teacher is None:
            teacher = Teacher(user_id=user_id, instruments=[])
            self.db.add(teacher)
            await self.db.flush()

        return await self.update(teacher.id, data, current_user)

    async def _assert_self(self, teacher_id: str, current_user: Any) -> None:
        """Verify the path teacher_id belongs to the authenticated user (IDOR guard)."""
        from app.services.teacher_id_resolver import try_resolve_teacher_id

        resolved = await try_resolve_teacher_id(self.db, current_user.id)
        if teacher_id not in (current_user.id, resolved):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def get_students(
        self,
        teacher_id: str,
        current_user: Any,
        *,
        page: int,
        size: int,
        offset: int,
        status: str | None = None,
        class_id: str | None = None,
    ) -> PaginatedResponse[StudentResponse]:
        """Return students associated with a teacher."""
        from app.models.student import Student

        await self._assert_self(teacher_id, current_user)

        query = select(Student).where(Student.teacher_id == teacher_id)
        if status:
            query = query.where(Student.status == status)
        if class_id:
            query = query.where(Student.lesson_class_id == class_id)  # type: ignore[attr-defined]

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [StudentResponse.model_validate(s) for s in result.all()]

        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_dashboard(self, teacher_id: str, current_user: Any) -> TeacherDashboardResponse:
        """Build aggregated dashboard data for a teacher."""
        from datetime import date, timedelta

        from app.models.lesson import Lesson
        from app.models.student import Student

        await self._assert_self(teacher_id, current_user)

        today = date.today()
        week_end = today + timedelta(days=7)

        total_students = await self.db.scalar(
            select(func.count()).where(Student.teacher_id == teacher_id)
        ) or 0
        active_students = await self.db.scalar(
            select(func.count()).where(Student.teacher_id == teacher_id, Student.status == "active")
        ) or 0

        today_lessons = await self.db.scalar(
            select(func.count()).where(Lesson.teacher_id == teacher_id, Lesson.date == today)
        ) or 0
        week_lessons = await self.db.scalar(
            select(func.count()).where(
                Lesson.teacher_id == teacher_id,
                Lesson.date >= today,
                Lesson.date < week_end,
            )
        ) or 0

        upcoming_result = await self.db.scalars(
            select(Lesson)
            .where(Lesson.teacher_id == teacher_id, Lesson.date >= today)
            .order_by(Lesson.date)
            .limit(5)
        )
        from app.schemas.lesson import LessonResponse

        upcoming = [LessonResponse.model_validate(lesson) for lesson in upcoming_result.all()]

        return TeacherDashboardResponse(
            total_students=total_students,
            active_students=active_students,
            today_lessons=today_lessons,
            week_lessons=week_lessons,
            unpaid_count=0,
            upcoming_lessons=upcoming,
        )
