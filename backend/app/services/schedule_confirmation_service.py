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
            title=data.title,
            message=data.message,
            proposed_day=data.proposed_day,
            proposed_time=data.proposed_time,
            proposed_duration=data.proposed_duration,
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

        await self.db.flush()
        await self.db.refresh(card)
        return ScheduleConfirmationCardResponse.model_validate(card)

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

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
            return card.teacher_id == current_user.id
        if role == "student":
            return card.student_id == current_user.id
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
