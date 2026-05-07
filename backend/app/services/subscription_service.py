"""Subscription service – subscriptions, templates, proposals."""

from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.request_event import RequestEventCreate, RequestEventResponse
from app.schemas.subscription import (
    ConfirmPaymentRequest,
    NotifyPaymentRequest,
    ProposalRespondRequest,
    SubscriptionCreate,
    SubscriptionDepositSummaryResponse,
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
        deposit_status: str | None = None,
        status: str | None = None,
    ) -> PaginatedResponse[SubscriptionResponse]:
        """List subscriptions with filters."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        query = select(Subscription)
        role = self._actor_type(user)
        if role == "student":
            query = query.where(Subscription.student_id.in_(await self._student_identifiers(user)))
        elif role == "parent":
            query = query.where(Subscription.student_id.in_(await self._parent_child_student_ids(user)))
        elif role == "teacher":
            identifiers = await self._teacher_identifiers(user)
            query = (
                query.join(
                    ClassMembership,
                    Subscription.membership_id == ClassMembership.id,
                )
                .join(
                    LessonClass,
                    ClassMembership.lesson_class_id == LessonClass.id,
                )
                .where(LessonClass.teacher_id.in_(identifiers))
            )
        else:
            query = query.where(False)

        if student_id:
            query = query.where(Subscription.student_id == student_id)
        if membership_id:
            query = query.where(Subscription.membership_id == membership_id)
        if status:
            query = query.where(Subscription.status == status)
        if payment_confirmed is not None:
            confirmed = payment_confirmed.lower() not in ("false", "0", "no")
            query = query.where(Subscription.payment_confirmed == confirmed)
        if deposit_status:
            if deposit_status == "unpaid":
                query = query.where(
                    Subscription.status == "active",
                    Subscription.payment_confirmed.is_(False),
                    Subscription.paid_at.is_(None),
                )
            elif deposit_status == "needsConfirmation":
                query = query.where(
                    Subscription.status == "active",
                    Subscription.payment_confirmed.is_(False),
                    Subscription.paid_at.is_not(None),
                )
            elif deposit_status == "confirmed":
                query = query.where(Subscription.payment_confirmed.is_(True))
            else:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid deposit_status",
                )
        if teacher_id:
            if role == "teacher":
                query = query.where(LessonClass.teacher_id == teacher_id)
            else:
                query = query.where(False)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [SubscriptionResponse.model_validate(s) for s in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_deposit_summary(
        self,
        *,
        user: Any,
        year: int | None = None,
        month: int | None = None,
    ) -> SubscriptionDepositSummaryResponse:
        """Summarize visible manual tuition deposit states."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        query = select(Subscription).where(Subscription.status == "active")
        role = self._actor_type(user)
        if role == "student":
            query = query.where(Subscription.student_id.in_(await self._student_identifiers(user)))
        elif role == "parent":
            query = query.where(Subscription.student_id.in_(await self._parent_child_student_ids(user)))
        elif role == "teacher":
            identifiers = await self._teacher_identifiers(user)
            query = (
                query.join(
                    ClassMembership,
                    Subscription.membership_id == ClassMembership.id,
                )
                .join(
                    LessonClass,
                    ClassMembership.lesson_class_id == LessonClass.id,
                )
                .where(LessonClass.teacher_id.in_(identifiers))
            )
        else:
            query = query.where(False)

        if year is not None and month is not None:
            start = date(year, month, 1)
            end = date(year + 1, 1, 1) if month == 12 else date(year, month + 1, 1)
            query = query.where(Subscription.start_date >= start, Subscription.start_date < end)
        elif year is not None:
            query = query.where(
                Subscription.start_date >= date(year, 1, 1),
                Subscription.start_date < date(year + 1, 1, 1),
            )

        subscriptions = (await self.db.scalars(query)).all()
        summary = SubscriptionDepositSummaryResponse(year=year, month=month)
        student_ids: set[str] = set()
        for sub in subscriptions:
            amount = sub.amount or 0
            summary.total_count += 1
            summary.total_amount += amount
            student_ids.add(sub.student_id)
            if sub.payment_confirmed:
                summary.confirmed_count += 1
                summary.confirmed_amount += amount
            elif sub.paid_at is not None:
                summary.needs_confirmation_count += 1
                summary.needs_confirmation_amount += amount
            else:
                summary.unpaid_count += 1
                summary.unpaid_amount += amount
        summary.student_count = len(student_ids)
        return summary

    async def create(self, data: SubscriptionCreate, current_user: Any) -> SubscriptionResponse:
        """Create a new subscription."""
        from app.models.subscription import Subscription

        membership_id = data.membership_id
        if membership_id:
            await self._get_subscription_membership_for_teacher(
                membership_id,
                current_user,
                student_id=data.student_id,
            )
        else:
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            membership_id = await self._find_or_create_membership(
                teacher_id=teacher_id,
                student_id=data.student_id,
            )

        sub = Subscription(
            student_id=data.student_id,
            membership_id=membership_id,
            type=data.type or "monthly",
            total_lessons=data.total_lessons,
            used_lessons=data.used_lessons,
            amount=data.amount or 0,
            start_date=data.start_date,
            end_date=data.end_date,
            status=data.status or "active",
            lessons_per_month=data.lessons_per_month,
            bonus_count=data.bonus_count,
            billing_type=data.billing_type,
            billing_day=data.billing_day,
            fifth_week_policy=data.fifth_week_policy,
            bonus_reason=data.bonus_reason,
            total_reschedule_allowance=data.total_reschedule_allowance,
            used_reschedule_count=data.used_reschedule_count,
            payment_confirmed=data.payment_confirmed,
            payment_method=data.payment_method,
            paid_at=data.paid_at,
            payment_confirmed_at=data.payment_confirmed_at,
            discount_amount=data.discount_amount,
            discount_reason=data.discount_reason,
            original_amount=data.original_amount,
            reschedule_deadline_hours=data.reschedule_deadline_hours,
        )
        self.db.add(sub)
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def get_by_id(self, subscription_id: str, current_user: Any) -> SubscriptionResponse:
        """Return a subscription by ID."""
        sub = await self._get_subscription_for_user(subscription_id, current_user)
        return SubscriptionResponse.model_validate(sub)

    async def update(self, subscription_id: str, data: SubscriptionUpdate, current_user: Any) -> SubscriptionResponse:
        """Update a subscription."""
        sub = await self._get_subscription_for_teacher(subscription_id, current_user)

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
        from app.models.subscription import SubscriptionUsage

        sub = await self._get_subscription_for_teacher(subscription_id, current_user)

        remaining = self._remaining_lessons(sub)
        if remaining is not None and remaining <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No remaining lessons",
            )

        # Record usage
        usage = SubscriptionUsage(
            subscription_id=subscription_id,
            lesson_id=data.lesson_id,
            type=data.type,
            teacher_name=data.teacher_name,
            instrument=data.instrument,
            note=data.note,
            deducted=data.deducted,
        )
        self.db.add(usage)

        # Update counters
        sub.used_lessons = (sub.used_lessons or 0) + 1

        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def use_reschedule(self, subscription_id: str, current_user: Any) -> SubscriptionResponse:
        """Use a reschedule credit from a subscription."""
        from app.models.subscription import SubscriptionUsage

        sub = await self._get_subscription_for_teacher(subscription_id, current_user)

        remaining = (sub.total_reschedule_allowance or 0) - (sub.used_reschedule_count or 0)
        if remaining <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No remaining reschedule credits",
            )

        usage = SubscriptionUsage(
            subscription_id=subscription_id,
            type="reschedule",
        )
        self.db.add(usage)
        sub.used_reschedule_count = (sub.used_reschedule_count or 0) + 1
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def update_status(self, subscription_id: str, new_status: str, current_user: Any) -> SubscriptionResponse:
        """Update subscription status."""
        from app.models.subscription import SubscriptionStatus

        sub = await self._get_subscription_for_teacher(subscription_id, current_user)

        sub.status = SubscriptionStatus(new_status)
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def get_usage_history(self, subscription_id: str, current_user: Any) -> list:
        """Get usage history for a subscription."""
        from app.models.subscription import SubscriptionUsage

        await self._get_subscription_for_user(subscription_id, current_user)
        result = await self.db.scalars(
            select(SubscriptionUsage)
            .where(SubscriptionUsage.subscription_id == subscription_id)
            .order_by(SubscriptionUsage.used_at.desc())
        )
        return list(result.all())

    async def add_usage(self, subscription_id: str, data: dict, current_user: Any) -> Any:
        """Add a usage record to a subscription."""
        from app.models.subscription import SubscriptionUsage

        await self._get_subscription_for_teacher(subscription_id, current_user)

        usage = SubscriptionUsage(
            subscription_id=subscription_id,
            lesson_id=data.get("lesson_id"),
            type=data.get("type", "lesson"),
            teacher_name=data.get("teacher_name"),
            instrument=data.get("instrument"),
            note=data.get("note"),
            deducted=data.get("deducted", True),
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

    async def get_pending_schedule_change_events(self, current_user: Any) -> list[RequestEventResponse]:
        """Return latest visible subscription schedule-change events requiring response."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.request_event import RequestEvent, RequestEventType
        from app.models.subscription import Subscription

        role = self._actor_type(current_user)
        source_types = {
            RequestEventType.lessonCancelled,
            RequestEventType.scheduleChanged,
            RequestEventType.scheduleChangeProposed,
            RequestEventType.scheduleChangeCountered,
        }
        terminal_types = {
            RequestEventType.scheduleChangeAccepted,
            RequestEventType.scheduleChangeRejected,
        }
        decision_types = source_types | terminal_types

        query = (
            select(RequestEvent)
            .join(Subscription, RequestEvent.subscription_id == Subscription.id)
            .where(
                RequestEvent.subscription_id.is_not(None),
                RequestEvent.event_type.in_(decision_types),
            )
        )

        if role == "teacher":
            identifiers = await self._teacher_identifiers(current_user)
            query = (
                query.join(
                    ClassMembership,
                    Subscription.membership_id == ClassMembership.id,
                )
                .join(
                    LessonClass,
                    ClassMembership.lesson_class_id == LessonClass.id,
                )
                .where(LessonClass.teacher_id.in_(identifiers))
            )
        elif role == "student":
            query = query.where(Subscription.student_id.in_(await self._student_identifiers(current_user)))
        elif role == "parent":
            query = query.where(Subscription.student_id.in_(await self._parent_child_student_ids(current_user)))
        else:
            query = query.where(False)

        result = await self.db.scalars(
            query.order_by(RequestEvent.created_at.desc(), RequestEvent.id.desc())
        )

        latest_by_session: dict[tuple[str, int | None], Any] = {}
        for event in result.all():
            if event.subscription_id is None:
                continue
            key = (event.subscription_id, event.session_number)
            latest_by_session.setdefault(key, event)

        pending = []
        for event in latest_by_session.values():
            if event.event_type not in source_types:
                continue
            if role in {"teacher", "student"} and event.actor_type == role:
                continue
            pending.append(event)

        pending.sort(key=lambda event: (event.created_at, event.id), reverse=True)
        return [RequestEventResponse.model_validate(event) for event in pending]

    async def add_event(
        self,
        subscription_id: str,
        data: RequestEventCreate,
        current_user: Any,
    ) -> RequestEventResponse:
        """Persist a subscription chat event."""
        from app.models.request_event import RequestEvent, RequestEventType, ScheduleChangeType

        sub = await self._get_subscription_for_user(subscription_id, current_user)
        self._validate_subscription_event_session_number(sub, data.session_number)
        await self._validate_subscription_event_turn(subscription_id, data, current_user)
        if data.subscription_id is not None and data.subscription_id != subscription_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Event subscription_id must match path subscription_id",
            )

        suggested_slots = [slot.model_dump(mode="json") for slot in data.suggested_slots]
        event_type = RequestEventType(data.event_type)
        schedule_change_type = (
            ScheduleChangeType(data.schedule_change_type)
            if data.schedule_change_type is not None
            else None
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
                request_id=data.request_id or subscription_id,
                subscription_id=subscription_id,
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

        event = RequestEvent(
            request_id=data.request_id or subscription_id,
            actor_type=data.actor_type,
            actor_id=data.actor_id,
            event_type=event_type,
            suggested_slots=suggested_slots,
            selected_slot_index=selected_slot_index,
            message=data.message,
            schedule_change_type=schedule_change_type,
            proposed_day_of_week=proposed_day_of_week,
            proposed_time=proposed_time,
            subscription_id=subscription_id,
            session_number=data.session_number,
            change_credit_used=data.change_credit_used,
            change_credit_remaining_after=data.change_credit_remaining_after,
            keeps_session_number=data.keeps_session_number,
        )
        self.db.add(event)
        await self.db.flush()
        await self.db.refresh(event)
        return RequestEventResponse.model_validate(event)

    async def _validate_subscription_event_turn(
        self,
        subscription_id: str,
        data: RequestEventCreate,
        current_user: Any,
    ) -> None:
        """Validate schedule-change event ordering for subscription sessions."""
        from app.models.request_event import RequestEvent, RequestEventType

        role = self._actor_type(current_user)
        if role == "parent":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

        event_type = RequestEventType(data.event_type)
        terminal_types = {
            RequestEventType.scheduleChangeAccepted,
            RequestEventType.scheduleChangeRejected,
        }
        pending_source_types = {
            RequestEventType.lessonCancelled,
            RequestEventType.scheduleChanged,
            RequestEventType.scheduleChangeProposed,
            RequestEventType.scheduleChangeCountered,
        }
        decision_types = pending_source_types | terminal_types

        if event_type not in terminal_types:
            return

        query = select(RequestEvent).where(
            RequestEvent.subscription_id == subscription_id,
            RequestEvent.event_type.in_(decision_types),
        )
        if data.session_number is not None:
            query = query.where(RequestEvent.session_number == data.session_number)

        latest = (
            await self.db.scalars(
                query.order_by(RequestEvent.created_at.desc(), RequestEvent.id.desc())
            )
        ).first()
        if latest is None or latest.event_type not in pending_source_types:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No pending schedule-change proposal",
            )
        if latest.actor_type == data.actor_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only the other party can respond to the schedule-change proposal",
            )

    def _validate_subscription_event_session_number(self, subscription: Any, session_number: int | None) -> None:
        """Ensure session-scoped events reference an actual subscription lesson."""
        if session_number is None:
            return
        if session_number < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="session_number must be greater than or equal to 1",
            )

        max_session = subscription.total_lessons
        bound_field = "total_lessons"
        if max_session is None:
            max_session = subscription.lessons_per_month
            bound_field = "lessons_per_month"
        if max_session is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="session_number requires subscription total_lessons or lessons_per_month",
            )
        if session_number > max_session:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"session_number must be less than or equal to subscription {bound_field}",
            )

    async def _latest_schedule_change_source_event(
        self,
        *,
        request_id: str,
        subscription_id: str,
        session_number: int | None,
        include_accepted: bool = False,
    ) -> Any | None:
        """Find the event that an accept/withdraw action is responding to."""
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
            RequestEvent.subscription_id == subscription_id,
            RequestEvent.event_type.in_(event_types),
        )
        if session_number is not None:
            query = query.where(RequestEvent.session_number == session_number)

        result = await self.db.scalars(query.order_by(RequestEvent.created_at.desc(), RequestEvent.id.desc()))
        return result.first()

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
        if role == "student":
            student_ids = await self._student_identifiers(current_user)
            if sub.student_id in student_ids:
                return sub
        elif role == "parent":
            student_ids = await self._parent_child_student_ids(current_user)
            if sub.student_id in student_ids:
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

    async def _teacher_identifiers(self, user: Any) -> list[str]:
        identifiers = [user.id]
        teacher_profile_id = await try_resolve_teacher_id(self.db, user.id)
        if teacher_profile_id and teacher_profile_id not in identifiers:
            identifiers.append(teacher_profile_id)
        return identifiers

    async def _student_identifiers(self, user: Any) -> list[str]:
        """Return user id plus linked Student profile ids for student actors."""
        from app.models.student import Student

        identifiers = [user.id]
        result = await self.db.scalars(select(Student.id).where(Student.user_id == user.id))
        for student_id in result.all():
            if student_id not in identifiers:
                identifiers.append(student_id)
        return identifiers

    async def _parent_child_student_ids(self, user: Any) -> list[str]:
        """Return active child Student ids for a parent user."""
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == user.id))
        if parent_id is None:
            return []

        result = await self.db.scalars(
            select(ParentChildRelation.student_id).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        return list(result.all())

    def _remaining_lessons(self, sub: Any) -> int | None:
        type_value = getattr(sub.type, "value", sub.type)
        if type_value == "trial":
            return 1 + (sub.bonus_count or 0) - (sub.used_lessons or 0)
        base = sub.total_lessons
        if base is None and type_value == "monthly":
            base = sub.lessons_per_month
        if base is None:
            return None
        return base + (sub.bonus_count or 0) - (sub.used_lessons or 0)

    async def _get_subscription_for_teacher(self, subscription_id: str, current_user: Any) -> Any:
        sub = await self._get_subscription_for_user(subscription_id, current_user)
        if self._actor_type(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return sub

    async def _get_subscription_membership_for_teacher(
        self,
        membership_id: str,
        current_user: Any,
        *,
        student_id: str | None = None,
    ) -> Any:
        from app.models.lesson import ClassMembership, LessonClass

        identifiers = await self._teacher_identifiers(current_user)
        membership = await self.db.scalar(
            select(ClassMembership)
            .join(LessonClass, ClassMembership.lesson_class_id == LessonClass.id)
            .where(
                ClassMembership.id == membership_id,
                LessonClass.teacher_id.in_(identifiers),
            )
        )
        if membership is None:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        if student_id is not None and membership.student_id != student_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="membership_id does not belong to student_id",
            )
        return membership

    async def confirm_payment(
        self, subscription_id: str, data: ConfirmPaymentRequest, current_user: Any
    ) -> SubscriptionResponse:
        """Confirm a manual tuition deposit."""
        from app.models.subscription import PaymentMethod

        sub = await self._get_subscription_for_teacher(subscription_id, current_user)
        sub.payment_confirmed = True
        if sub.paid_at is None:
            sub.paid_at = datetime.now(UTC)
        sub.payment_confirmed_at = datetime.now(UTC)
        if data.payment_method:
            sub.payment_method = PaymentMethod(data.payment_method)
        await self.db.flush()
        await self.db.refresh(sub)
        return SubscriptionResponse.model_validate(sub)

    async def notify_payment(
        self,
        subscription_id: str,
        data: NotifyPaymentRequest,
        current_user: Any,
    ) -> SubscriptionResponse:
        """Record that a student or parent reports an external tuition deposit."""
        from app.models.subscription import PaymentMethod

        sub = await self._get_subscription_for_user(subscription_id, current_user)
        if sub.payment_confirmed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment already confirmed",
            )
        if data.payment_method:
            sub.payment_method = PaymentMethod(data.payment_method)
        sub.paid_at = datetime.now(UTC)
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
            type=data.type or "package",
            lessons_count=data.lessons_count,
            lessons_per_month=data.lessons_per_month,
            duration_months=data.duration_months,
            lesson_duration_minutes=data.lesson_duration_minutes,
            validity_days=data.validity_days,
            amount=data.amount,
            description=data.description,
            display_order=data.display_order,
            reschedule_allowance=data.reschedule_allowance,
            is_auto_proposal_enabled=data.is_auto_proposal_enabled,
        )
        self.db.add(template)
        await self.db.flush()
        await self.db.refresh(template)
        return SubscriptionTemplateResponse.model_validate(template)

    async def get_template_by_id(self, template_id: str, current_user: Any) -> SubscriptionTemplateResponse:
        """Return one template by ID."""
        template = await self._get_template_for_teacher(template_id, current_user)
        return SubscriptionTemplateResponse.model_validate(template)

    async def update_template(
        self, template_id: str, data: SubscriptionTemplateUpdate, current_user: Any
    ) -> SubscriptionTemplateResponse:
        """Update a template."""
        template = await self._get_template_for_teacher(template_id, current_user)

        update_data = data.model_dump(exclude_unset=True)
        update_data.pop("owner_id", None)
        update_data.pop("owner_type", None)
        for key, value in update_data.items():
            setattr(template, key, value)
        await self.db.flush()
        await self.db.refresh(template)
        return SubscriptionTemplateResponse.model_validate(template)

    async def deactivate_template(self, template_id: str, current_user: Any) -> None:
        """Deactivate a template (soft delete)."""
        template = await self._get_template_for_teacher(template_id, current_user)
        template.is_active = False
        await self.db.flush()

    async def toggle_template_active(self, template_id: str, current_user: Any) -> SubscriptionTemplateResponse:
        """Toggle a template active flag."""
        template = await self._get_template_for_teacher(template_id, current_user)
        template.is_active = not template.is_active
        await self.db.flush()
        await self.db.refresh(template)
        return SubscriptionTemplateResponse.model_validate(template)

    async def reorder_templates(self, ordered_ids: list[str], current_user: Any) -> None:
        """Persist template display order for the current teacher."""
        from app.models.subscription import SubscriptionTemplate

        identifiers = await self._teacher_identifiers(current_user)
        for index, template_id in enumerate(ordered_ids):
            template = await self.db.get(SubscriptionTemplate, template_id)
            if template is not None:
                if template.teacher_id not in identifiers:
                    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
                template.display_order = index
        await self.db.flush()

    async def _get_template_for_teacher(self, template_id: str, current_user: Any) -> Any:
        """Return a template only if it belongs to the current teacher."""
        from app.models.subscription import SubscriptionTemplate

        template = await self.db.get(SubscriptionTemplate, template_id)
        if template is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")

        identifiers = await self._teacher_identifiers(current_user)
        if template.teacher_id not in identifiers:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return template

    # ------------------------------------------------------------------
    # Proposals
    # ------------------------------------------------------------------

    async def create_renewal_proposal(
        self,
        previous_subscription_id: str,
        current_user: Any,
        *,
        initiator: str = "teacher",
    ) -> SubscriptionProposalResponse:
        """Create a renewal proposal linked to the expiring/expired subscription."""
        from datetime import timedelta

        from app.models.subscription import SubscriptionProposal, SubscriptionTemplate

        sub = await self._get_subscription_for_teacher(previous_subscription_id, current_user)
        tid = await resolve_teacher_id(self.db, current_user.id)

        # Find a matching active template by teacher + subscription type
        template = await self.db.scalar(
            select(SubscriptionTemplate).where(
                SubscriptionTemplate.teacher_id == tid,
                SubscriptionTemplate.type == sub.type,
                SubscriptionTemplate.is_active == True,  # noqa: E712
            ).limit(1)
        )

        proposal = SubscriptionProposal(
            teacher_id=tid,
            student_id=sub.student_id,
            recommended_template_id=template.id if template else None,
            is_renewal=True,
            previous_subscription_id=previous_subscription_id,
            renewal_initiator=initiator,
            proposal_type="renewal",
            status="pending",
            expires_at=datetime.now(UTC) + timedelta(days=7),
        )
        self.db.add(proposal)
        await self.db.flush()
        await self.db.refresh(proposal)

        return SubscriptionProposalResponse.model_validate(proposal)

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
        role = self._actor_type(user)
        if role == "teacher":
            query = query.where(SubscriptionProposal.teacher_id.in_(await self._teacher_identifiers(user)))
        elif role == "student":
            query = query.where(SubscriptionProposal.student_id.in_(await self._student_identifiers(user)))
        else:
            query = query.where(False)
        if student_id:
            query = query.where(SubscriptionProposal.student_id == student_id)
        if status:
            query = query.where(SubscriptionProposal.status == status)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [SubscriptionProposalResponse.model_validate(p) for p in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_proposal_by_id(self, proposal_id: str, current_user: Any) -> SubscriptionProposalResponse:
        """Return one proposal by ID."""
        proposal = await self._get_proposal_for_user(proposal_id, current_user)
        return SubscriptionProposalResponse.model_validate(proposal)

    async def _get_proposal_for_user(self, proposal_id: str, current_user: Any) -> Any:
        """Return a proposal only if the current actor can access it."""
        from app.models.subscription import SubscriptionProposal

        proposal = await self.db.get(SubscriptionProposal, proposal_id)
        if proposal is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposal not found")

        role = self._actor_type(current_user)
        if role == "teacher":
            identifiers = await self._teacher_identifiers(current_user)
            if proposal.teacher_id in identifiers:
                return proposal
        elif role == "student":
            identifiers = await self._student_identifiers(current_user)
            if proposal.student_id in identifiers:
                return proposal
            if await self._is_unlinked_student_profile(proposal.student_id):
                return proposal

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _is_unlinked_student_profile(self, student_id: str) -> bool:
        """Legacy compatibility for teacher-created offline student profiles."""
        from app.models.student import Student

        student = await self.db.get(Student, student_id)
        return student is not None and student.user_id is None

    async def _get_proposal_for_teacher(self, proposal_id: str, current_user: Any) -> Any:
        """Return a proposal only if the current teacher owns it."""
        proposal = await self._get_proposal_for_user(proposal_id, current_user)
        if self._actor_type(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return proposal

    async def create_proposal(
        self, data: SubscriptionProposalCreate, current_user: Any
    ) -> SubscriptionProposalResponse:
        """Send a subscription proposal."""
        from datetime import timedelta

        from app.models.subscription import SubscriptionProposal

        tid = await resolve_teacher_id(self.db, current_user.id)
        teacher_ids = await self._teacher_identifiers(current_user)
        await self._assert_proposal_create_resources(data, teacher_ids)
        proposal = SubscriptionProposal(
            teacher_id=tid,
            student_id=data.student_id,
            template_id=data.template_id,
            message=data.message,
            template_ids=data.template_ids,
            recommended_template_id=data.recommended_template_id,
            lesson_request_id=data.lesson_request_id,
            academy_id=data.academy_id,
            discount_amount=data.discount_amount,
            discount_reason=data.discount_reason,
            proposal_type=data.proposal_type,
            is_renewal=data.is_renewal,
            previous_subscription_id=data.previous_subscription_id,
            renewal_initiator=data.renewal_initiator,
            is_auto_proposal=data.is_auto_proposal,
            is_app_transition=data.is_app_transition,
            status="pending",
            expires_at=datetime.now(UTC) + timedelta(days=7),
        )
        self.db.add(proposal)
        await self.db.flush()
        await self.db.refresh(proposal)

        # Apply golden-time discount metadata for auto-proposals
        await self._apply_golden_time_discount(proposal, tid)

        # GAP-1: Link LessonRequest ↔ Proposal bidirectionally + event log
        if data.lesson_request_id:
            await self._link_request_to_proposal(data.lesson_request_id, proposal.id)
            await self._log_request_event(
                data.lesson_request_id,
                actor_type="teacher",
                actor_id=proposal.teacher_id,
                event_type="proposalSent",
            )

        return SubscriptionProposalResponse.model_validate(proposal)

    async def _assert_proposal_create_resources(self, data: SubscriptionProposalCreate, teacher_ids: list[str]) -> None:
        await self._assert_proposal_student_owner(data.student_id, teacher_ids)
        await self._assert_proposal_template_owner(data.template_id, teacher_ids)
        await self._assert_proposal_template_owner(data.recommended_template_id, teacher_ids)
        for template_id in data.template_ids:
            await self._assert_proposal_template_owner(template_id, teacher_ids)
        await self._assert_proposal_lesson_request_owner(data.lesson_request_id, teacher_ids, data.student_id)
        await self._assert_proposal_previous_subscription_owner(
            data.previous_subscription_id,
            teacher_ids,
            data.student_id,
        )

    async def _assert_proposal_student_owner(self, student_id: str, teacher_ids: list[str]) -> None:
        from app.models.student import Student

        student = await self.db.get(Student, student_id)
        if student is not None and student.teacher_id not in teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _assert_proposal_template_owner(self, template_id: str | None, teacher_ids: list[str]) -> None:
        if template_id is None:
            return

        from app.models.subscription import SubscriptionTemplate

        template = await self.db.get(SubscriptionTemplate, template_id)
        if template is not None and template.teacher_id not in teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _assert_proposal_previous_subscription_owner(
        self,
        previous_subscription_id: str | None,
        teacher_ids: list[str],
        proposal_student_id: str,
    ) -> None:
        if previous_subscription_id is None:
            return

        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        subscription = await self.db.scalar(
            select(Subscription)
            .join(ClassMembership, ClassMembership.id == Subscription.membership_id)
            .join(LessonClass, LessonClass.id == ClassMembership.lesson_class_id)
            .where(
                Subscription.id == previous_subscription_id,
                LessonClass.teacher_id.in_(teacher_ids),
            )
        )
        if subscription is None:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        if subscription.student_id != proposal_student_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _assert_proposal_lesson_request_owner(
        self,
        lesson_request_id: str | None,
        teacher_ids: list[str],
        proposal_student_id: str,
    ) -> None:
        if lesson_request_id is None:
            return

        from app.models.schedule import LessonRequest

        lesson_request = await self.db.get(LessonRequest, lesson_request_id)
        if lesson_request is not None and lesson_request.teacher_id not in teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        if lesson_request is not None and lesson_request.student_id != proposal_student_id:
            await self._assert_request_can_bind_to_proposal_student(
                lesson_request.student_id,
                proposal_student_id,
                teacher_ids,
            )

    async def _assert_request_can_bind_to_proposal_student(
        self,
        request_student_id: str,
        proposal_student_id: str,
        teacher_ids: list[str],
    ) -> None:
        """Allow request-user to teacher-created student profile binding, but not profile mixing."""
        from app.models.student import Student

        proposal_student = await self.db.get(Student, proposal_student_id)
        if proposal_student is None or proposal_student.teacher_id not in teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

        request_student = await self.db.get(Student, request_student_id)
        if request_student is not None and request_student.id != proposal_student_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def expire_old_proposals(self) -> int:
        """Mark expired pending proposals as expired."""
        from app.models.subscription import ProposalStatus, SubscriptionProposal

        now = datetime.now(UTC)
        result = await self.db.scalars(
            select(SubscriptionProposal).where(
                SubscriptionProposal.status.in_([ProposalStatus.pending, ProposalStatus.paymentNotified]),
                SubscriptionProposal.expires_at < now,
            )
        )
        proposals = list(result.all())
        for proposal in proposals:
            proposal.status = ProposalStatus.expired
        await self.db.flush()
        return len(proposals)

    async def respond_to_proposal(
        self, proposal_id: str, data: ProposalRespondRequest, current_user: Any
    ) -> SubscriptionProposalResponse:
        """Accept or reject a proposal."""
        from app.models.subscription import ProposalStatus

        proposal = await self._get_proposal_for_user(proposal_id, current_user)

        if data.action in ("notify_payment", "accept", "select_template"):
            proposal.status = ProposalStatus.paymentNotified
            proposal.payment_notified_at = datetime.now(UTC)
            proposal.selected_template_id = data.selected_template_id

            # GAP-6: Sync LessonRequest status → paymentNotified
            if proposal.lesson_request_id:
                await self._transition_request_status(proposal.lesson_request_id, "paymentNotified")
                await self._log_request_event(
                    proposal.lesson_request_id,
                    actor_type="student",
                    actor_id=proposal.student_id,
                    event_type="paymentNotified",
                    subscription_id=proposal.subscription_id,
                )
        elif data.action == "reject":
            proposal.status = ProposalStatus.rejected
            proposal.rejection_reason = data.rejection_reason
        elif data.action == "cancel":
            proposal.status = ProposalStatus.cancelled
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
            SubscriptionStatus,
            SubscriptionTemplate,
        )

        proposal = await self._get_proposal_for_teacher(proposal_id, current_user)

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

            # Resolve discount amount (golden-time or pre-set)
            original_amount = template.amount if template else 0
            discount_amount = await self._resolve_discount_amount(
                proposal, original_amount,
            )
            discount_reason = proposal.discount_reason if discount_amount > 0 else None

            sub = Subscription(
                student_id=proposal.student_id,
                membership_id=membership_id,
                type=template.type if template else "monthly",
                total_lessons=template.lessons_count if template else None,
                lessons_per_month=template.lessons_per_month if template else None,
                amount=original_amount - discount_amount,
                original_amount=original_amount,
                status=SubscriptionStatus.active,
                payment_confirmed=True,
                payment_method=PaymentMethod.bankTransfer,
                paid_at=proposal.payment_notified_at or now,
                payment_confirmed_at=now,
                discount_amount=discount_amount if discount_amount > 0 else None,
                discount_reason=discount_reason,
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

        # GAP-6: Transition LessonRequest → subscriptionIssued + event log
        if proposal.lesson_request_id:
            await self._transition_request_status(proposal.lesson_request_id, "subscriptionIssued")
            await self._log_request_event(
                proposal.lesson_request_id,
                actor_type="teacher",
                actor_id=proposal.teacher_id,
                event_type="subscriptionIssued",
                subscription_id=proposal.subscription_id,
            )

        proposal.status = ProposalStatus.confirmed
        proposal.payment_status = ProposalPaymentStatus.completed
        proposal.confirmed_at = now
        await self.db.flush()
        await self.db.refresh(proposal)
        return SubscriptionProposalResponse.model_validate(proposal)

    # ------------------------------------------------------------------
    # Private helpers for the request→subscription integration
    # ------------------------------------------------------------------

    async def _log_request_event(
        self,
        request_id: str,
        *,
        actor_type: str,
        actor_id: str,
        event_type: str,
        subscription_id: str | None = None,
        message: str | None = None,
    ) -> None:
        """Persist a RequestEvent for chat history tracking."""
        from app.models.request_event import RequestEvent, RequestEventType

        event = RequestEvent(
            request_id=request_id,
            actor_type=actor_type,
            actor_id=actor_id,
            event_type=RequestEventType(event_type),
            subscription_id=subscription_id,
            message=message,
        )
        self.db.add(event)
        await self.db.flush()

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

    async def _apply_golden_time_discount(
        self, proposal: Any, teacher_id: str
    ) -> None:
        """Tag auto-proposals with golden-time discount metadata.

        The actual discount amount is calculated at confirmation time
        (see ``_resolve_discount_amount``), because we need to know
        how many hours elapsed between proposal creation and student
        acceptance.
        """
        from app.models.settings import ProposalSettings

        if not proposal.is_auto_proposal:
            return

        settings = await self.db.scalar(
            select(ProposalSettings).where(ProposalSettings.teacher_id == teacher_id)
        )
        if settings is None:
            return

        if settings.golden_time_discount_percent > 0:
            proposal.discount_amount = None  # Resolved at confirmation
            proposal.discount_reason = (
                f"golden_time_{settings.golden_time_hours}h"
                f"_{settings.golden_time_discount_percent}%"
            )
            await self.db.flush()

    async def _resolve_discount_amount(
        self, proposal: Any, original_amount: int
    ) -> int:
        """Calculate the final discount amount for a proposal.

        For golden-time discounts the student must have responded
        (``payment_notified_at``) within the configured hours window.
        For other discount types the pre-set ``discount_amount`` is
        returned as-is.
        """
        if not proposal.discount_reason:
            return proposal.discount_amount or 0

        if proposal.discount_reason.startswith("golden_time_"):
            from app.models.settings import ProposalSettings

            ps = await self.db.scalar(
                select(ProposalSettings).where(
                    ProposalSettings.teacher_id == proposal.teacher_id,
                )
            )
            if ps and proposal.payment_notified_at and proposal.created_at:
                elapsed = proposal.payment_notified_at - proposal.created_at
                hours_elapsed = elapsed.total_seconds() / 3600
                if hours_elapsed <= ps.golden_time_hours:
                    return int(original_amount * ps.golden_time_discount_percent / 100)
            return 0

        return proposal.discount_amount or 0

    async def _create_confirmation_card(
        self,
        teacher_id: str,
        student_id: str,
        subscription_id: str,
        lesson_request_id: str | None,
    ) -> None:
        """GAP-4: Auto-create a ScheduleConfirmationCard after subscription issuance."""
        from app.models.policy import ConfirmationCardType, ScheduleConfirmationCard

        proposed_day: str | None = None
        proposed_time: str | None = None
        proposed_duration: int | None = None
        instrument: str | None = None
        card_type = ConfirmationCardType.afterTrial
        total_lessons: int | None = None

        if lesson_request_id:
            from app.models.schedule import LessonRequest

            lr = await self.db.get(LessonRequest, lesson_request_id)
            if lr:
                proposed_day = str(lr.preferred_day) if lr.preferred_day is not None else None
                proposed_time = lr.preferred_time
                proposed_duration = lr.preferred_duration
                instrument = lr.instrument
                if lr.is_returning_student:
                    card_type = ConfirmationCardType.reEnrollment

        # Get total_lessons from the subscription
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub:
            total_lessons = sub.total_lessons

        card = ScheduleConfirmationCard(
            student_id=student_id,
            teacher_id=teacher_id,
            subscription_id=subscription_id,
            lesson_request_id=lesson_request_id,
            card_type=card_type,
            instrument=instrument,
            title="schedule.confirmation_card.title",
            message="schedule.confirmation_card.message",
            proposed_day=proposed_day,
            proposed_time=proposed_time,
            proposed_duration=proposed_duration,
            total_lessons=total_lessons,
        )
        self.db.add(card)
        await self.db.flush()
