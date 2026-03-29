"""Lesson and lesson-class service."""

from __future__ import annotations

from datetime import date
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.lesson import (
    LessonClassCreate,
    LessonClassResponse,
    LessonClassUpdate,
    LessonCreate,
    LessonFeedbackUpdate,
    LessonResponse,
    LessonUpdate,
    MembershipCreate,
    MembershipResponse,
    MembershipUpdate,
)
from app.services.teacher_id_resolver import resolve_teacher_id


class LessonService:
    """Handle lesson and lesson-class business logic."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Lessons
    # ------------------------------------------------------------------

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        student_id: str | None = None,
        date: str | None = None,
        date_from: str | None = None,
        date_to: str | None = None,
        status: str | None = None,
    ) -> PaginatedResponse[LessonResponse]:
        """List lessons with filters."""
        from app.models.lesson import Lesson

        tid = await resolve_teacher_id(self.db, user.id)
        query = select(Lesson).where(Lesson.teacher_id == tid)
        if student_id:
            query = query.where(Lesson.student_id == student_id)
        if date:
            query = query.where(Lesson.date == date)
        if date_from:
            query = query.where(Lesson.date >= date_from)
        if date_to:
            query = query.where(Lesson.date <= date_to)
        if status:
            query = query.where(Lesson.status == status)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.order_by(Lesson.date.desc()).offset(offset).limit(size))
        items = [LessonResponse.model_validate(l) for l in result.all()]

        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create(self, data: LessonCreate, current_user: Any) -> LessonResponse:
        """Create a new lesson."""
        from app.models.lesson import Lesson

        tid = await resolve_teacher_id(self.db, current_user.id)
        lesson = Lesson(
            teacher_id=tid,
            student_id=data.student_id,
            student_name=data.student_id,  # TODO: resolve actual student name
            instrument=data.instrument or "",
            date=data.date,
            start_time=data.start_time or "00:00",
            duration=data.duration,
            location_name=data.location_name,
        )
        self.db.add(lesson)
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def get_by_id(self, lesson_id: str, current_user: Any) -> LessonResponse:
        """Return a lesson by ID."""
        from app.models.lesson import Lesson

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")
        return LessonResponse.model_validate(lesson)

    async def update(self, lesson_id: str, data: LessonUpdate, current_user: Any) -> LessonResponse:
        """Update a lesson."""
        from app.models.lesson import Lesson

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        update_data = data.model_dump(exclude_unset=True, exclude={"pieces"})
        for key, value in update_data.items():
            setattr(lesson, key, value)
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def update_status(self, lesson_id: str, new_status: str, current_user: Any) -> LessonResponse:
        """Change lesson status."""
        from app.models.lesson import Lesson

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")
        lesson.status = new_status
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def update_feedback(
        self, lesson_id: str, data: LessonFeedbackUpdate, current_user: Any
    ) -> LessonResponse:
        """Write or update feedback for a lesson."""
        from app.models.lesson import Lesson

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        if data.feedback is not None:
            lesson.feedback = data.feedback
        if data.practice_tips is not None:
            lesson.practice_tips = data.practice_tips
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def get_upcoming(self, current_user: Any, *, limit: int = 10) -> list[LessonResponse]:
        """Return upcoming lessons."""
        from app.models.lesson import Lesson

        today = date.today()
        result = await self.db.scalars(
            select(Lesson)
            .where(Lesson.teacher_id == await resolve_teacher_id(self.db, current_user.id), Lesson.date >= today)
            .order_by(Lesson.date)
            .limit(limit)
        )
        return [LessonResponse.model_validate(l) for l in result.all()]

    async def get_recent(self, current_user: Any, *, limit: int = 10) -> list[LessonResponse]:
        """Return recently completed lessons."""
        from app.models.lesson import Lesson

        result = await self.db.scalars(
            select(Lesson)
            .where(Lesson.teacher_id == await resolve_teacher_id(self.db, current_user.id), Lesson.status == "completed")
            .order_by(Lesson.date.desc())
            .limit(limit)
        )
        return [LessonResponse.model_validate(l) for l in result.all()]

    # ------------------------------------------------------------------
    # Lesson classes
    # ------------------------------------------------------------------

    async def get_all_classes(
        self, current_user: Any, *, page: int, size: int, offset: int
    ) -> PaginatedResponse[LessonClassResponse]:
        """List lesson classes for the teacher."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        query = select(LessonClass).where(
            LessonClass.teacher_id == tid,
            LessonClass.is_archived == False,  # noqa: E712
        )
        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [LessonClassResponse.model_validate(c) for c in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create_class(self, data: LessonClassCreate, current_user: Any) -> LessonClassResponse:
        """Create a lesson class."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        lesson_class = LessonClass(
            teacher_id=tid,
            name=data.name,
            type=data.type,
            payment_type=data.payment_type,
            contact_person=data.contact_person,
            contact_phone=data.contact_phone,
            address=data.address,
        )
        self.db.add(lesson_class)
        await self.db.flush()
        await self.db.refresh(lesson_class)
        return LessonClassResponse.model_validate(lesson_class)

    async def get_class_by_id(self, class_id: str, current_user: Any) -> LessonClassResponse:
        """Return a lesson class."""
        from app.models.lesson import LessonClass

        lc = await self.db.get(LessonClass, class_id)
        if lc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson class not found")
        return LessonClassResponse.model_validate(lc)

    async def update_class(
        self, class_id: str, data: LessonClassUpdate, current_user: Any
    ) -> LessonClassResponse:
        """Update a lesson class."""
        from app.models.lesson import LessonClass

        lc = await self.db.get(LessonClass, class_id)
        if lc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson class not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(lc, key, value)
        await self.db.flush()
        await self.db.refresh(lc)
        return LessonClassResponse.model_validate(lc)

    async def delete_class(self, class_id: str, current_user: Any) -> None:
        """Archive a lesson class."""
        from app.models.lesson import LessonClass

        lc = await self.db.get(LessonClass, class_id)
        if lc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson class not found")
        lc.is_archived = True
        await self.db.flush()

    async def restore_class(self, class_id: str, current_user: Any) -> LessonClassResponse:
        """Restore an archived lesson class."""
        from app.models.lesson import LessonClass

        lc = await self.db.get(LessonClass, class_id)
        if lc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson class not found")
        lc.is_archived = False
        await self.db.flush()
        await self.db.refresh(lc)
        return LessonClassResponse.model_validate(lc)

    async def reorder_classes(self, ordered_ids: list[str], current_user: Any) -> None:
        """Set display order for lesson classes."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        for idx, class_id in enumerate(ordered_ids):
            lc = await self.db.get(LessonClass, class_id)
            if lc and lc.teacher_id == tid:
                lc.sort_order = idx
        await self.db.flush()

    # ------------------------------------------------------------------
    # Memberships
    # ------------------------------------------------------------------

    async def get_memberships_by_class(
        self, class_id: str, current_user: Any
    ) -> list[MembershipResponse]:
        """List all memberships in a class."""
        from app.models.lesson import ClassMembership

        result = await self.db.scalars(
            select(ClassMembership).where(ClassMembership.lesson_class_id == class_id)
        )
        return [MembershipResponse.model_validate(m) for m in result.all()]

    async def get_membership_by_id(self, membership_id: str, current_user: Any) -> MembershipResponse:
        """Return a single membership."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        return MembershipResponse.model_validate(m)

    async def add_membership(
        self, class_id: str, data: MembershipCreate, current_user: Any
    ) -> MembershipResponse:
        """Add a student to a class."""
        from app.models.lesson import ClassMembership

        membership = ClassMembership(
            lesson_class_id=class_id,
            student_id=data.student_id,
            instrument=data.instrument or "",
            monthly_fee=data.monthly_fee or 0,
            lessons_per_week=data.lessons_per_week or 1,
            lesson_day=data.lesson_day,
            lesson_time=data.lesson_time,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(membership)
        return MembershipResponse.model_validate(membership)

    async def update_membership(
        self, class_id: str, membership_id: str, data: MembershipUpdate, current_user: Any
    ) -> MembershipResponse:
        """Update a class membership."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(m, key, value)
        await self.db.flush()
        await self.db.refresh(m)
        return MembershipResponse.model_validate(m)

    async def remove_membership(self, class_id: str, membership_id: str, current_user: Any) -> None:
        """Remove a membership from a class."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self.db.delete(m)
        await self.db.flush()
