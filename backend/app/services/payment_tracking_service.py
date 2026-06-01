"""Teacher payment-pending dashboard — #424.

Aggregates `SubscriptionProposal` rows in `pending` / `paymentNotified` status
that are still within the 7-day expiry window, with D+N computed at read time.
Also handles manual [재발송] (with a 30-minute cooldown) and [회수].
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.subscription import (
    ProposalStatus,
    SubscriptionProposal,
    SubscriptionTemplate,
)
from app.schemas.subscription import (
    PendingPaymentCountResponse,
    PendingPaymentResponse,
    PendingPaymentRow,
    SubscriptionProposalResponse,
)
from app.services.subscription_access_service import SubscriptionAccessService

logger = logging.getLogger(__name__)

RESEND_COOLDOWN_MINUTES = 30
ACTIVE_PROPOSAL_STATUSES = (ProposalStatus.pending, ProposalStatus.paymentNotified)


def _aware(value: datetime | None) -> datetime | None:
    """Treat sqlite-naive datetimes as UTC so arithmetic is consistent."""
    if value is None or value.tzinfo is not None:
        return value
    return value.replace(tzinfo=UTC)


class PaymentTrackingService:
    """Service for the teacher pending-payment dashboard (#424)."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.access = SubscriptionAccessService(db)

    # ------------------------------------------------------------------ aggregation

    async def list_pending(self, current_user: Any) -> PendingPaymentResponse:
        rows = await self._fetch_active_proposals(current_user)
        now = datetime.now(UTC)
        materialised = [await self._to_row(p, now) for p in rows]
        materialised.sort(key=lambda r: r.days_since_sent, reverse=True)
        return PendingPaymentResponse(pending=materialised, total_count=len(materialised))

    async def count_pending(self, current_user: Any) -> PendingPaymentCountResponse:
        teacher_ids = await self._require_teacher_ids(current_user)
        now = datetime.now(UTC)
        rows = await self.db.scalars(
            select(SubscriptionProposal.id).where(
                SubscriptionProposal.teacher_id.in_(teacher_ids),
                SubscriptionProposal.status.in_(ACTIVE_PROPOSAL_STATUSES),
                SubscriptionProposal.expires_at > now,
            )
        )
        return PendingPaymentCountResponse(count=len(rows.all()))

    # ------------------------------------------------------------------ actions

    async def resend(self, proposal_id: str, current_user: Any) -> dict[str, Any]:
        """Send a reminder push to the student. Cooldown: 30 minutes."""
        proposal = await self._require_teacher_proposal(proposal_id, current_user)

        if proposal.status not in ACTIVE_PROPOSAL_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Proposal is not awaiting payment",
            )

        now = datetime.now(UTC)
        last_sent = _aware(proposal.last_reminder_sent_at)
        if last_sent is not None and (now - last_sent) < timedelta(minutes=RESEND_COOLDOWN_MINUTES):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"재발송은 {RESEND_COOLDOWN_MINUTES}분에 한 번만 가능합니다. cooldown 안내",
            )

        proposal.last_reminder_sent_at = now
        await self.db.flush()
        return {"resent_at": now.isoformat(), "proposal_id": proposal.id}

    async def revoke(self, proposal_id: str, current_user: Any) -> SubscriptionProposalResponse:
        """Cancel a proposal (teacher's correction path)."""
        proposal = await self._require_teacher_proposal(proposal_id, current_user)

        if proposal.status not in ACTIVE_PROPOSAL_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only pending or paymentNotified proposals can be revoked",
            )

        proposal.status = ProposalStatus.cancelled
        await self.db.flush()
        await self.db.refresh(proposal)
        return SubscriptionProposalResponse.model_validate(proposal)

    # ------------------------------------------------------------------ internals

    async def _require_teacher_ids(self, current_user: Any) -> list[str]:
        if self.access.actor_type(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return await self.access.teacher_identifiers(current_user)

    async def _require_teacher_proposal(self, proposal_id: str, current_user: Any) -> SubscriptionProposal:
        teacher_ids = await self._require_teacher_ids(current_user)
        proposal = await self.db.get(SubscriptionProposal, proposal_id)
        if proposal is None or proposal.teacher_id not in teacher_ids:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposal not found")
        return proposal

    async def _fetch_active_proposals(self, current_user: Any) -> list[SubscriptionProposal]:
        teacher_ids = await self._require_teacher_ids(current_user)
        now = datetime.now(UTC)
        result = await self.db.scalars(
            select(SubscriptionProposal).where(
                SubscriptionProposal.teacher_id.in_(teacher_ids),
                SubscriptionProposal.status.in_(ACTIVE_PROPOSAL_STATUSES),
                SubscriptionProposal.expires_at > now,
            )
        )
        return list(result.all())

    async def _to_row(self, proposal: SubscriptionProposal, now: datetime) -> PendingPaymentRow:
        student_name = await self._student_name(proposal.student_id)
        amount, lesson_count = await self._template_summary(proposal)
        created_at = _aware(proposal.created_at) or now
        days_since_sent = max(0, (now - created_at).days)
        last_sent = _aware(proposal.last_reminder_sent_at)
        can_resend = last_sent is None or (now - last_sent) >= timedelta(minutes=RESEND_COOLDOWN_MINUTES)
        return PendingPaymentRow(
            proposal_id=proposal.id,
            student_id=proposal.student_id,
            student_name=student_name,
            amount=amount,
            lesson_count=lesson_count,
            days_since_sent=days_since_sent,
            expires_at=_aware(proposal.expires_at) or now,
            last_reminder_sent_at=last_sent,
            can_resend=can_resend,
            status=proposal.status.value if hasattr(proposal.status, "value") else str(proposal.status),
        )

    async def _student_name(self, student_id: str) -> str:
        from app.models.student import Student

        student = await self.db.get(Student, student_id)
        return student.name if student else ""

    async def _template_summary(self, proposal: SubscriptionProposal) -> tuple[int, int | None]:
        template_id = proposal.selected_template_id or proposal.recommended_template_id or proposal.template_id
        if not template_id:
            return (0, None)
        template = await self.db.get(SubscriptionTemplate, template_id)
        if template is None:
            return (0, None)
        return (template.amount or 0, template.lessons_count)
