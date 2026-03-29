"""Lesson request service — unified lesson request lifecycle."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.lesson_request import (
    AlternativeAccept,
    LessonRequestCreate,
    LessonRequestResponse,
    LessonRequestStatusUpdate,
    LessonRequestUpdate,
    TimeProposalCreate,
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
            preferred_day=data.preferred_day,
            preferred_time=data.preferred_time,
            preferred_duration=data.preferred_duration,
            is_returning_student=data.is_returning_student,
            suggested_price=suggested_price,
            # Legacy fields
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

        now = datetime.now(timezone.utc)
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

    async def propose_alternatives(
        self, request_id: str, data: TimeProposalCreate, current_user: Any
    ) -> LessonRequestResponse:
        """Teacher proposes up to 3 alternative time slots."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")

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

        now = datetime.now(timezone.utc)
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

        await self.db.flush()
        await self.db.refresh(request)
        return LessonRequestResponse.model_validate(request)

    async def accept_alternative(
        self, request_id: str, data: AlternativeAccept, current_user: Any
    ) -> LessonRequestResponse:
        """Student accepts one of teacher's proposed alternative slots."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")

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

        now = datetime.now(timezone.utc)
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

        await self.db.flush()
        await self.db.refresh(request)
        return LessonRequestResponse.model_validate(request)

    async def counter_propose(
        self, request_id: str, data: TimeProposalCreate, current_user: Any
    ) -> LessonRequestResponse:
        """Student counter-proposes a different time slot."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, request_id)
        if request is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson request not found")

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
            now = datetime.now(timezone.utc)
            request.status = "expired"
            request.status_updated_at = now
            await self.db.flush()
            await self.db.refresh(request)
            return LessonRequestResponse.model_validate(request)

        now = datetime.now(timezone.utc)
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

        await self.db.flush()
        await self.db.refresh(request)
        return LessonRequestResponse.model_validate(request)

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
