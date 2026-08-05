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
            select(TeacherCareer).where(TeacherCareer.teacher_id == teacher.id).order_by(TeacherCareer.sort_order)
        )
        certificates = await self.db.scalars(
            select(TeacherCertificate).where(TeacherCertificate.teacher_id == teacher.id)
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
        instruments: list[str] | None = None,
        area: str | None = None,
        q: str | None = None,
        lesson_type: str | None = None,
        min_experience: int | None = None,
        has_verified_certificate: bool | None = None,
        fee_min: int | None = None,
        fee_max: int | None = None,
    ) -> PaginatedResponse[TeacherResponse]:
        """List / search teachers with pagination.

        Phase 44 (2026-06-10 audit) — instruments 다중 + visibility_settings.is_public=false 차단.
        """
        from app.models.teacher import CertificateStatus, Teacher, TeacherCertificate
        from app.models.user import User

        query = select(Teacher)

        # Phase 44 — 다중 instruments OR 매칭. 명시되면 단수 instrument 무시.
        if instruments:
            from sqlalchemy import or_ as _or

            query = query.where(_or(*[Teacher.instruments.cast(String).ilike(f"%{inst}%") for inst in instruments]))
        elif instrument:
            # JSON array contains check (SQLite: use LIKE, PostgreSQL: use @>)
            query = query.where(Teacher.instruments.cast(String).ilike(f"%{instrument}%"))
        if area:
            query = query.where(Teacher.lesson_areas.cast(String).ilike(f"%{area}%"))
        if lesson_type:
            query = query.where(Teacher.lesson_types.cast(String).ilike(f"%{lesson_type}%"))
        if min_experience is not None:
            query = query.where(Teacher.experience_years >= min_experience)
        # spec teacher_registration.md §4.2 — feeRange 필터.
        # teacher 의 fee_max 가 검색의 fee_min 보다 작거나, fee_min 이 검색 fee_max 보다 크면 제외.
        if fee_min is not None:
            query = query.where((Teacher.fee_max.is_(None)) | (Teacher.fee_max >= fee_min))
        if fee_max is not None:
            query = query.where((Teacher.fee_min.is_(None)) | (Teacher.fee_min <= fee_max))
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

        # Phase 44 (2026-06-10 audit) — visibility_settings.is_public=false 차단.
        # NULL (미설정) 또는 is_public!=false 인 선생님만 검색 결과 노출.
        query = query.where(
            or_(
                Teacher.visibility_settings.is_(None),
                Teacher.visibility_settings.cast(String).not_ilike('%"is_public": false%'),
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

        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == user_id))
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
            select(TeacherCareer).where(TeacherCareer.teacher_id == teacher.id).order_by(TeacherCareer.sort_order)
        )

        return TeacherPublicProfileResponse(
            id=teacher.id,
            name=user.name if user else "",
            nickname=teacher.nickname,
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

        total_students = await self.db.scalar(select(func.count()).where(Student.teacher_id == teacher_id)) or 0
        active_students = (
            await self.db.scalar(
                select(func.count()).where(Student.teacher_id == teacher_id, Student.status == "active")
            )
            or 0
        )

        today_lessons = (
            await self.db.scalar(select(func.count()).where(Lesson.teacher_id == teacher_id, Lesson.date == today)) or 0
        )
        week_lessons = (
            await self.db.scalar(
                select(func.count()).where(
                    Lesson.teacher_id == teacher_id,
                    Lesson.date >= today,
                    Lesson.date < week_end,
                )
            )
            or 0
        )

        upcoming_result = await self.db.scalars(
            select(Lesson).where(Lesson.teacher_id == teacher_id, Lesson.date >= today).order_by(Lesson.date).limit(5)
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

    # ---------------------------------------------------------------------------
    # Certificate CRUD — teacher_registration.md §3 (자격증 업로드 → 검토 → 승인/반려)
    # ---------------------------------------------------------------------------

    async def list_my_certificates(self, user_id: str) -> list:
        """Return certificates owned by the authenticated teacher."""
        from datetime import UTC, datetime  # noqa: F401

        from app.models.teacher import Teacher, TeacherCertificate

        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == user_id))
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher profile not found")
        result = await self.db.scalars(select(TeacherCertificate).where(TeacherCertificate.teacher_id == teacher.id))
        return [TeacherCertificateResponse.model_validate(c) for c in result.all()]

    async def create_my_certificate(self, user_id: str, data: dict) -> TeacherCertificateResponse:
        """Submit a new certificate for review. status starts as ``pending``."""
        from datetime import UTC, datetime

        from app.models.teacher import CertificateStatus, CertificateType, Teacher, TeacherCertificate

        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == user_id))
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher profile not found")
        try:
            cert_type = CertificateType(data["type"])
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Unknown certificate type: {data['type']}",
            ) from exc
        certificate = TeacherCertificate(
            teacher_id=teacher.id,
            type=cert_type,
            name=data["name"],
            issuing_body=data.get("issuing_body"),
            issue_date=data.get("issue_date"),
            certificate_number=data.get("certificate_number"),
            image_url=data.get("image_url"),
            status=CertificateStatus.pending,
            submitted_at=datetime.now(UTC),
        )
        self.db.add(certificate)
        await self.db.flush()
        await self.db.refresh(certificate)
        return TeacherCertificateResponse.model_validate(certificate)

    async def update_my_certificate(self, user_id: str, certificate_id: str, data: dict) -> TeacherCertificateResponse:
        """Re-submit a certificate. status 가 approved 면 갱신 차단."""
        from app.models.teacher import CertificateStatus, CertificateType, Teacher, TeacherCertificate

        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == user_id))
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher profile not found")
        certificate = await self.db.scalar(
            select(TeacherCertificate)
            .where(TeacherCertificate.id == certificate_id)
            .where(TeacherCertificate.teacher_id == teacher.id)
        )
        if certificate is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Certificate not found")
        if certificate.status == CertificateStatus.approved:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Approved certificates cannot be edited",
            )
        if "type" in data and data["type"] is not None:
            try:
                certificate.type = CertificateType(data["type"])
            except ValueError as exc:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=f"Unknown certificate type: {data['type']}",
                ) from exc
        for key in ("name", "issuing_body", "issue_date", "certificate_number", "image_url"):
            if key in data and data[key] is not None:
                setattr(certificate, key, data[key])
        # 재제출 시 status 를 pending 으로 reset.
        certificate.status = CertificateStatus.pending
        certificate.rejection_reason = None
        certificate.reviewed_at = None
        await self.db.flush()
        await self.db.refresh(certificate)
        return TeacherCertificateResponse.model_validate(certificate)

    async def delete_my_certificate(self, user_id: str, certificate_id: str) -> None:
        """Delete a certificate. approved 상태도 삭제 허용 — 본인이 self-revoke 가능."""
        from app.models.teacher import Teacher, TeacherCertificate

        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == user_id))
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher profile not found")
        certificate = await self.db.scalar(
            select(TeacherCertificate)
            .where(TeacherCertificate.id == certificate_id)
            .where(TeacherCertificate.teacher_id == teacher.id)
        )
        if certificate is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Certificate not found")
        await self.db.delete(certificate)
        await self.db.flush()
