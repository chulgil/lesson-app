"""Request event service — CRUD for lesson request chat history."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.request_event import RequestEvent, RequestEventType
from app.schemas.request_event import RequestEventCreate, RequestEventResponse


class RequestEventService:
    """Handle request event read/write operations."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_events_by_request_id(self, request_id: str, current_user: Any) -> list[RequestEventResponse]:
        """Return all events for a lesson request, ordered by created_at asc."""
        await self._check_request_access(request_id, current_user)

        result = await self.db.scalars(
            select(RequestEvent)
            .where(RequestEvent.request_id == request_id)
            .order_by(RequestEvent.created_at.asc(), RequestEvent.id.asc())
        )
        return [RequestEventResponse.model_validate(event) for event in result.all()]

    async def create_event(self, request_id: str, data: RequestEventCreate, current_user: Any) -> RequestEventResponse:
        """Create a new event for a lesson request."""
        await self._check_request_access(request_id, current_user)

        # Derive actor identity from the authenticated user — ignore client-supplied values.
        server_actor_id = current_user.id
        server_actor_type = self._actor_type(current_user)

        event = RequestEvent(
            request_id=request_id,
            actor_type=server_actor_type,
            actor_id=server_actor_id,
            event_type=RequestEventType(data.event_type),
            suggested_slots=([s.model_dump(mode="json") for s in data.suggested_slots] if data.suggested_slots else []),
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

    async def _check_request_access(self, request_id: str, current_user: Any) -> None:
        """Verify the lesson request exists and the user can access it."""
        from app.models.schedule import LessonRequest
        from app.services.teacher_id_resolver import try_resolve_teacher_id

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lesson request not found",
            )

        role = self._actor_type(current_user)
        if role == "student" and request.student_id == current_user.id:
            return
        if role == "teacher":
            identifiers = [current_user.id]
            teacher_profile_id = await try_resolve_teacher_id(self.db, current_user.id)
            if teacher_profile_id and teacher_profile_id not in identifiers:
                identifiers.append(teacher_profile_id)
            if request.teacher_id in identifiers:
                return

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    def _actor_type(self, user: Any) -> str:
        role = getattr(user, "role", None)
        return getattr(role, "value", role) or ""
