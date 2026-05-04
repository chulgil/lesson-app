"""Subscription service – subscriptions, templates, proposals."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.request_event import RequestEventCreate, RequestEventResponse
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
from app.services.teacher_id_resolver import resolve_teacher_id, try_resolve_teacher_id


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
            query = (
                query.join(
                    ClassMembership,
                    Subscription.membership_id == ClassMembership.id,
                )
                .join(
                    LessonClass,
                    ClassMembership.lesson_class_id == LessonClass.id,
                )
                .where(LessonClass.teacher_id == teacher_id)
            )

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
            payment_confirmed=data.payment_confirmed,
            payment_method=data.payment_method,
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

    async def update(self, subscription_id: str, data: SubscriptionUpdate, current_user: Any) -> SubscriptionResponse:
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

    async def use_reschedule(self, subscription_id: str, current_user: Any) -> SubscriptionResponse:
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

    async def update_status(self, subscription_id: str, new_status: str, current_user: Any) -> SubscriptionResponse:
        """Update subscription status."""
        from app.models.subscription import Subscription, SubscriptionStatus

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        sub.status = SubscriptionStatus(new_status)
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def get_usage_history(self, subscription_id: str, current_user: Any) -> list:
        """Get usage history for a subscription."""
        from app.models.subscription import SubscriptionUsage

        result = await self.db.scalars(
            select(SubscriptionUsage)
            .where(SubscriptionUsage.subscription_id == subscription_id)
            .order_by(SubscriptionUsage.used_at.desc())
        )
        return list(result.all())

    async def add_usage(self, subscription_id: str, data: dict, current_user: Any) -> Any:
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

    async def get_events(
        self,
        subscription_id: str,
        current_user: Any,
        *,
        session_number: int | None = None,
    ) -> list[RequestEventResponse]:
        """Get subscription chat events, optionally scoped to one session."""
        from app.models.request_event import RequestEvent

        await self._get_subscription_for_user(subscription_id, current_user)

        query = (
            select(RequestEvent)
            .where(RequestEvent.subscription_id == subscription_id)
            .order_by(RequestEvent.created_at.asc(), RequestEvent.id.asc())
        )
        if session_number is not None:
            query = query.where(RequestEvent.session_number == session_number)

        result = await self.db.scalars(query)
        return [RequestEventResponse.model_validate(event) for event in result.all()]

    async def add_event(
        self,
        subscription_id: str,
        data: RequestEventCreate,
        current_user: Any,
    ) -> RequestEventResponse:
        """Persist a subscription chat event."""
        from app.models.request_event import RequestEvent

        await self._get_subscription_for_user(subscription_id, current_user)
        if data.subscription_id is not None and data.subscription_id != subscription_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Event subscription_id must match path subscription_id",
            )

        event = RequestEvent(
            request_id=data.request_id or subscription_id,
            actor_type=data.actor_type,
            actor_id=data.actor_id,
            event_type=data.event_type,
            suggested_slots=[slot.model_dump(mode="json") for slot in data.suggested_slots],
            selected_slot_index=data.selected_slot_index,
            message=data.message,
            schedule_change_type=data.schedule_change_type,
            proposed_day_of_week=data.proposed_day_of_week,
            proposed_time=data.proposed_time,
            subscription_id=subscription_id,
            session_number=data.session_number,
        )
        self.db.add(event)
        await self.db.flush()
        await self.db.refresh(event)
        return RequestEventResponse.model_validate(event)

    async def _get_subscription_for_user(self, subscription_id: str, current_user: Any) -> Any:
        """Return subscription if the current user can access it."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subscription not found",
            )

        role = self._actor_type(current_user)
        if role == "student" and sub.student_id == current_user.id:
            return sub

        if role == "teacher":
            identifiers = [current_user.id]
            teacher_profile_id = await try_resolve_teacher_id(self.db, current_user.id)
            if teacher_profile_id and teacher_profile_id not in identifiers:
                identifiers.append(teacher_profile_id)

            teacher_id = await self.db.scalar(
                select(LessonClass.teacher_id)
                .join(ClassMembership, ClassMembership.lesson_class_id == LessonClass.id)
                .where(ClassMembership.id == sub.membership_id)
            )
            if teacher_id in identifiers:
                return sub

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    def _actor_type(self, user: Any) -> str:
        role = getattr(user, "role", None)
        return getattr(role, "value", role) or ""

    async def confirm_payment(
        self, subscription_id: str, data: ConfirmPaymentRequest, current_user: Any
    ) -> SubscriptionResponse:
        """Confirm a manual tuition deposit."""
        from app.models.subscription import PaymentMethod, Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        sub.payment_confirmed = True
        sub.payment_confirmed_at = datetime.now(UTC)
        if data.payment_method:
            sub.payment_method = PaymentMethod(data.payment_method)
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
        from datetime import timedelta

        from app.models.subscription import SubscriptionProposal

        tid = await resolve_teacher_id(self.db, current_user.id)
        proposal = SubscriptionProposal(
            teacher_id=tid,
            student_id=data.student_id,
            message=data.message,
            recommended_template_id=data.recommended_template_id,
            lesson_request_id=data.lesson_request_id,
            status="pending",
            expires_at=datetime.now(UTC) + timedelta(days=7),
        )
        self.db.add(proposal)
        await self.db.flush()
        await self.db.refresh(proposal)

        # GAP-1: Link LessonRequest ↔ Proposal bidirectionally
        if data.lesson_request_id:
            await self._link_request_to_proposal(data.lesson_request_id, proposal.id)

        return SubscriptionProposalResponse.model_validate(proposal)

    async def respond_to_proposal(
        self, proposal_id: str, data: ProposalRespondRequest, current_user: Any
    ) -> SubscriptionProposalResponse:
        """Accept or reject a proposal."""
        from app.models.subscription import ProposalStatus, SubscriptionProposal

        proposal = await self.db.get(SubscriptionProposal, proposal_id)
        if proposal is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposal not found")

        if data.action in ("notify_payment", "accept"):
            proposal.status = ProposalStatus.paymentNotified
            proposal.payment_notified_at = datetime.now(UTC)
            proposal.selected_template_id = data.selected_template_id

            # GAP-6: Sync LessonRequest status → paymentNotified
            if proposal.lesson_request_id:
                await self._transition_request_status(proposal.lesson_request_id, "paymentNotified")
        elif data.action == "reject":
            proposal.status = ProposalStatus.rejected
            proposal.rejection_reason = data.rejection_reason
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid action")

        await self.db.flush()
        await self.db.refresh(proposal)
        return SubscriptionProposalResponse.model_validate(proposal)

    async def confirm_proposal(self, proposal_id: str, current_user: Any) -> SubscriptionProposalResponse:
        """Confirm a manual deposit and issue the subscription.

        Handles GAP-2 (membership), GAP-3 (relationship), GAP-4 (confirmation card),
        GAP-6 (request status transition) in addition to subscription creation.
        """
        from app.models.subscription import (
            PaymentMethod,
            ProposalPaymentStatus,
            ProposalStatus,
            Subscription,
            SubscriptionProposal,
            SubscriptionStatus,
            SubscriptionTemplate,
        )

        proposal = await self.db.get(SubscriptionProposal, proposal_id)
        if proposal is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposal not found")

        if proposal.status != "paymentNotified":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Proposal must be paymentNotified before confirmation",
            )

        now = datetime.now(UTC)
        if not proposal.subscription_id:
            # Resolve instrument from LessonRequest if linked
            instrument = None
            if proposal.lesson_request_id:
                from app.models.schedule import LessonRequest

                lr = await self.db.get(LessonRequest, proposal.lesson_request_id)
                if lr:
                    instrument = lr.instrument

            # GAP-2: Find or create ClassMembership
            membership_id = await self._find_or_create_membership(
                teacher_id=proposal.teacher_id,
                student_id=proposal.student_id,
                instrument=instrument,
            )

            template_id = proposal.selected_template_id or proposal.recommended_template_id or proposal.template_id
            template = await self.db.get(SubscriptionTemplate, template_id) if template_id else None
            sub = Subscription(
                student_id=proposal.student_id,
                membership_id=membership_id,
                type=template.type if template else "monthly",
                total_lessons=template.lessons_count if template else None,
                lessons_per_month=template.lessons_per_month if template else None,
                amount=template.amount if template else 0,
                status=SubscriptionStatus.active,
                payment_confirmed=True,
                payment_method=PaymentMethod.bankTransfer,
                paid_at=proposal.payment_notified_at or now,
                payment_confirmed_at=now,
                discount_amount=proposal.discount_amount,
                discount_reason=proposal.discount_reason,
            )
            self.db.add(sub)
            await self.db.flush()
            proposal.subscription_id = sub.id

            # GAP-3: Activate teacher-student relationship
            await self._activate_relationship(
                teacher_id=proposal.teacher_id,
                student_id=proposal.student_id,
                subscription_id=sub.id,
            )

            # GAP-4: Auto-create schedule confirmation card
            await self._create_confirmation_card(
                teacher_id=proposal.teacher_id,
                student_id=proposal.student_id,
                subscription_id=sub.id,
                lesson_request_id=proposal.lesson_request_id,
            )

        # GAP-6: Transition LessonRequest → subscriptionIssued
        if proposal.lesson_request_id:
            await self._transition_request_status(proposal.lesson_request_id, "subscriptionIssued")

        proposal.status = ProposalStatus.confirmed
        proposal.payment_status = ProposalPaymentStatus.completed
        proposal.confirmed_at = now
        await self.db.flush()
        await self.db.refresh(proposal)
        return SubscriptionProposalResponse.model_validate(proposal)

    # ------------------------------------------------------------------
    # Private helpers for the request→subscription integration
    # ------------------------------------------------------------------

    async def _link_request_to_proposal(self, lesson_request_id: str, proposal_id: str) -> None:
        """GAP-1: Set LessonRequest.proposal_id and transition to proposalSent."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, lesson_request_id)
        if request is None:
            return
        request.proposal_id = proposal_id
        request.status = "proposalSent"
        request.status_updated_at = datetime.now(UTC)
        await self.db.flush()

    async def _transition_request_status(self, lesson_request_id: str, new_status: str) -> None:
        """GAP-6: Update LessonRequest status as part of the subscription flow."""
        from app.models.schedule import LessonRequest

        request = await self.db.get(LessonRequest, lesson_request_id)
        if request is None:
            return
        request.status = new_status
        request.status_updated_at = datetime.now(UTC)
        await self.db.flush()

    async def _find_or_create_membership(
        self, teacher_id: str, student_id: str, instrument: str | None = None
    ) -> str:
        """GAP-2: Find existing ClassMembership or create one via a default private class."""
        from app.models.lesson import ClassMembership, LessonClass

        existing = await self.db.scalar(
            select(ClassMembership.id)
            .join(LessonClass, LessonClass.id == ClassMembership.lesson_class_id)
            .where(
                LessonClass.teacher_id == teacher_id,
                ClassMembership.student_id == student_id,
                ClassMembership.status.in_(["active", "trial"]),
            )
        )
        if existing:
            return existing

        default_class = await self.db.scalar(
            select(LessonClass).where(
                LessonClass.teacher_id == teacher_id,
                LessonClass.type == "private",
                LessonClass.is_archived == False,  # noqa: E712
            )
        )
        if default_class is None:
            default_class = LessonClass(
                teacher_id=teacher_id,
                name="개인 레슨",
                type="private",
            )
            self.db.add(default_class)
            await self.db.flush()
            await self.db.refresh(default_class)

        membership = ClassMembership(
            lesson_class_id=default_class.id,
            student_id=student_id,
            instrument=instrument or "",
            status="active",
        )
        self.db.add(membership)
        await self.db.flush()
        return membership.id

    async def _activate_relationship(
        self, teacher_id: str, student_id: str, subscription_id: str
    ) -> None:
        """GAP-3: Find TeacherStudentRelation and set to active with subscription link."""
        from app.models.relationship import RelationStatus, TeacherStudentRelation

        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id == teacher_id,
                TeacherStudentRelation.student_id == student_id,
            )
        )
        if relation is None:
            return
        relation.status = RelationStatus.active
        relation.active_subscription_id = subscription_id
        await self.db.flush()

    async def _create_confirmation_card(
        self,
        teacher_id: str,
        student_id: str,
        subscription_id: str,
        lesson_request_id: str | None,
    ) -> None:
        """GAP-4: Auto-create a ScheduleConfirmationCard after subscription issuance."""
        from app.models.policy import ScheduleConfirmationCard

        proposed_day: str | None = None
        proposed_time: str | None = None
        proposed_duration: int | None = None

        if lesson_request_id:
            from app.models.schedule import LessonRequest

            lr = await self.db.get(LessonRequest, lesson_request_id)
            if lr:
                proposed_day = str(lr.preferred_day) if lr.preferred_day is not None else None
                proposed_time = lr.preferred_time
                proposed_duration = lr.preferred_duration

        card = ScheduleConfirmationCard(
            student_id=student_id,
            teacher_id=teacher_id,
            subscription_id=subscription_id,
            title="수업 일정 확인",
            message="이 시간으로 예약할까요?",
            proposed_day=proposed_day,
            proposed_time=proposed_time,
            proposed_duration=proposed_duration,
        )
        self.db.add(card)
        await self.db.flush()
