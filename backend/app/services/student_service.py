"""Student service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.student import StudentCreate, StudentResponse, StudentStatsResponse, StudentSummaryResponse, StudentUpdate
from app.services.teacher_id_resolver import resolve_teacher_id


class StudentService:
    """Handle student CRUD and statistics."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        status: str | None = None,
        class_id: str | None = None,
        q: str | None = None,
    ) -> PaginatedResponse[StudentResponse]:
        """List students visible to the current user."""
        from app.models.student import Student

        tid = await resolve_teacher_id(self.db, user.id)
        query = select(Student).where(Student.teacher_id == tid)
        if status:
            query = query.where(Student.status == status)
        # class_id filter not supported in Student model directly
        # if class_id:
        #     query = query.where(Student.lesson_class_id == class_id)
        if q:
            query = query.where(Student.name.ilike(f"%{q}%"))

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [StudentResponse.model_validate(s) for s in result.all()]

        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create(self, data: StudentCreate, current_user: Any) -> StudentResponse:
        """Register a new student under the current teacher."""
        from app.models.student import Student

        tid = await resolve_teacher_id(self.db, current_user.id)
        create_data = data.model_dump(exclude_unset=True)
        student = Student(
            teacher_id=tid,
            name=create_data.pop("name"),
            instrument=create_data.pop("instrument", "") or "",
            level=create_data.pop("level", "beginner"),
            **{k: v for k, v in create_data.items() if v is not None},
        )
        self.db.add(student)
        await self.db.flush()
        await self.db.refresh(student)
        return StudentResponse.model_validate(student)

    async def get_by_id(self, student_id: str, current_user: Any) -> StudentResponse:
        """Return a single student by ID."""
        from app.models.student import Student

        student = await self.db.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
        return StudentResponse.model_validate(student)

    async def update(self, student_id: str, data: StudentUpdate, current_user: Any) -> StudentResponse:
        """Update student fields."""
        from app.models.student import Student

        student = await self.db.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(student, key, value)
        await self.db.flush()
        await self.db.refresh(student)
        return StudentResponse.model_validate(student)

    async def update_status(self, student_id: str, new_status: str, current_user: Any) -> StudentResponse:
        """Update only the student's status field."""
        from app.models.student import Student

        valid_statuses = {"trial", "active", "paused", "inactive"}
        if new_status not in valid_statuses:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status: {new_status}. Must be one of {valid_statuses}",
            )

        student = await self.db.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        student.status = new_status
        await self.db.flush()
        await self.db.refresh(student)
        return StudentResponse.model_validate(student)

    async def delete(self, student_id: str, current_user: Any) -> None:
        """Soft-delete a student."""
        from app.models.student import Student

        student = await self.db.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
        student.status = "inactive"
        await self.db.flush()

    async def get_stats(self, student_id: str, current_user: Any) -> StudentStatsResponse:
        """Return aggregated statistics for a student."""
        from app.models.lesson import Lesson

        total_lessons = await self.db.scalar(
            select(func.count()).where(Lesson.student_id == student_id)
        ) or 0
        completed_lessons = await self.db.scalar(
            select(func.count()).where(
                Lesson.student_id == student_id,
                Lesson.status == "completed",
            )
        ) or 0

        attendance_rate = (completed_lessons / total_lessons * 100) if total_lessons > 0 else 0.0

        return StudentStatsResponse(
            total_lessons=total_lessons,
            completed_lessons=completed_lessons,
            attendance_rate=round(attendance_rate, 1),
            practice_streak=0,
            total_practice_minutes=0,
            repertoire_count=0,
        )

    async def get_summary(self, current_user: Any) -> StudentSummaryResponse:
        """Return summary statistics for a teacher's students."""
        from app.models.student import Student

        tid = await resolve_teacher_id(self.db, current_user.id)
        query = select(Student).where(Student.teacher_id == tid)

        result = await self.db.scalars(query)
        students = result.all()

        total_count = len(students)
        active_count = sum(1 for s in students if s.status == "active")
        by_instrument: dict[str, int] = {}
        for s in students:
            instrument = s.instrument or ""
            if instrument:
                by_instrument[instrument] = by_instrument.get(instrument, 0) + 1

        return StudentSummaryResponse(
            total_count=total_count,
            active_count=active_count,
            by_instrument=by_instrument,
        )

    # ------------------------------------------------------------------
    # Student self-service (학생 자기 프로필)
    # ------------------------------------------------------------------

    async def setup_student_profile(self, data: Any, current_user: Any) -> StudentResponse:
        """Create student profile during onboarding (student self-service)."""
        from app.models.student import Student

        # Check if profile already exists
        existing = await self.db.scalar(
            select(Student).where(Student.user_id == current_user.id)
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Student profile already exists",
            )

        student = Student(
            user_id=current_user.id,
            teacher_id="",  # No teacher yet (will be set on connection)
            name=data.name,
            instrument=data.instrument,
            level=data.level,
            phone=getattr(data, "phone", None),
        )
        self.db.add(student)
        await self.db.flush()
        await self.db.refresh(student)
        return StudentResponse.model_validate(student)

    async def get_student_by_user_id(self, user_id: str) -> StudentResponse:
        """Get student profile by user_id."""
        from app.models.student import Student

        student = await self.db.scalar(
            select(Student).where(Student.user_id == user_id)
        )
        if student is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Student profile not found",
            )
        return StudentResponse.model_validate(student)

    async def update_student_profile(self, data: Any, current_user: Any) -> StudentResponse:
        """Update student's own profile."""
        from app.models.student import Student

        student = await self.db.scalar(
            select(Student).where(Student.user_id == current_user.id)
        )
        if student is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Student profile not found",
            )

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            if value is not None:
                setattr(student, key, value)
        await self.db.flush()
        await self.db.refresh(student)
        return StudentResponse.model_validate(student)
