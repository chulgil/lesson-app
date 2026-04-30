"""RequestEvent service — Plan A Phase 1 SSOT for lesson request chat history.

Mirrors frontend Hive `RequestEvent` (typeId 131). Replaces legacy
`LessonScheduleChange` (deprecated, see Plan A Phase 4 migration).
"""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.request_event import RequestEvent
from app.schemas.request_event import (
    RequestEventCreate,
    RequestEventResponse,
    RequestEventUpdate,
)


class RequestEventService:
    """Handle RequestEvent CRUD with permission checks against LessonRequest."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _assert_request_access(self, request_id: str, current_user: Any) -> None:
        """Verify current_user is teacher or student of the lesson request."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lesson request not found",
            )
        if current_user.id not in (request.teacher_id, request.student_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a participant of this lesson request",
            )

    async def create_event(
        self,
        request_id: str,
        data: RequestEventCreate,
        current_user: Any,
    ) -> RequestEventResponse:
        """Append a new event (chat message) to a lesson request."""
        await self._assert_request_access(request_id, current_user)

        if data.request_id != request_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="request_id in body does not match path",
            )
        if data.actor_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="actor_id must match current user",
            )

        event = RequestEvent(
            request_id=data.request_id,
            actor_type=data.actor_type,
            actor_id=data.actor_id,
            event_type=data.event_type,
            suggested_slots=[s.model_dump(mode="json") for s in data.suggested_slots] if data.suggested_slots else None,
            selected_slot_index=data.selected_slot_index,
            message=data.message,
            schedule_change_type=data.schedule_change_type,
            proposed_day_of_week=data.proposed_day_of_week,
            proposed_time=data.proposed_time,
            subscription_id=data.subscription_id,
            session_number=data.session_number,
        )
        self.db.add(event)
        await self.db.flush()
        await self.db.refresh(event)
        return RequestEventResponse.model_validate(event)

    async def list_events(
        self,
        request_id: str,
        current_user: Any,
    ) -> list[RequestEventResponse]:
        """List all events of a lesson request, oldest first."""
        await self._assert_request_access(request_id, current_user)

        result = await self.db.scalars(
            select(RequestEvent).where(RequestEvent.request_id == request_id).order_by(RequestEvent.created_at.asc())
        )
        return [RequestEventResponse.model_validate(e) for e in result.all()]

    async def get_event(self, event_id: str, current_user: Any) -> RequestEventResponse:
        """Return a single event by id (with access check)."""
        event = await self.db.get(RequestEvent, event_id)
        if event is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Request event not found",
            )
        await self._assert_request_access(event.request_id, current_user)
        return RequestEventResponse.model_validate(event)

    async def update_event(
        self,
        event_id: str,
        data: RequestEventUpdate,
        current_user: Any,
    ) -> RequestEventResponse:
        """Partially update an event (selected_slot_index, message)."""
        event = await self.db.get(RequestEvent, event_id)
        if event is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Request event not found",
            )
        await self._assert_request_access(event.request_id, current_user)

        if event.actor_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the actor can edit this event",
            )

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(event, key, value)
        await self.db.flush()
        await self.db.refresh(event)
        return RequestEventResponse.model_validate(event)
