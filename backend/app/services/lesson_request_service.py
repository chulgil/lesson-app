"""Lesson request service — unified lesson request lifecycle."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.lesson_request import (
    AlternativeAccept,
    LessonRequestAction,
    LessonRequestCalendarItem,
    LessonRequestCalendarResponse,
    LessonRequestCreate,
    LessonRequestResponse,
    LessonRequestStatusUpdate,
    LessonRequestUpdate,
    RequestEventResponse,
    TimeProposalCreate,
)
from app.schemas.request_event import RequestEventCreate


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
        query = await self._apply_access_filter(query, user)
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
        items = [await self._to_response(r) for r in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def _match_price(self, teacher_id: str, instrument: str | None, experience_level: str | None) -> int | None:
        """Match price from teacher's lesson_price_table for instrument × level."""
        from app.models.settings import TeacherSettings

        if not instrument or not experience_level:
            return None

        result = await self.db.scalars(
            select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id)
        )
        settings = result.first()
        if settings is None or settings.lesson_price_table is None:
            return None

        instrument_prices = settings.lesson_price_table.get(instrument)
        if instrument_prices is None:
            return None

        return instrument_prices.get(experience_level)

    async def create(self, data: LessonRequestCreate, current_user: Any) -> LessonRequestResponse:
        """Create a unified lesson request."""
        from app.models.schedule import LessonRequest

        preferred_slots = [
            slot.model_dump(mode="json") for slot in data.preferred_slots
        ]
        primary_slot = preferred_slots[0] if preferred_slots else None
        preferred_day = data.preferred_day
        preferred_time = data.preferred_time
        if primary_slot:
            preferred_day = preferred_day if preferred_day is not None else primary_slot.get("day_of_week")
            preferred_time = preferred_time or primary_slot.get("start_time")

        # Auto-match price from teacher's price table
        suggested_price = await self._match_price(
            data.teacher_id, data.instrument, data.experience_level
        )

        request = LessonRequest(
            student_id=current_user.id,
            teacher_id=data.teacher_id,
            message=data.message,
            # Unified fields
            request_type=data.request_type,
            instrument=data.instrument,
            goal=data.goal,
            experience_level=data.experience_level,
            preferred_day=preferred_day,
            preferred_time=preferred_time,
            preferred_duration=data.preferred_duration,
            preferred_slots=preferred_slots,
            is_returning_student=data.is_returning_student,
            suggested_price=suggested_price,
            # Legacy fields
            preferred_timing=data.preferred_timing,
            keep_previous_schedule=data.keep_previous_schedule,
            previous_lesson_day=data.previous_lesson_day,
            previous_lesson_time=data.previous_lesson_time,
            previous_lesson_duration=data.previous_lesson_duration,
            expires_at=datetime.now(UTC) + timedelta(days=14),
        )
        self.db.add(request)
        await self.db.flush()
        await self._add_event(
            request_id=request.id,
            actor_type="student",
            actor_id=current_user.id,
            event_type="initialRequest",
            suggested_slots=[
                {
                    "day_of_week": slot["day_of_week"],
                    "start_time": slot["start_time"],
                    "end_time": slot["end_time"],
                }
                for slot in preferred_slots
                if slot.get("day_of_week") is not None
            ],
            message=data.message,
        )
        await self.db.refresh(request)
        return await self._to_response(request)

    async def get_by_id(self, request_id: str, current_user: Any) -> LessonRequestResponse:
        """Return a single lesson request."""
        request = await self._get_request_for_user(request_id, current_user)
        return await self._to_response(request)

    async def get_events(self, request_id: str, current_user: Any) -> list[RequestEventResponse]:
        """Return request events for an accessible lesson request."""
        await self._get_request_for_user(request_id, current_user)
        events = await self._get_events(request_id)
        return [RequestEventResponse.model_validate(event) for event in events]

    async def add_event(
        self,
        request_id: str,
        data: RequestEventCreate,
        current_user: Any,
    ) -> RequestEventResponse:
        """Persist a request event sent by the remote frontend repository."""
        from app.models.request_event import RequestEvent

        if data.request_id != request_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Event request_id must match path request_id",
            )

        await self._get_request_for_user(request_id, current_user)
        event = RequestEvent(
            request_id=request_id,
            actor_type=data.actor_type,
            actor_id=data.actor_id,
            event_type=data.event_type,
            suggested_slots=[slot.model_dump() for slot in data.suggested_slots],
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

    async def update(
        self, request_id: str, data: LessonRequestUpdate, current_user: Any
    ) -> LessonRequestResponse:
        """Update a lesson request."""
        request = await self._get_request_for_user(request_id, current_user)

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            if key == "preferred_slots" and value is not None:
                value = [
                    slot.model_dump(mode="json") if hasattr(slot, "model_dump") else slot
                    for slot in value
                ]
            setattr(request, key, value)
        await self.db.flush()
        await self.db.refresh(request)
        return await self._to_response(request)

    async def update_status(
        self, request_id: str, data: LessonRequestStatusUpdate, current_user: Any
    ) -> LessonRequestResponse:
        """Change lesson request status."""
        request = await self._get_request_for_user(request_id, current_user)

        now = datetime.now(UTC)
        request.status = data.status
        request.status_updated_at = now

        if data.decline_reason:
            request.decline_reason = data.decline_reason
        if data.proposal_id:
            request.proposal_id = data.proposal_id

        # Set timestamp based on status transition
        if data.status == "approved" or data.status == "timeConfirmed":
            request.confirmed_at = now
        elif data.status == "pending":
            # Withdraw approval — reset confirmed_at
            request.confirmed_at = None
        elif data.status == "cancelled":
            request.cancelled_at = now

        await self._add_event(
            request_id=request.id,
            actor_type=self._actor_type(current_user),
            actor_id=current_user.id,
            event_type=self._event_type_for_status(data.status),
            message=data.decline_reason,
            subscription_id=(
                data.proposal_id
                if data.status in ("proposalSent", "subscriptionIssued")
                else None
            ),
        )
        await self.db.flush()
        await self.db.refresh(request)
        return await self._to_response(request)

    async def delete(self, request_id: str, current_user: Any) -> None:
        """Delete a lesson request."""
        request = await self._get_request_for_user(request_id, current_user)
        await self.db.delete(request)
        await self.db.flush()

    async def propose_alternatives(
        self, request_id: str, data: TimeProposalCreate, current_user: Any
    ) -> LessonRequestResponse:
        """Teacher proposes up to 3 alternative time slots."""
        request = await self._get_request_for_user(request_id, current_user)
        self._require_actor(current_user, "teacher")

        if request.status not in ("pending", "negotiating"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot propose alternatives for request in status: {request.status}",
            )

        if len(data.slots) < 1 or len(data.slots) > 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Teacher must propose 1-3 alternative slots",
            )

        max_rounds = 3
        current_round = request.current_round or 0
        if current_round >= max_rounds:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Maximum negotiation rounds reached",
            )

        now = datetime.now(UTC)
        proposals = list(request.time_proposals or [])

        # Prevent consecutive teacher proposals (must wait for student response)
        # Exception: first proposal on a pending request
        if proposals and proposals[-1].get("role") == "teacher":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Waiting for student response before proposing again",
            )

        proposal_entry = {
            "proposer_id": current_user.id,
            "role": "teacher",
            "action": "propose",
            "slots": [s.model_dump() for s in data.slots],
            "message": data.message,
            "created_at": now.isoformat(),
        }
        proposals.append(proposal_entry)

        request.time_proposals = proposals
        request.status = "negotiating"
        request.current_round = current_round + 1
        request.status_updated_at = now

        await self._add_event(
            request_id=request.id,
            actor_type="teacher",
            actor_id=current_user.id,
            event_type="proposeAlternative",
            suggested_slots=[s.model_dump() for s in data.slots],
            message=data.message,
        )
        await self.db.flush()
        await self.db.refresh(request)
        return await self._to_response(request)

    async def accept_alternative(
        self, request_id: str, data: AlternativeAccept, current_user: Any
    ) -> LessonRequestResponse:
        """Student accepts one of teacher's proposed alternative slots."""
        request = await self._get_request_for_user(request_id, current_user)
        self._require_actor(current_user, "student")

        if request.status != "negotiating":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Request is not in negotiating status",
            )

        proposals = list(request.time_proposals or [])
        teacher_proposals = [p for p in proposals if p.get("role") == "teacher"]
        if not teacher_proposals:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No teacher proposals to accept",
            )

        latest_teacher = teacher_proposals[-1]
        slots = latest_teacher.get("slots", [])
        if data.selected_slot_index < 0 or data.selected_slot_index >= len(slots):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid slot index",
            )

        now = datetime.now(UTC)
        selected_slot = slots[data.selected_slot_index]
        accept_entry = {
            "proposer_id": current_user.id,
            "role": "student",
            "action": "accept",
            "slots": [selected_slot],
            "message": data.message,
            "created_at": now.isoformat(),
        }
        proposals.append(accept_entry)

        request.time_proposals = proposals
        request.status = "timeConfirmed"
        request.confirmed_at = now
        request.status_updated_at = now
        request.preferred_day = selected_slot.get("day_of_week")
        request.preferred_time = selected_slot.get("start_time")

        await self._add_event(
            request_id=request.id,
            actor_type="student",
            actor_id=current_user.id,
            event_type="acceptAlternative",
            suggested_slots=[selected_slot],
            selected_slot_index=data.selected_slot_index,
            message=data.message,
        )
        await self.db.flush()
        await self.db.refresh(request)
        return await self._to_response(request)

    async def counter_propose(
        self, request_id: str, data: TimeProposalCreate, current_user: Any
    ) -> LessonRequestResponse:
        """Student counter-proposes a different time slot."""
        request = await self._get_request_for_user(request_id, current_user)
        self._require_actor(current_user, "student")

        if request.status != "negotiating":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Request is not in negotiating status",
            )

        if len(data.slots) != 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Student must counter-propose exactly 1 slot",
            )

        # Prevent consecutive student proposals (must wait for teacher response)
        proposals = list(request.time_proposals or [])
        if proposals and proposals[-1].get("role") == "student":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Waiting for teacher response before counter-proposing again",
            )

        max_rounds = 3
        current_round = request.current_round or 0
        if current_round >= max_rounds:
            # Auto-expire
            now = datetime.now(UTC)
            request.status = "expired"
            request.status_updated_at = now
            await self._add_event(
                request_id=request.id,
                actor_type="system",
                actor_id="system",
                event_type="expire",
            )
            await self.db.flush()
            await self.db.refresh(request)
            return await self._to_response(request)

        now = datetime.now(UTC)
        proposals = list(request.time_proposals or [])
        counter_entry = {
            "proposer_id": current_user.id,
            "role": "student",
            "action": "counterPropose",
            "slots": [s.model_dump() for s in data.slots],
            "message": data.message,
            "created_at": now.isoformat(),
        }
        proposals.append(counter_entry)

        request.time_proposals = proposals
        request.status_updated_at = now

        await self._add_event(
            request_id=request.id,
            actor_type="student",
            actor_id=current_user.id,
            event_type="counterPropose",
            suggested_slots=[s.model_dump() for s in data.slots],
            message=data.message,
        )
        await self.db.flush()
        await self.db.refresh(request)
        return await self._to_response(request)

    async def apply_action(
        self, request_id: str, data: LessonRequestAction, current_user: Any
    ) -> LessonRequestResponse:
        """Apply the spec-defined unified lifecycle action."""
        if data.action == "approve":
            return await self.update_status(
                request_id,
                LessonRequestStatusUpdate(status="approved"),
                current_user,
            )
        if data.action == "reject":
            return await self.update_status(
                request_id,
                LessonRequestStatusUpdate(
                    status="rejected",
                    decline_reason=data.decline_reason or data.message,
                ),
                current_user,
            )
        if data.action == "cancel":
            return await self.update_status(
                request_id,
                LessonRequestStatusUpdate(status="cancelled"),
                current_user,
            )
        if data.action == "proposeAlternative":
            if not data.slots:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="slots are required")
            return await self.propose_alternatives(
                request_id,
                TimeProposalCreate(slots=data.slots, message=data.message),
                current_user,
            )
        if data.action == "counterPropose":
            if not data.slots:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="slots are required")
            return await self.counter_propose(
                request_id,
                TimeProposalCreate(slots=data.slots, message=data.message),
                current_user,
            )
        if data.action == "acceptAlternative":
            if data.selected_slot_index is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="selected_slot_index is required",
                )
            return await self.accept_alternative(
                request_id,
                AlternativeAccept(
                    selected_slot_index=data.selected_slot_index,
                    message=data.message,
                ),
                current_user,
            )
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported action")

    async def get_calendar(self, current_user: Any) -> LessonRequestCalendarResponse:
        """Return preferred-day counts for lesson requests visible to the user."""
        from app.models.schedule import LessonRequest

        query = (
            select(LessonRequest.preferred_day, func.count())
            .where(LessonRequest.preferred_day.is_not(None))
            .group_by(LessonRequest.preferred_day)
            .order_by(LessonRequest.preferred_day)
        )
        query = await self._apply_access_filter(query, current_user)
        rows = (await self.db.execute(query)).all()
        return LessonRequestCalendarResponse(
            items=[
                LessonRequestCalendarItem(day_of_week=int(day), count=int(count))
                for day, count in rows
            ]
        )

    async def process_expired(self) -> int:
        """Mark expired requests. Returns count of processed items."""
        from app.models.schedule import LessonRequest

        now = datetime.now(UTC)
        result = await self.db.scalars(
            select(LessonRequest).where(
                LessonRequest.status.in_(["pending", "negotiating"]),
                LessonRequest.expires_at <= now,
            )
        )
        count = 0
        for request in result.all():
            request.status = "expired"
            request.status_updated_at = now
            await self._add_event(
                request_id=request.id,
                actor_type="system",
                actor_id="system",
                event_type="expire",
            )
            count += 1
        if count:
            await self.db.flush()
        return count

    async def _to_response(self, request: Any) -> LessonRequestResponse:
        events = await self._get_events(request.id)
        response = LessonRequestResponse.model_validate(request)
        response.type = request.request_type
        response.experience = request.experience_level
        response.events = [RequestEventResponse.model_validate(event) for event in events]
        return response

    async def _get_events(self, request_id: str) -> list[Any]:
        from app.models.request_event import RequestEvent

        result = await self.db.scalars(
            select(RequestEvent)
            .where(RequestEvent.request_id == request_id)
            .order_by(RequestEvent.created_at.asc(), RequestEvent.id.asc())
        )
        return list(result.all())

    async def _add_event(
        self,
        *,
        request_id: str,
        actor_type: str,
        actor_id: str,
        event_type: str,
        suggested_slots: list | None = None,
        selected_slot_index: int | None = None,
        message: str | None = None,
        subscription_id: str | None = None,
    ) -> None:
        from app.models.request_event import RequestEvent, RequestEventType

        self.db.add(
            RequestEvent(
                request_id=request_id,
                actor_type=actor_type,
                actor_id=actor_id,
                event_type=RequestEventType(event_type),
                suggested_slots=suggested_slots or [],
                selected_slot_index=selected_slot_index,
                message=message,
                subscription_id=subscription_id,
            )
        )

    async def _get_request_for_user(self, request_id: str, current_user: Any) -> Any:
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")
        if not await self._can_access_request(request, current_user):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return request

    async def _can_access_request(self, request: Any, current_user: Any) -> bool:
        role = self._actor_type(current_user)
        if role == "student":
            return request.student_id == current_user.id
        if role == "teacher":
            return request.teacher_id in await self._teacher_identifiers(current_user.id)
        return False

    async def _apply_access_filter(self, query: Any, current_user: Any) -> Any:
        from app.models.schedule import LessonRequest

        role = self._actor_type(current_user)
        if role == "student":
            return query.where(LessonRequest.student_id == current_user.id)
        if role == "teacher":
            return query.where(LessonRequest.teacher_id.in_(await self._teacher_identifiers(current_user.id)))
        return query.where(False)

    async def _teacher_identifiers(self, user_id: str) -> list[str]:
        from app.services.teacher_id_resolver import try_resolve_teacher_id

        identifiers = [user_id]
        teacher_profile_id = await try_resolve_teacher_id(self.db, user_id)
        if teacher_profile_id and teacher_profile_id not in identifiers:
            identifiers.append(teacher_profile_id)
        return identifiers

    def _actor_type(self, user: Any) -> str:
        role = getattr(user, "role", None)
        return getattr(role, "value", role) or ""

    def _require_actor(self, user: Any, expected_role: str) -> None:
        if self._actor_type(user) != expected_role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    def _event_type_for_status(self, request_status: str) -> str:
        status_events = {
            "approved": "approve",
            "rejected": "reject",
            "pending": "withdrawApproval",
            "timeConfirmed": "acceptAlternative",
            "proposalSent": "proposalSent",
            "proposalAccepted": "proposalAccepted",
            "paymentNotified": "paymentNotified",
            "paymentConfirmed": "paymentConfirmed",
            "subscriptionIssued": "subscriptionIssued",
            "inProgress": "subscriptionIssued",
            "completed": "completed",
            "cancelled": "cancel",
            "expired": "expire",
        }
        return status_events.get(request_status, "message")
