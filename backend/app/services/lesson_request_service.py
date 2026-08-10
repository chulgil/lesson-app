"""Lesson request service — unified lesson request lifecycle."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
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
from app.services.actor import actor_type

# Statuses from which no further transitions are allowed.
TERMINAL_STATUSES: frozenset[str] = frozenset({"cancelled", "expired", "completed"})


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

        result = await self.db.scalars(query.order_by(LessonRequest.created_at.desc()).offset(offset).limit(size))
        items = [await self._to_response(r) for r in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def _match_price(self, teacher_id: str, instrument: str | None, experience_level: str | None) -> int | None:
        """Match price from teacher's lesson_price_table for instrument × level."""
        from app.models.settings import TeacherSettings

        if not instrument or not experience_level:
            return None

        result = await self.db.scalars(select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id))
        settings = result.first()
        if settings is None or settings.lesson_price_table is None:
            return None

        instrument_prices = settings.lesson_price_table.get(instrument)
        if instrument_prices is None:
            return None

        matched_price: int | None = instrument_prices.get(experience_level)
        return matched_price

    async def create(self, data: LessonRequestCreate, current_user: Any) -> LessonRequestResponse:
        """Create a unified lesson request."""
        from app.models.schedule import LessonRequest

        preferred_slots = [slot.model_dump(mode="json") for slot in data.preferred_slots]
        primary_slot = preferred_slots[0] if preferred_slots else None
        preferred_day = data.preferred_day
        preferred_time = data.preferred_time
        if primary_slot:
            preferred_day = preferred_day if preferred_day is not None else primary_slot.get("day_of_week")
            preferred_time = preferred_time or primary_slot.get("start_time")

        # Auto-match price from teacher's price table
        suggested_price = await self._match_price(data.teacher_id, data.instrument, data.experience_level)

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
            # spec §18 — 학생 신청 시 희망 장소 (수강권 발급 디폴트 전달용).
            preferred_location_type=data.preferred_location_type,
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

        # #1207 — a new request otherwise reaches the teacher only when they refresh
        # the list. Emit the teacher's inbox row (new type lessonRequestReceived).
        await self._notify_counterparty(
            request,
            current_user,
            notification_type="lessonRequestReceived",
            title="새 레슨 신청",
            body="학생이 레슨을 신청했어요. 확인 후 시간을 조율해주세요.",
        )

        # Auto-create subscription proposal if teacher has auto_proposal_enabled
        if request.request_type != "trial":
            await self._try_auto_proposal(request, current_user)

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
        from app.models.request_event import RequestEvent, RequestEventType, ScheduleChangeType

        if data.request_id != request_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Event request_id must match path request_id",
            )

        request = await self._get_request_for_user(request_id, current_user)
        suggested_slots = [slot.model_dump(mode="json") for slot in data.suggested_slots]
        event_type = RequestEventType(data.event_type)
        schedule_change_type = (
            ScheduleChangeType(data.schedule_change_type) if data.schedule_change_type is not None else None
        )
        proposed_day_of_week = data.proposed_day_of_week
        proposed_time = data.proposed_time
        selected_slot_index = data.selected_slot_index

        terminal_replay_types = {
            RequestEventType.scheduleChangeAccepted,
            RequestEventType.withdrawApproval,
        }
        if event_type in terminal_replay_types and not suggested_slots:
            source = await self._latest_schedule_change_source_event(
                request_id=request_id,
                subscription_id=data.subscription_id,
                session_number=data.session_number,
                include_accepted=event_type == RequestEventType.withdrawApproval,
            )
            if source is not None:
                suggested_slots = list(source.suggested_slots or [])
                schedule_change_type = schedule_change_type or source.schedule_change_type
                if selected_slot_index is None:
                    selected_slot_index = source.selected_slot_index
                if proposed_day_of_week is None:
                    proposed_day_of_week = source.proposed_day_of_week
                proposed_time = proposed_time or source.proposed_time

        # Derive actor identity from the authenticated user — ignore client-supplied values.
        server_actor_id = current_user.id
        server_actor_type = actor_type(current_user)

        event = RequestEvent(
            request_id=request_id,
            actor_type=server_actor_type,
            actor_id=server_actor_id,
            event_type=event_type,
            suggested_slots=suggested_slots,
            selected_slot_index=selected_slot_index,
            message=data.message,
            schedule_change_type=schedule_change_type,
            proposed_day_of_week=proposed_day_of_week,
            proposed_time=proposed_time,
            subscription_id=data.subscription_id,
            session_number=data.session_number,
            change_credit_used=data.change_credit_used,
            change_credit_remaining_after=data.change_credit_remaining_after,
            keeps_session_number=data.keeps_session_number,
        )
        self.db.add(event)
        await self.db.flush()
        await self.db.refresh(event)
        # #1192 — accepting a confirmed-lesson schedule change must move the actual
        # Lesson rows (calendar SSOT), not just record the timeline event.
        if event_type == RequestEventType.scheduleChangeAccepted:
            await self._apply_schedule_change_to_lessons(request, event)
            # #1207 — the Lesson rows move, but the proposer (counterparty) only
            # learned via a same-device local notification. Notify them the change
            # was accepted. Placed after the move so a 409 conflict skips the emit.
            await self._notify_counterparty(
                request,
                current_user,
                notification_type="scheduleChangeApproved",
                title="일정 변경 수락",
                body="상대방이 일정 변경을 수락했어요. 레슨 시간이 변경되었습니다.",
            )
        return RequestEventResponse.model_validate(event)

    @staticmethod
    def _resolve_schedule_change_slot(event: Any) -> tuple[int | None, str | None]:
        """Resolve the (day_of_week, start_time) an accepted change moves lessons to.

        Prefers the selected suggested slot; falls back to the proposed day/time.
        """
        slots = event.suggested_slots or []
        index = event.selected_slot_index if event.selected_slot_index is not None else 0
        if slots and 0 <= index < len(slots):
            slot = slots[index]
            day = slot.get("day_of_week") if isinstance(slot, dict) else getattr(slot, "day_of_week", None)
            time = slot.get("start_time") if isinstance(slot, dict) else getattr(slot, "start_time", None)
            if day is not None and time:
                return day, time
        return event.proposed_day_of_week, event.proposed_time

    async def _apply_schedule_change_to_lessons(self, request: Any, event: Any) -> None:
        """#1192 — move confirmed Lesson rows when a schedule change is accepted.

        Without this, `add_event` only recorded a timeline event, so the weekly/
        daily calendar (Lesson SSOT) and conflict ledger (LessonBooking) kept the
        old time even after both parties agreed → no-show risk.

        - single: the next upcoming confirmed lesson shifts to the new weekday+time
          within its own week (nearest future occurrence, no past dates).
        - bulk: every future confirmed lesson shifts to the new weekday+time.
        - a collision with another booking at the new slot aborts the accept
          (409) before any row is mutated — safe, per the #1192 design.
        """
        import datetime as dt

        from app.models.lesson import Lesson
        from app.models.request_event import ScheduleChangeType
        from app.models.schedule import BookingStatus, LessonBooking
        from app.models.subscription import SubscriptionProposal

        new_day, new_time = self._resolve_schedule_change_slot(event)
        if new_day is None or not new_time:
            return

        # request → proposal → subscription_id (the link lives on the proposal).
        subscription_id = await self.db.scalar(
            select(SubscriptionProposal.subscription_id)
            .where(
                SubscriptionProposal.lesson_request_id == request.id,
                SubscriptionProposal.subscription_id.is_not(None),
            )
            .order_by(SubscriptionProposal.id.desc())
        )
        if subscription_id is None:
            return

        # KST calendar date — server-local date.today() (UTC in deployment)
        # lags a day behind between 00:00-09:00 KST, shifting which lessons a
        # schedule change applies to.
        from app.services.cancellation_policy import KST

        today = datetime.now(UTC).astimezone(KST).date()
        lessons = list(
            (
                await self.db.scalars(
                    select(Lesson)
                    .where(
                        Lesson.subscription_id == subscription_id,
                        Lesson.date >= today,
                        Lesson.status == "scheduled",
                        Lesson.is_archived == False,  # noqa: E712
                    )
                    .order_by(Lesson.date.asc(), Lesson.start_time.asc())
                )
            ).all()
        )
        if not lessons:
            return

        change_type = getattr(event.schedule_change_type, "value", event.schedule_change_type)
        is_bulk = change_type == ScheduleChangeType.bulkChange.value
        targets = lessons if is_bulk else lessons[:1]

        moves: list[tuple[Any, dt.date]] = [
            (lesson, lesson.date + dt.timedelta(days=(new_day - lesson.date.weekday()) % 7)) for lesson in targets
        ]

        active_booking_statuses = [
            BookingStatus.pending,
            BookingStatus.confirmed,
            BookingStatus.changeRequested,
        ]

        # Conflict-check every move first so a collision aborts atomically
        # (reject the accept) before any row is mutated.
        for lesson, new_date in moves:
            conflict = await self.db.scalar(
                select(LessonBooking.id).where(
                    LessonBooking.teacher_id == lesson.teacher_id,
                    LessonBooking.scheduled_date == new_date,
                    LessonBooking.scheduled_time == new_time,
                    LessonBooking.subscription_id != subscription_id,
                    LessonBooking.status.in_(active_booking_statuses),
                )
            )
            if conflict is not None:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Schedule change conflicts with an existing booking at the new time.",
                )

        for lesson, new_date in moves:
            old_date, old_time = lesson.date, lesson.start_time
            lesson.date = new_date
            lesson.start_time = new_time
            booking = await self.db.scalar(
                select(LessonBooking).where(
                    LessonBooking.subscription_id == subscription_id,
                    LessonBooking.teacher_id == lesson.teacher_id,
                    LessonBooking.scheduled_date == old_date,
                    LessonBooking.scheduled_time == old_time,
                    LessonBooking.status.in_(active_booking_statuses),
                )
            )
            if booking is not None:
                booking.scheduled_date = new_date
                booking.scheduled_time = new_time
        await self.db.flush()

    async def update(self, request_id: str, data: LessonRequestUpdate, current_user: Any) -> LessonRequestResponse:
        """Update a lesson request."""
        request = await self._get_request_for_user(request_id, current_user)

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            if key == "preferred_slots" and value is not None:
                value = [slot.model_dump(mode="json") if hasattr(slot, "model_dump") else slot for slot in value]
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
        canonical_status = self._canonical_request_status(data.status)

        # Guard: terminal states (cancelled/expired/completed) are irreversible.
        if request.status in TERMINAL_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot transition from terminal status '{request.status}'",
            )

        # Idempotent reentry guard — re-submitting the current status (e.g. a
        # double-tapped approve) must not re-emit RequestEvent rows and
        # counterpart notifications.
        if canonical_status == request.status:
            return await self._to_response(request)

        # Approval / proposal / subscription-issuing transitions are teacher-only.
        # Students may only cancel/withdraw or progress their own payment side.
        if canonical_status in self._TEACHER_ONLY_STATUSES:
            self._require_actor(current_user, "teacher")
        request.status = canonical_status
        request.status_updated_at = now

        if data.decline_reason:
            request.decline_reason = data.decline_reason
        if data.proposal_id:
            request.proposal_id = data.proposal_id

        # Set timestamp based on status transition
        if canonical_status == "timeConfirmed":
            request.confirmed_at = now
        elif canonical_status == "pending":
            # Withdraw approval — reset confirmed_at
            request.confirmed_at = None
        elif canonical_status == "cancelled":
            request.cancelled_at = now

        await self._add_event(
            request_id=request.id,
            actor_type=actor_type(current_user),
            actor_id=current_user.id,
            event_type=self._event_type_for_status(data.status),
            message=data.decline_reason,
            subscription_id=(data.proposal_id if canonical_status in ("proposalSent", "subscriptionIssued") else None),
        )
        # #1207 — teacher approve/reject is the happy-path confirmation the student
        # otherwise never actively learns about (FE local notifications render only
        # on the actor's own device). Emit the counterpart row on these two.
        if canonical_status == "timeConfirmed":
            await self._notify_counterparty(
                request,
                current_user,
                notification_type="scheduleChangeApproved",
                title="레슨 신청 승인",
                body="선생님이 레슨 신청을 승인했어요. 레슨 시간이 확정되었습니다.",
            )
        elif canonical_status == "rejected":
            await self._notify_counterparty(
                request,
                current_user,
                notification_type="scheduleChangeRejected",
                title="레슨 신청 거절",
                body="선생님이 레슨 신청을 거절했어요. 다른 시간을 제안해보세요.",
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
        await self._notify_counterparty(
            request,
            current_user,
            notification_type="scheduleChangeAlternative",
            title="대안 시간 제안",
            body="선생님이 레슨 시간 대안을 제안했어요. 확인 후 선택해주세요.",
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
        await self._notify_counterparty(
            request,
            current_user,
            notification_type="scheduleChangeApproved",
            title="제안 시간 수락",
            body="학생이 제안 시간을 수락했어요. 레슨 시간이 확정되었습니다.",
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
        await self._notify_counterparty(
            request,
            current_user,
            notification_type="scheduleChangeRequested",
            title="다른 시간 제안",
            body="학생이 다른 레슨 시간을 제안했어요. 확인해주세요.",
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

    async def _latest_schedule_change_source_event(
        self,
        *,
        request_id: str,
        subscription_id: str | None,
        session_number: int | None,
        include_accepted: bool = False,
    ) -> Any | None:
        """Find the latest schedule-change proposal/request whose slots must be replayed."""
        from app.models.request_event import RequestEvent, RequestEventType

        event_types = [
            RequestEventType.scheduleChanged,
            RequestEventType.scheduleChangeProposed,
            RequestEventType.scheduleChangeCountered,
        ]
        if include_accepted:
            event_types.append(RequestEventType.scheduleChangeAccepted)

        query = select(RequestEvent).where(
            RequestEvent.request_id == request_id,
            RequestEvent.event_type.in_(event_types),
        )
        if subscription_id is not None:
            query = query.where(RequestEvent.subscription_id == subscription_id)
        if session_number is not None:
            query = query.where(RequestEvent.session_number == session_number)

        result = await self.db.scalars(query.order_by(RequestEvent.created_at.desc(), RequestEvent.id.desc()))
        return result.first()

    # Canonical statuses that only a teacher may set (approval / proposal /
    # subscription-issuing / progression). Cancellation/withdrawal and the
    # student-side payment-notify/proposal-accept transitions stay allowed.
    _TEACHER_ONLY_STATUSES = frozenset(
        {
            "timeConfirmed",
            "rejected",
            "proposalSent",
            "subscriptionIssued",
            "inProgress",
            "completed",
        }
    )

    def _canonical_request_status(self, request_status: str) -> str:
        """Normalize legacy status names to the current UnifiedRequestStatus SSOT."""
        if request_status == "approved":
            return "timeConfirmed"
        return request_status

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
            items=[LessonRequestCalendarItem(day_of_week=int(day), count=int(count)) for day, count in rows]
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

    async def _try_auto_proposal(self, request: Any, current_user: Any) -> None:
        """Auto-create subscription proposal if teacher has auto_proposal_enabled."""
        from app.models.settings import ProposalSettings

        settings = await self.db.scalar(
            select(ProposalSettings).where(ProposalSettings.teacher_id == request.teacher_id)
        )
        if settings is None or not settings.auto_proposal_enabled:
            return

        # Use recommended template or first from auto list
        template_id = settings.recommended_template_id
        if not template_id and settings.auto_proposal_template_ids:
            template_id = settings.auto_proposal_template_ids[0]
        if not template_id:
            return  # No template configured

        from app.models.subscription import SubscriptionProposal

        proposal = SubscriptionProposal(
            teacher_id=request.teacher_id,
            student_id=request.student_id,
            recommended_template_id=template_id,
            lesson_request_id=request.id,
            is_auto_proposal=True,
            status="pending",
            expires_at=datetime.now(UTC) + timedelta(days=7),
        )
        self.db.add(proposal)
        await self.db.flush()

        # Link back to request
        request.proposal_id = proposal.id
        await self.db.flush()

    async def _to_response(self, request: Any) -> LessonRequestResponse:
        events = await self._get_events(request.id)
        response = LessonRequestResponse.model_validate(request)
        response.type = request.request_type
        response.experience = request.experience_level
        response.events = [RequestEventResponse.model_validate(event) for event in events]  # type: ignore[misc]
        student_name, teacher_name, academy_name = await self._resolve_display_names(request)
        response.student_name = student_name
        response.teacher_name = teacher_name
        response.academy_name = academy_name
        return response

    async def _resolve_display_names(self, request: Any) -> tuple[str | None, str | None, str | None]:
        """Resolve student/teacher/academy display names from ids on the row.

        Best-effort — unresolved ids yield None so the client can fall back to
        its local name map. ``student_id`` is the requesting student's User.id;
        ``teacher_id`` may be a Teacher profile id or a User.id.
        """
        from app.models.academy import Academy
        from app.models.student import Student
        from app.models.teacher import Teacher
        from app.models.user import User

        # Student: prefer the roster name a teacher recognizes, else the User name.
        student_name = await self.db.scalar(select(Student.name).where(Student.user_id == request.student_id))
        if student_name is None:
            student_name = await self.db.scalar(select(User.name).where(User.id == request.student_id))

        # Teacher: mirror displayName = nickname ?? name.
        teacher = (
            await self.db.scalars(
                select(Teacher).where(or_(Teacher.id == request.teacher_id, Teacher.user_id == request.teacher_id))
            )
        ).first()
        if teacher is not None:
            teacher_name = teacher.nickname or await self.db.scalar(select(User.name).where(User.id == teacher.user_id))
        else:
            teacher_name = await self.db.scalar(select(User.name).where(User.id == request.teacher_id))

        academy_name: str | None = None
        if request.academy_id:
            academy_name = await self.db.scalar(select(Academy.name).where(Academy.id == request.academy_id))

        return student_name, teacher_name, academy_name

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

    async def _notify_counterparty(
        self,
        request: Any,
        current_user: Any,
        *,
        notification_type: str,
        title: str,
        body: str,
    ) -> None:
        """Create an in-app/push notification for the negotiation counterparty (#1193).

        FE local notifications only render on the actor's own device, so the
        counterpart learns about a transition only through this server row.
        ``request.student_id`` stores the student *user* id (see
        ``_can_access_request``); ``request.teacher_id`` may be a Teacher row
        id or a legacy user id, so resolve via the Teacher row with fallback.
        """
        from app.services.notification_recipient import (
            resolve_student_user_id,
            resolve_teacher_user_id,
        )
        from app.services.notification_service import NotificationPriority, NotificationService

        # Resolve to a real recipient User.id (FK-safe). ``request.student_id`` is a
        # user id; ``request.teacher_id`` may be a Teacher profile id. A recipient
        # that no longer maps to a real user yields None → skip emit rather than
        # break the primary transition on a Notification.user_id FK violation.
        if actor_type(current_user) == "teacher":
            recipient_user_id = await resolve_student_user_id(self.db, request.student_id)
        else:
            recipient_user_id = await resolve_teacher_user_id(self.db, request.teacher_id)

        if not recipient_user_id:
            return

        await NotificationService(self.db).create_and_send(
            user_id=recipient_user_id,
            notification_type=notification_type,
            title=title,
            body=body,
            priority=NotificationPriority.high,
            action_url=f"/schedule/request/{request.id}",
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
        role = actor_type(current_user)
        if role == "student":
            result: bool = request.student_id == current_user.id
            return result
        if role == "teacher":
            return bool(request.teacher_id in await self._teacher_identifiers(current_user.id))
        return False

    async def _apply_access_filter(self, query: Any, current_user: Any) -> Any:
        from app.models.schedule import LessonRequest

        role = actor_type(current_user)
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

    def _require_actor(self, user: Any, expected_role: str) -> None:
        if actor_type(user) != expected_role:
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
