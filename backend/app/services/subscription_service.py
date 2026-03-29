"""Subscription service – subscriptions, templates, proposals."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.subscription import (
    ConfirmPaymentRequest,
    ProposalRespondRequest,
    SubscriptionCreate,
    SubscriptionProposalCreate,
    SubscriptionProposalResponse,
    SubscriptionResponse,
    SubscriptionTemplateCreate,
    SubscriptionTemplateResponse,
    SubscriptionTemplateUpdate,
    SubscriptionUpdate,
    UseLessonRequest,
)
from app.services.teacher_id_resolver import resolve_teacher_id


class SubscriptionService:
    """Handle subscription lifecycle, templates, and proposals."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Subscriptions
    # ------------------------------------------------------------------

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        student_id: str | None = None,
        membership_id: str | None = None,
        teacher_id: str | None = None,
        payment_confirmed: str | None = None,
        status: str | None = None,
    ) -> PaginatedResponse[SubscriptionResponse]:
        """List subscriptions with filters."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        query = select(Subscription)
        if student_id:
            query = query.where(Subscription.student_id == student_id)
        if membership_id:
            query = query.where(Subscription.membership_id == membership_id)
        if status:
            query = query.where(Subscription.status == status)
        if payment_confirmed is not None:
            confirmed = payment_confirmed.lower() not in ("false", "0", "no")
            query = query.where(Subscription.payment_confirmed == confirmed)
        if teacher_id:
            query = query.join(
                ClassMembership,
                Subscription.membership_id == ClassMembership.id,
            ).join(
                LessonClass,
                ClassMembership.lesson_class_id == LessonClass.id,
            ).where(LessonClass.teacher_id == teacher_id)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [SubscriptionResponse.model_validate(s) for s in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create(self, data: SubscriptionCreate, current_user: Any) -> SubscriptionResponse:
        """Create a new subscription."""
        from app.models.subscription import Subscription

        sub = Subscription(
            student_id=data.student_id,
            membership_id=data.membership_id or "",
            type=data.type or "monthly",
            total_lessons=data.total_lessons,
            amount=data.amount or 0,
            start_date=data.start_date,
        )
        self.db.add(sub)
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def get_by_id(self, subscription_id: str, current_user: Any) -> SubscriptionResponse:
        """Return a subscription by ID."""
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        return SubscriptionResponse.model_validate(sub)

    async def update(
        self, subscription_id: str, data: SubscriptionUpdate, current_user: Any
    ) -> SubscriptionResponse:
        """Update a subscription."""
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(sub, key, value)
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def deduct_lesson(
        self, subscription_id: str, data: UseLessonRequest, current_user: Any
    ) -> SubscriptionResponse:
        """Deduct a lesson usage from a subscription."""
        from app.models.subscription import Subscription, SubscriptionUsage

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        remaining = (sub.total_lessons or 0) - (sub.used_lessons or 0)
        if sub.total_lessons is not None and remaining <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No remaining lessons",
            )

        # Record usage
        usage = SubscriptionUsage(
            subscription_id=subscription_id,
            lesson_id=data.lesson_id,
            type=data.type,
        )
        self.db.add(usage)

        # Update counters
        sub.used_lessons = (sub.used_lessons or 0) + 1

        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def use_reschedule(
        self, subscription_id: str, current_user: Any
    ) -> SubscriptionResponse:
        """Use a reschedule credit from a subscription."""
        from app.models.subscription import Subscription, SubscriptionUsage

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        usage = SubscriptionUsage(
            subscription_id=subscription_id,
            type="reschedule",
        )
        self.db.add(usage)
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def update_status(
        self, subscription_id: str, new_status: str, current_user: Any
    ) -> SubscriptionResponse:
        """Update subscription status."""
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        sub.status = new_status
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def get_usage_history(
        self, subscription_id: str, current_user: Any
    ) -> list:
        """Get usage history for a subscription."""
        from app.models.subscription import SubscriptionUsage

        result = await self.db.scalars(
            select(SubscriptionUsage)
            .where(SubscriptionUsage.subscription_id == subscription_id)
            .order_by(SubscriptionUsage.created_at.desc())
        )
        return list(result.all())

    async def add_usage(
        self, subscription_id: str, data: dict, current_user: Any
    ) -> Any:
        """Add a usage record to a subscription."""
        from app.models.subscription import Subscription, SubscriptionUsage

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        usage = SubscriptionUsage(
            subscription_id=subscription_id,
            lesson_id=data.get("lesson_id"),
            type=data.get("type", "lesson"),
        )
        self.db.add(usage)
        await self.db.flush()
        await self.db.refresh(usage)
        return usage

    async def confirm_payment(
        self, subscription_id: str, data: ConfirmPaymentRequest, current_user: Any
    ) -> SubscriptionResponse:
        """Mark a subscription as paid."""
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        sub.payment_confirmed = True
        if data.payment_method:
            sub.payment_method = data.payment_method
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    # ------------------------------------------------------------------
    # Templates
    # ------------------------------------------------------------------

    async def get_all_templates(self, current_user: Any) -> list[SubscriptionTemplateResponse]:
        """List active templates for the teacher."""
        from app.models.subscription import SubscriptionTemplate

        tid = await resolve_teacher_id(self.db, current_user.id)
        result = await self.db.scalars(
            select(SubscriptionTemplate).where(
                SubscriptionTemplate.teacher_id == tid,
                SubscriptionTemplate.is_active == True,  # noqa: E712
            )
        )
        return [SubscriptionTemplateResponse.model_validate(t) for t in result.all()]

    async def create_template(
        self, data: SubscriptionTemplateCreate, current_user: Any
    ) -> SubscriptionTemplateResponse:
        """Create a subscription template."""
        from app.models.subscription import SubscriptionTemplate

        tid = await resolve_teacher_id(self.db, current_user.id)
        template = SubscriptionTemplate(
            teacher_id=tid,
            name=data.name,
            type=data.type,
            lessons_count=data.lessons_count,
            amount=data.amount,
            description=data.description,
        )
        self.db.add(template)
        await self.db.flush()
        await self.db.refresh(template)
        return SubscriptionTemplateResponse.model_validate(template)

    async def update_template(
        self, template_id: str, data: SubscriptionTemplateUpdate, current_user: Any
    ) -> SubscriptionTemplateResponse:
        """Update a template."""
        from app.models.subscription import SubscriptionTemplate

        template = await self.db.get(SubscriptionTemplate, template_id)
        if template is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(template, key, value)
        await self.db.flush()
        await self.db.refresh(template)
        return SubscriptionTemplateResponse.model_validate(template)

    async def deactivate_template(self, template_id: str, current_user: Any) -> None:
        """Deactivate a template (soft delete)."""
        from app.models.subscription import SubscriptionTemplate

        template = await self.db.get(SubscriptionTemplate, template_id)
        if template is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")
        template.is_active = False
        await self.db.flush()

    # ------------------------------------------------------------------
    # Proposals
    # ------------------------------------------------------------------

    async def get_all_proposals(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        student_id: str | None = None,
        status: str | None = None,
    ) -> PaginatedResponse[SubscriptionProposalResponse]:
        """List proposals."""
        from app.models.subscription import SubscriptionProposal

        query = select(SubscriptionProposal)
        if student_id:
            query = query.where(SubscriptionProposal.student_id == student_id)
        if status:
            query = query.where(SubscriptionProposal.status == status)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [SubscriptionProposalResponse.model_validate(p) for p in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create_proposal(
        self, data: SubscriptionProposalCreate, current_user: Any
    ) -> SubscriptionProposalResponse:
        """Send a subscription proposal."""
        from datetime import datetime, timedelta, timezone

        from app.models.subscription import SubscriptionProposal

        tid = await resolve_teacher_id(self.db, current_user.id)
        proposal = SubscriptionProposal(
            teacher_id=tid,
            student_id=data.student_id,
            message=data.message,
            recommended_template_id=data.recommended_template_id,
            status="pending",
            expires_at=datetime.now(timezone.utc) + timedelta(days=7),
        )
        self.db.add(proposal)
        await self.db.flush()
        await self.db.refresh(proposal)
        return SubscriptionProposalResponse.model_validate(proposal)

    async def respond_to_proposal(
        self, proposal_id: str, data: ProposalRespondRequest, current_user: Any
    ) -> SubscriptionProposalResponse:
        """Accept or reject a proposal."""
        from app.models.subscription import SubscriptionProposal

        proposal = await self.db.get(SubscriptionProposal, proposal_id)
        if proposal is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposal not found")

        if data.action == "accept":
            proposal.status = "paymentNotified"
            proposal.selected_template_id = data.selected_template_id
        elif data.action == "reject":
            proposal.status = "rejected"
            proposal.rejection_reason = data.rejection_reason
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid action")

        await self.db.flush()
        await self.db.refresh(proposal)
        return SubscriptionProposalResponse.model_validate(proposal)

    async def confirm_proposal(
        self, proposal_id: str, current_user: Any
    ) -> SubscriptionProposalResponse:
        """Confirm a proposal after payment (creates the subscription)."""
        from app.models.subscription import SubscriptionProposal

        proposal = await self.db.get(SubscriptionProposal, proposal_id)
        if proposal is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposal not found")

        proposal.status = "confirmed"
        await self.db.flush()
        await self.db.refresh(proposal)
        return SubscriptionProposalResponse.model_validate(proposal)
