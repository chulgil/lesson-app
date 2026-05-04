"""Schedule confirmation card service."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schedule_confirmation import (
    ScheduleConfirmationCardConfirm,
    ScheduleConfirmationCardCreate,
    ScheduleConfirmationCardResponse,
)


class ScheduleConfirmationService:
    """Handle schedule confirmation card lifecycle."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_card(
        self, data: ScheduleConfirmationCardCreate, current_user: Any
    ) -> ScheduleConfirmationCardResponse:
        """Teacher creates a schedule confirmation card for a student."""
        from app.models.policy import ScheduleConfirmationCard

        card = ScheduleConfirmationCard(
            student_id=data.student_id,
            teacher_id=current_user.id,
            subscription_id=data.subscription_id,
            lesson_request_id=data.lesson_request_id,
            card_type=data.card_type,
            instrument=data.instrument,
            title=data.title,
            message=data.message,
            proposed_day=data.proposed_day,
            proposed_time=data.proposed_time,
            proposed_duration=data.proposed_duration,
            proposed_slots=data.proposed_slots,
            total_lessons=data.total_lessons,
            expires_at=data.expires_at,
        )
        self.db.add(card)
        await self.db.flush()
        await self.db.refresh(card)
        return ScheduleConfirmationCardResponse.model_validate(card)

    async def get_cards(
        self,
        current_user: Any,
        *,
        student_id: str | None = None,
        card_status: str | None = None,
    ) -> list[ScheduleConfirmationCardResponse]:
        """List confirmation cards accessible to the current user."""
        from app.models.policy import ScheduleConfirmationCard

        query = select(ScheduleConfirmationCard)
        query = self._apply_access_filter(query, current_user)

        if student_id:
            query = query.where(ScheduleConfirmationCard.student_id == student_id)
        if card_status:
            query = query.where(ScheduleConfirmationCard.status == card_status)

        query = query.order_by(ScheduleConfirmationCard.created_at.desc())
        result = await self.db.scalars(query)
        return [
            ScheduleConfirmationCardResponse.model_validate(card)
            for card in result.all()
        ]

    async def get_card_by_id(
        self, card_id: str, current_user: Any
    ) -> ScheduleConfirmationCardResponse:
        """Return a single confirmation card by ID."""
        card = await self._get_card_for_user(card_id, current_user)
        return ScheduleConfirmationCardResponse.model_validate(card)

    async def confirm_card(
        self,
        card_id: str,
        data: ScheduleConfirmationCardConfirm,
        current_user: Any,
    ) -> ScheduleConfirmationCardResponse:
        """Student confirms or rejects a schedule confirmation card."""
        from app.models.policy import ConfirmationCardStatus

        card = await self._get_card_for_user(card_id, current_user)

        if card.status != ConfirmationCardStatus.pending:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Card is already {card.status.value}, cannot change status",
            )

        now = datetime.now(UTC)
        card.status = ConfirmationCardStatus(data.action)
        card.response_message = data.response_message
        card.responded_at = now

        # GAP-5: Create LessonBooking records when student confirms
        if data.action == "confirmed" and card.subscription_id:
            await self._create_bookings_for_subscription(card)

        await self.db.flush()
        await self.db.refresh(card)
        return ScheduleConfirmationCardResponse.model_validate(card)

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    async def _create_bookings_for_subscription(self, card: Any) -> None:
        """GAP-5: Create LessonBooking records based on subscription type."""
        import datetime as dt
        from datetime import timedelta

        from app.models.schedule import LessonBooking
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, card.subscription_id)
        if sub is None:
            return

        sub_type = sub.type.value if hasattr(sub.type, "value") else sub.type

        if sub_type == "trial":
            count = 1
            lesson_type = "trial"
        elif sub_type == "package":
            count = 1  # Package: book first lesson only
            lesson_type = "regular"
        else:  # monthly / regular
            count = sub.total_lessons or 4
            lesson_type = "regular"

        base_date = dt.date.today()
        proposed_day = int(card.proposed_day) if card.proposed_day else base_date.weekday()

        # Find next occurrence of proposed_day (0=Mon)
        days_ahead = proposed_day - base_date.weekday()
        if days_ahead <= 0:
            days_ahead += 7
        first_date = base_date + timedelta(days=days_ahead)

        for i in range(count):
            scheduled_date = first_date + timedelta(weeks=i)
            booking = LessonBooking(
                teacher_id=card.teacher_id,
                student_id=card.student_id,
                lesson_type=lesson_type,
                scheduled_date=scheduled_date,
                scheduled_time=card.proposed_time or "14:00",
                duration=card.proposed_duration or 60,
                instrument=card.instrument,
                status="confirmed",
            )
            self.db.add(booking)

    async def _get_card_for_user(self, card_id: str, current_user: Any) -> Any:
        from app.models.policy import ScheduleConfirmationCard

        card = await self.db.get(ScheduleConfirmationCard, card_id)
        if card is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Schedule confirmation card not found",
            )
        if not self._can_access(card, current_user):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Forbidden",
            )
        return card

    def _can_access(self, card: Any, current_user: Any) -> bool:
        role = self._actor_type(current_user)
        if role == "teacher":
            result: bool = card.teacher_id == current_user.id
            return result
        if role == "student":
            result2: bool = card.student_id == current_user.id
            return result2
        return False

    def _apply_access_filter(self, query: Any, current_user: Any) -> Any:
        from app.models.policy import ScheduleConfirmationCard

        role = self._actor_type(current_user)
        if role == "teacher":
            return query.where(ScheduleConfirmationCard.teacher_id == current_user.id)
        if role == "student":
            return query.where(ScheduleConfirmationCard.student_id == current_user.id)
        return query.where(False)

    def _actor_type(self, user: Any) -> str:
        role = getattr(user, "role", None)
        return getattr(role, "value", role) or ""
