"""Parent service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.lesson import LessonResponse
from app.schemas.parent import ParentChildResponse, ParentResponse, ParentUpdate
from app.schemas.practice import PracticeStatsResponse


class ParentService:
    """Handle parent profile and child management."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_profile(self, current_user: Any) -> ParentResponse:
        """Return the parent profile."""
        from app.models.parent import Parent

        parent = await self.db.scalar(
            select(Parent).where(Parent.user_id == current_user.id)
        )
        if parent is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent profile not found")
        return ParentResponse.model_validate(parent)

    async def update_profile(self, data: ParentUpdate, current_user: Any) -> ParentResponse:
        """Update the parent profile."""
        from app.models.parent import Parent

        parent = await self.db.scalar(
            select(Parent).where(Parent.user_id == current_user.id)
        )
        if parent is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent profile not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(parent, key, value)
        await self.db.flush()
        await self.db.refresh(parent)
        return ParentResponse.model_validate(parent)

    async def get_children(self, current_user: Any) -> list[ParentChildResponse]:
        """Return the list of linked children."""
        from app.models.parent import Parent, ParentChildRelation
        from app.models.student import Student
        from app.schemas.student import StudentResponse

        parent = await self.db.scalar(
            select(Parent).where(Parent.user_id == current_user.id)
        )
        if parent is None:
            return []

        relations = await self.db.scalars(
            select(ParentChildRelation).where(ParentChildRelation.parent_id == parent.id)
        )

        children = []
        for rel in relations.all():
            student = await self.db.get(Student, rel.student_id)
            if student:
                children.append(
                    ParentChildResponse(
                        student=StudentResponse.model_validate(student),
                        linked_at=rel.created_at,
                    )
                )
        return children

    async def connect_child(self, invite_code: str, current_user: Any) -> ParentChildResponse:
        """Link a child via invite code."""
        # TODO: look up invite code, resolve student, create ParentChildRelation
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Child connection via invite code not yet implemented",
        )

    async def get_child_lessons(
        self,
        student_id: str,
        current_user: Any,
        *,
        date_from: str | None = None,
        date_to: str | None = None,
    ) -> list[LessonResponse]:
        """Return lessons for a linked child."""
        from app.models.lesson import Lesson

        query = select(Lesson).where(Lesson.student_id == student_id)
        if date_from:
            query = query.where(Lesson.date >= date_from)
        if date_to:
            query = query.where(Lesson.date <= date_to)

        result = await self.db.scalars(query.order_by(Lesson.date.desc()))
        return [LessonResponse.model_validate(l) for l in result.all()]

    async def get_child_practice(
        self,
        student_id: str,
        current_user: Any,
        *,
        year: int | None = None,
        month: int | None = None,
    ) -> PracticeStatsResponse:
        """Return practice statistics for a child."""
        # TODO: delegate to PracticeService.get_stats
        return PracticeStatsResponse(
            total_practice_minutes=0,
            total_practice_days=0,
            completed_sections=0,
            current_streak=0,
            longest_streak=0,
            daily_stats={},
        )
