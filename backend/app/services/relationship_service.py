"""Relationship and follow service."""

from __future__ import annotations

import secrets
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse


class RelationshipService:
    """Handle teacher-student relationships and follows."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def invite(self, student_id: str, method: str, current_user: Any) -> Any:
        """Create an invitation to connect with a student."""
        from app.models.relationship import TeacherStudentRelation

        invite_code = secrets.token_urlsafe(6).upper()[:6]

        relation = TeacherStudentRelation(
            teacher_id=current_user.id,
            student_id=student_id,
            invite_code=invite_code,
            status="pending",
        )
        self.db.add(relation)
        await self.db.flush()
        await self.db.refresh(relation)

        # TODO: send SMS / notification based on `method`

        return relation

    async def connect(self, invite_code: str, current_user: Any) -> Any:
        """Accept an invitation using an invite code."""
        from app.models.relationship import TeacherStudentRelation

        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.invite_code == invite_code,
                TeacherStudentRelation.status == "pending",
            )
        )
        if relation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid or expired invite code",
            )

        relation.status = "connected"
        await self.db.flush()
        await self.db.refresh(relation)
        return relation

    async def get_all(
        self, *, user: Any, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        """List all relationships for the current user."""
        from app.models.relationship import TeacherStudentRelation

        query = select(TeacherStudentRelation).where(
            (TeacherStudentRelation.teacher_id == user.id)
            | (TeacherStudentRelation.student_id == user.id)
        )

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = result.all()

        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_by_id(self, relationship_id: str, current_user: Any) -> Any:
        """Return a single relationship by ID."""
        from app.models.relationship import TeacherStudentRelation

        relation = await self.db.get(TeacherStudentRelation, relationship_id)
        if relation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Relationship not found",
            )
        return relation

    async def update_status(
        self, relationship_id: str, new_status: str, current_user: Any,
        *, subscription_id: str | None = None, booking_id: str | None = None,
        last_lesson_day: str | None = None, last_lesson_time: str | None = None,
        last_lesson_duration: int | None = None,
    ) -> Any:
        """Change the status of a relationship with optional metadata."""
        from datetime import datetime, timezone

        from app.models.relationship import TeacherStudentRelation

        relation = await self.db.get(TeacherStudentRelation, relationship_id)
        if relation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Relationship not found",
            )
        relation.status = new_status

        # Update optional metadata
        if subscription_id:
            relation.active_subscription_id = subscription_id
        if booking_id:
            relation.trial_booking_id = booking_id
        if last_lesson_day:
            relation.last_lesson_day = last_lesson_day
            relation.last_lesson_time = last_lesson_time
            relation.last_lesson_duration = last_lesson_duration
            relation.schedule_recorded_at = datetime.now(timezone.utc)

        await self.db.flush()
        await self.db.refresh(relation)
        return relation

    async def follow(self, following_id: str, target_type: str, current_user: Any) -> Any:
        """Follow a user."""
        from app.models.relationship import Follow

        follow = Follow(
            follower_id=current_user.id,
            following_id=following_id,
            target_type=target_type,
        )
        self.db.add(follow)
        await self.db.flush()
        await self.db.refresh(follow)
        return follow

    async def unfollow(self, follow_id: str, current_user: Any) -> None:
        """Unfollow."""
        from app.models.relationship import Follow

        follow = await self.db.get(Follow, follow_id)
        if follow is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Follow not found",
            )
        if follow.follower_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot unfollow for another user",
            )
        await self.db.delete(follow)
        await self.db.flush()
