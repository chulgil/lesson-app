"""Lesson request service."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.lesson_request import (
    LessonRequestCreate,
    LessonRequestResponse,
    LessonRequestStatusUpdate,
    LessonRequestUpdate,
)


class LessonRequestService:
    """Handle lesson request lifecycle."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        teacher_id: str | None = None,
        student_id: str | None = None,
        request_status: str | None = None,
    ) -> PaginatedResponse[LessonRequestResponse]:
        """List lesson requests with filters."""
        from app.models.schedule import LessonRequest

        query = select(LessonRequest)
        if teacher_id:
            query = query.where(LessonRequest.teacher_id == teacher_id)
        if student_id:
            query = query.where(LessonRequest.student_id == student_id)
        if request_status:
            query = query.where(LessonRequest.status == request_status)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(
            query.order_by(LessonRequest.created_at.desc()).offset(offset).limit(size)
        )
        items = [LessonRequestResponse.model_validate(r) for r in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create(self, data: LessonRequestCreate, current_user: Any) -> LessonRequestResponse:
        """Create a lesson request."""
        from app.models.schedule import LessonRequest

        request = LessonRequest(
            student_id=current_user.id,
            teacher_id=data.teacher_id,
            message=data.message,
            preferred_timing=data.preferred_timing,
            keep_previous_schedule=data.keep_previous_schedule,
            previous_lesson_day=data.previous_lesson_day,
            previous_lesson_time=data.previous_lesson_time,
            previous_lesson_duration=data.previous_lesson_duration,
            expires_at=datetime.now(timezone.utc) + timedelta(days=14),
        )
        self.db.add(request)
        await self.db.flush()
        await self.db.refresh(request)
        return LessonRequestResponse.model_validate(request)

    async def get_by_id(self, request_id: str) -> LessonRequestResponse:
        """Return a single lesson request."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")
        return LessonRequestResponse.model_validate(request)

    async def update(
        self, request_id: str, data: LessonRequestUpdate, current_user: Any
    ) -> LessonRequestResponse:
        """Update a lesson request."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(request, key, value)
        await self.db.flush()
        await self.db.refresh(request)
        return LessonRequestResponse.model_validate(request)

    async def update_status(
        self, request_id: str, data: LessonRequestStatusUpdate, current_user: Any
    ) -> LessonRequestResponse:
        """Change lesson request status."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")

        request.status = data.status
        request.status_updated_at = datetime.now(timezone.utc)
        if data.decline_reason:
            request.decline_reason = data.decline_reason
        if data.proposal_id:
            request.proposal_id = data.proposal_id

        await self.db.flush()
        await self.db.refresh(request)
        return LessonRequestResponse.model_validate(request)

    async def delete(self, request_id: str, current_user: Any) -> None:
        """Delete a lesson request."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")
        await self.db.delete(request)
        await self.db.flush()

    async def process_expired(self) -> int:
        """Mark expired requests. Returns count of processed items."""
        from app.models.schedule import LessonRequest

        now = datetime.now(timezone.utc)
        result = await self.db.scalars(
            select(LessonRequest).where(
                LessonRequest.status == "pending",
                LessonRequest.expires_at <= now,
            )
        )
        count = 0
        for request in result.all():
            request.status = "expired"
            request.status_updated_at = now
            count += 1
        if count:
            await self.db.flush()
        return count
