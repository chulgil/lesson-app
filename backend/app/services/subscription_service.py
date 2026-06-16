"""Subscription service – subscriptions, templates, proposals."""

from __future__ import annotations

import logging
from datetime import UTC, date, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status

logger = logging.getLogger(__name__)
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import PhoneVerificationRequiredException
from app.models.teacher import Teacher
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
from app.services.subscription_access_service import SubscriptionAccessService
from app.services.teacher_id_resolver import resolve_teacher_id


class SubscriptionService:
    """Handle subscription lifecycle, templates, and proposals."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.access = SubscriptionAccessService(db)

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
        from app.models.subscription import Subscription

        query = await self.access.visible_subscription_query(select(Subscription), user)

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
            if self.access.actor_type(user) == "teacher":
                from app.models.lesson import LessonClass

                query = query.where(LessonClass.teacher_id == teacher_id)
            else:
                query = query.where(False)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [await self._subscription_response(s) for s in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_deposit_summary(
        self,
        *,
        user: Any,
        year: int | None = None,
        month: int | None = None,
    ) -> SubscriptionDepositSummaryResponse:
        """Summarize visible manual tuition deposit states."""
        from app.models.subscription import Subscription

        query = await self.access.visible_subscription_query(
            select(Subscription).where(Subscription.status == "active"),
            user,
        )

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

        # #430: E3 hard gate — first subscription issuance requires phone
        # verification per docs/specs/user/phone_verification_policy.md §4.
        # Frontend intercepts the 409 + ``phone_verification_required`` code
        # and routes to the verification flow.
        await self._require_phone_verification(current_user)

        membership_id = data.membership_id
        if membership_id:
            await self.access.get_membership_for_teacher(
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

        paid_at = data.paid_at
        payment_confirmed_at = data.payment_confirmed_at
        if data.payment_confirmed:
            now = datetime.now(UTC)
            paid_at = paid_at or now
            payment_confirmed_at = payment_confirmed_at or now

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
            paid_at=paid_at,
            payment_confirmed_at=payment_confirmed_at,
            discount_amount=data.discount_amount,
            discount_reason=data.discount_reason,
            original_amount=data.original_amount,
            reschedule_deadline_hours=data.reschedule_deadline_hours,
        )
        self.db.add(sub)
        await self.db.flush()
        await self.db.refresh(sub)

        # Notify student about new subscription
        from app.models.student import Student

        _student = await self.db.get(Student, data.student_id)
        if _student and _student.user_id:
            from app.models.notification import NotificationPriority
            from app.services.notification_service import NotificationService

            notification_service = NotificationService(self.db)
            await notification_service.create_and_send(
                user_id=_student.user_id,
                notification_type="subscriptionIssued",
                title="수강권이 발급되었습니다",
                body=f"{data.total_lessons}회 수강권이 발급되었습니다",
                priority=NotificationPriority.high,
                action_url=f"/subscriptions/{sub.id}",
                action_label="수강권 확인",
            )

        return await self._subscription_response(sub)

    async def get_by_id(self, subscription_id: str, current_user: Any) -> SubscriptionResponse:
        """Return a subscription by ID."""
        sub = await self.access.get_subscription_for_user(subscription_id, current_user)
        return await self._subscription_response(sub)

    async def update(self, subscription_id: str, data: SubscriptionUpdate, current_user: Any) -> SubscriptionResponse:
        """Update a subscription."""
        sub = await self.access.require_teacher_subscription(subscription_id, current_user)

        update_data = data.model_dump(exclude_unset=True)
        self._reject_deposit_state_update(sub, update_data)
        self._validate_subscription_update_state(sub, update_data)
        if update_data.get("payment_confirmed") is True:
            now = datetime.now(UTC)
            update_data.setdefault("paid_at", sub.paid_at or now)
            update_data.setdefault("payment_confirmed_at", sub.payment_confirmed_at or now)
        for key, value in update_data.items():
            setattr(sub, key, value)
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    def _apply_deduction_counter(self, sub: Any) -> None:
        """#426/#743: bump ``used_lessons`` and stamp first consumption.

        Single place that mutates the deduction counter so every deducting path
        (``deduct_lesson``, ``deduct_for_completed_lesson``, ``add_usage``) stays
        consistent (SSOT).
        """
        sub.used_lessons = (sub.used_lessons or 0) + 1

        # #426: stamp first lesson consumption — blocks Undo of payment confirmation.
        if sub.first_lesson_consumed_at is None:
            sub.first_lesson_consumed_at = datetime.now(UTC)

    def _record_lesson_usage(self, sub: Any, *, lesson_id: str | None, **usage_fields: Any) -> Any:
        """Core deduction side-effects (no access checks).

        Creates a ``SubscriptionUsage`` row and bumps the deduction counter via
        ``_apply_deduction_counter`` (#426). Shared by the teacher-facing
        ``deduct_lesson`` and the scheduler-facing ``deduct_for_completed_lesson``.
        """
        from app.models.subscription import SubscriptionUsage

        usage = SubscriptionUsage(
            subscription_id=sub.id,
            lesson_id=lesson_id,
            **usage_fields,
        )
        self.db.add(usage)
        self._apply_deduction_counter(sub)
        return usage

    async def deduct_lesson(
        self, subscription_id: str, data: UseLessonRequest, current_user: Any
    ) -> SubscriptionResponse:
        """Deduct a lesson usage from a subscription.

        동시 두 호출이 모두 ``remaining > 0`` 체크를 통과해 ``used_lessons`` 가
        ``total_lessons`` 를 초과하는 race 를 막기 위해 row lock 을 잡고 재확인한다.
        """
        from app.models.subscription import Subscription

        # 1) ownership 검증.
        await self.access.require_teacher_subscription(subscription_id, current_user)
        # 2) row lock 후 재조회 — 잔여 검증과 increment 가 한 트랜잭션에서 직렬화.
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        if not sub.payment_confirmed:
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED,
                detail="입금이 확인되지 않은 수강권에서는 레슨을 차감할 수 없습니다.",
            )

        remaining = self._remaining_lessons(sub)
        if remaining is not None and remaining <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No remaining lessons",
            )

        self._record_lesson_usage(
            sub,
            lesson_id=data.lesson_id,
            type=data.type,
            teacher_name=data.teacher_name,
            instrument=data.instrument,
            note=data.note,
            deducted=data.deducted,
        )

        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def deduct_for_completed_lesson(self, lesson_id: str, subscription_id: str) -> bool:
        """User-agnostic, idempotent deduction for an auto-completed lesson (#469).

        Called by the attendance scheduler (no current_user / access checks).
        Skips and returns ``False`` if a usage row already exists for
        ``lesson_id`` (idempotent on re-run) or the subscription is missing /
        out of remaining lessons. Returns ``True`` when a deduction is recorded.

        #742: Two concurrent calls for the same lesson_id are serialised by
        locking the Subscription row (WITH FOR UPDATE) BEFORE the idempotency
        re-check, so the second caller observes the first caller's usage row and
        returns False. ``lesson_id`` is intentionally NOT globally unique —
        other paths (manual ``deduct_lesson``, reschedule) legitimately record
        multiple usage rows per lesson.
        """
        from app.models.subscription import Subscription, SubscriptionUsage

        # #742: lock the subscription row FIRST so concurrent callers serialise
        # here, before the idempotency check below.
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            return False

        # Idempotency: bail if this lesson already consumed a session. Re-checked
        # AFTER acquiring the row lock so a concurrent caller that already
        # recorded this lesson is observed (closes the auto-complete race).
        existing = await self.db.scalar(select(SubscriptionUsage.id).where(SubscriptionUsage.lesson_id == lesson_id))
        if existing is not None:
            return False

        # Skip deduction if the subscription has not been payment-confirmed.
        # Mirrors the guard in deduct_lesson() for the manual path.
        if not sub.payment_confirmed:
            return False

        remaining = self._remaining_lessons(sub)
        if remaining is not None and remaining <= 0:
            return False

        self._record_lesson_usage(
            sub,
            lesson_id=lesson_id,
            type="lesson",
            note="24시간 미확인 자동 완료 차감",
            deducted=True,
        )
        await self.db.flush()
        return True

    async def use_reschedule(self, subscription_id: str, current_user: Any) -> SubscriptionResponse:
        """Use a reschedule credit from a subscription.

        잔여 검증과 increment 사이 race 차단 — row lock 후 재확인.
        """
        from app.models.subscription import Subscription, SubscriptionUsage

        await self.access.require_teacher_subscription(subscription_id, current_user)
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

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
        return await self._subscription_response(sub)

    async def patch_reschedule_credits(
        self,
        subscription_id: str,
        additional_count: int,
        reason: str | None,
        current_user: Any,
    ) -> SubscriptionResponse:
        """spec subscription_edit_spec.md §2.1 / §6.1 — 수강권 변경권 추가 (bonus)."""
        from app.models.subscription import Subscription

        if additional_count <= 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="additional_count must be positive",
            )
        await self.access.require_teacher_subscription(subscription_id, current_user)
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        sub.bonus_reschedule_count = (sub.bonus_reschedule_count or 0) + additional_count
        if reason:
            sub.bonus_reason = reason
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def patch_lesson_location(
        self,
        subscription_id: str,
        location_type: str,
        location_id: str | None,
        travel_time_minutes: int | None,
        current_user: Any,
    ) -> SubscriptionResponse:
        """spec §2.2 / §6.1 — 수강권 레슨 장소 + 이동시간 통합 변경."""
        from app.models.subscription import Subscription

        await self.access.require_teacher_subscription(subscription_id, current_user)
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        sub.lesson_location_type = location_type
        sub.lesson_location_id = location_id
        if travel_time_minutes is not None:
            sub.travel_time_minutes = travel_time_minutes
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def patch_travel_time(
        self,
        subscription_id: str,
        travel_time_minutes: int,
        current_user: Any,
    ) -> SubscriptionResponse:
        """spec §2.2 / §6.1 — 이동시간 단독 수정."""
        from app.models.subscription import Subscription

        if travel_time_minutes < 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="travel_time_minutes must be non-negative",
            )
        await self.access.require_teacher_subscription(subscription_id, current_user)
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        sub.travel_time_minutes = travel_time_minutes
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def patch_cancel_deadline(
        self,
        subscription_id: str,
        override_hours: int | None,
        current_user: Any,
    ) -> SubscriptionResponse:
        """spec §2.4 / §6.1 — 수강권별 개별 취소 기준시간 (null = 기본 정책)."""
        from app.models.subscription import Subscription

        if override_hours is not None and override_hours < 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="override_cancel_deadline_hours must be non-negative",
            )
        await self.access.require_teacher_subscription(subscription_id, current_user)
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        sub.override_cancel_deadline_hours = override_hours
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def bulk_change(
        self,
        subscription_id: str,
        new_day_of_week: int,
        new_time: str,
        current_user: Any,
    ) -> dict[str, Any]:
        """spec makeup_credit_spec.md §7 / §8.2 — 일괄변경.

        scheduled / pending / confirmed 미래 booking 을 새 요일/시간으로 옮김.
        같은 요일/시간 슬롯에 충돌 booking 이 이미 있는 경우 해당 건은 cancelled
        + bulkChangeLoss 크레딧 적립. 응답에 4 필드 (rescheduled, lost, credits, newExpiresAt).
        """
        from app.models.schedule import BookingStatus, LessonBooking
        from app.models.subscription import Subscription
        from app.services.makeup_credit_service import MakeupCreditService
        from app.services.teacher_id_resolver import resolve_teacher_id

        if not (0 <= new_day_of_week <= 6):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="new_day_of_week must be 0..6",
            )
        sub = await self.access.require_teacher_subscription(subscription_id, current_user)
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

        today = date.today()
        result = await self.db.scalars(
            select(LessonBooking)
            .where(LessonBooking.subscription_id == subscription_id)
            .where(LessonBooking.scheduled_date >= today)
            .where(
                LessonBooking.status.in_(
                    [
                        BookingStatus.pending,
                        BookingStatus.confirmed,
                        BookingStatus.changeRequested,
                    ]
                )
            )
            .order_by(LessonBooking.scheduled_date.asc())
        )
        targets = list(result.all())

        rescheduled = 0
        lost: list[LessonBooking] = []
        seen_dates: set[date] = set()
        for booking in targets:
            shift = (new_day_of_week - booking.scheduled_date.weekday()) % 7
            new_date = booking.scheduled_date + timedelta(days=shift)
            # 같은 새 일정에 이미 옮긴 booking 이 있거나 conflict — 손실 처리.
            conflict = await self.db.scalar(
                select(LessonBooking.id)
                .where(LessonBooking.teacher_id == booking.teacher_id)
                .where(LessonBooking.scheduled_date == new_date)
                .where(LessonBooking.scheduled_time == new_time)
                .where(LessonBooking.id != booking.id)
                .where(
                    LessonBooking.status.in_(
                        [
                            BookingStatus.pending,
                            BookingStatus.confirmed,
                            BookingStatus.changeRequested,
                        ]
                    )
                )
            )
            if conflict is not None or new_date in seen_dates:
                booking.status = BookingStatus.cancelled
                lost.append(booking)
                continue
            booking.scheduled_date = new_date
            booking.scheduled_time = new_time
            seen_dates.add(new_date)
            rescheduled += 1

        await self.db.flush()

        # MakeupCredit 적립 (각 손실 booking 당 1건).
        credits_accrued = 0
        if lost:
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            makeup = MakeupCreditService(self.db)
            for booking in lost:
                await makeup.accrue_for_bulk_change_loss(
                    student_id=booking.student_id,
                    teacher_id=teacher_id,
                    subscription_id=subscription_id,
                    schedule_change_id=subscription_id,  # spec: schedule_change event id 미보유 시 sub id 로 대체.
                    lost_lesson_id=booking.id,
                )
                credits_accrued += 1

        sub_row = await self.db.get(Subscription, subscription_id)
        return {
            "rescheduled_count": rescheduled,
            "lost_count": len(lost),
            "credits_accrued": credits_accrued,
            "new_expires_at": sub_row.end_date if sub_row is not None else None,
        }

    async def update_status(self, subscription_id: str, new_status: str, current_user: Any) -> SubscriptionResponse:
        """Update subscription status.

        expired 는 terminal state — 임의 backward 전이 차단. 차감·결제 게이트 우회를 방지.
        """
        from app.models.subscription import SubscriptionStatus

        sub = await self.access.require_teacher_subscription(subscription_id, current_user)

        try:
            target = SubscriptionStatus(new_status)
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Unknown subscription status: {new_status}",
            ) from exc
        # spec subscription_master.md §2.3 — 7-상태 lifecycle 전이 매트릭스.
        valid_transitions: dict[SubscriptionStatus, set[SubscriptionStatus]] = {
            SubscriptionStatus.pending: {
                # 입금 확인 → 활성, 또는 시간 만료, 또는 사용자 취소.
                SubscriptionStatus.active,
                SubscriptionStatus.cancelled,
                SubscriptionStatus.expired,
            },
            SubscriptionStatus.active: {
                SubscriptionStatus.expiringSoon,
                SubscriptionStatus.exhausted,
                SubscriptionStatus.expired,
                SubscriptionStatus.paused,
                SubscriptionStatus.suspended,
                SubscriptionStatus.cancelled,
            },
            SubscriptionStatus.expiringSoon: {
                SubscriptionStatus.active,
                SubscriptionStatus.exhausted,
                SubscriptionStatus.expired,
                SubscriptionStatus.paused,
                SubscriptionStatus.suspended,
                SubscriptionStatus.cancelled,
            },
            SubscriptionStatus.paused: {
                SubscriptionStatus.active,
                SubscriptionStatus.expired,
                SubscriptionStatus.suspended,
                SubscriptionStatus.cancelled,
            },
            SubscriptionStatus.suspended: {
                # 운영 측 강제 일시정지 — 활성/만료/취소 로만 복귀.
                SubscriptionStatus.active,
                SubscriptionStatus.expired,
                SubscriptionStatus.cancelled,
            },
            SubscriptionStatus.exhausted: {
                # 횟수 소진 — 만료 / 환불 (cancelled) 만 가능.
                SubscriptionStatus.expired,
                SubscriptionStatus.cancelled,
            },
            SubscriptionStatus.expired: set(),  # terminal — 어떤 상태로도 복귀 불가.
            SubscriptionStatus.cancelled: set(),  # terminal — 환불·취소 후 복귀 불가.
        }
        if target != sub.status and target not in valid_transitions.get(sub.status, set()):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Invalid status transition: {sub.status.value} → {target.value}",
            )
        sub.status = target
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def get_usage_history(self, subscription_id: str, current_user: Any) -> list:
        """Get usage history for a subscription."""
        from app.models.subscription import SubscriptionUsage

        await self.access.get_subscription_for_user(subscription_id, current_user)
        result = await self.db.scalars(
            select(SubscriptionUsage)
            .where(SubscriptionUsage.subscription_id == subscription_id)
            .order_by(SubscriptionUsage.used_at.desc())
        )
        return list(result.all())

    async def add_usage(self, subscription_id: str, data: dict, current_user: Any) -> Any:
        """Add a usage record to a subscription.

        #743: when ``deducted`` is True this also bumps ``used_lessons`` so the
        FE auto-deduct flows (lesson confirmation / add past lesson, which POST
        here with deducted=True) actually decrement remaining. Non-deducted rows
        are history-only and leave the counter untouched.
        """
        from app.models.subscription import Subscription, SubscriptionUsage

        await self.access.require_teacher_subscription(subscription_id, current_user)

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

        if usage.deducted:
            sub = await self.db.get(Subscription, subscription_id)
            if sub is not None:
                self._apply_deduction_counter(sub)

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

        await self.access.get_subscription_for_user(subscription_id, current_user)

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

        role = self.access.actor_type(current_user)
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
            identifiers = await self.access.teacher_identifiers(current_user)
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
            query = query.where(Subscription.student_id.in_(await self.access.student_identifiers(current_user)))
        elif role == "parent":
            query = query.where(Subscription.student_id.in_(await self.access.parent_child_student_ids(current_user)))
        else:
            query = query.where(False)

        result = await self.db.scalars(query.order_by(RequestEvent.created_at.desc(), RequestEvent.id.desc()))

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

        sub = await self.access.get_subscription_for_user(subscription_id, current_user)
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

        role = self.access.actor_type(current_user)
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

        latest = (await self.db.scalars(query.order_by(RequestEvent.created_at.desc(), RequestEvent.id.desc()))).first()
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

    def _validate_subscription_update_state(self, subscription: Any, update_data: dict[str, Any]) -> None:
        """Validate merged subscription counters and static deposit invariants."""
        values = {
            "type": update_data.get("type", subscription.type),
            "total_lessons": update_data.get("total_lessons", subscription.total_lessons),
            "lessons_per_month": update_data.get("lessons_per_month", subscription.lessons_per_month),
            "bonus_count": update_data.get("bonus_count", subscription.bonus_count),
            "used_lessons": update_data.get("used_lessons", subscription.used_lessons),
            "total_reschedule_allowance": update_data.get(
                "total_reschedule_allowance",
                subscription.total_reschedule_allowance,
            ),
            "used_reschedule_count": update_data.get("used_reschedule_count", subscription.used_reschedule_count),
            "payment_confirmed": update_data.get("payment_confirmed", subscription.payment_confirmed),
            "payment_confirmed_at": update_data.get("payment_confirmed_at", subscription.payment_confirmed_at),
        }
        self._validate_counter_value("bonus_count", values["bonus_count"])
        self._validate_counter_value("used_lessons", values["used_lessons"])
        self._validate_counter_value("total_lessons", values["total_lessons"])
        self._validate_counter_value("lessons_per_month", values["lessons_per_month"])
        self._validate_counter_value("total_reschedule_allowance", values["total_reschedule_allowance"])
        self._validate_counter_value("used_reschedule_count", values["used_reschedule_count"])

        lesson_capacity = self._effective_lesson_capacity(
            subscription_type=self._enum_value(values["type"]),
            total_lessons=values["total_lessons"],
            lessons_per_month=values["lessons_per_month"],
            bonus_count=values["bonus_count"] or 0,
        )
        if lesson_capacity is not None and (values["used_lessons"] or 0) > lesson_capacity:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="used_lessons must not exceed effective lesson capacity",
            )
        if (values["used_reschedule_count"] or 0) > (values["total_reschedule_allowance"] or 0):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="used_reschedule_count must not exceed total_reschedule_allowance",
            )
        if values["payment_confirmed"] is False and values["payment_confirmed_at"] is not None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="payment_confirmed_at is not allowed when payment_confirmed is false",
            )

    def _validate_counter_value(self, field_name: str, value: int | None) -> None:
        if value is not None and value < 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail=f"{field_name} must be greater than or equal to 0",
            )

    def _effective_lesson_capacity(
        self,
        *,
        subscription_type: str | None,
        total_lessons: int | None,
        lessons_per_month: int | None,
        bonus_count: int,
    ) -> int | None:
        if subscription_type == "trial":
            return 1 + bonus_count
        base = total_lessons if total_lessons is not None else lessons_per_month
        if base is None:
            return None
        return base + bonus_count

    def _enum_value(self, value: Any) -> str | None:
        if value is None:
            return None
        return str(getattr(value, "value", value))

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

    async def _subscription_response(self, sub: Any) -> SubscriptionResponse:
        """Build a subscription response enriched with membership schedule context.

        spec subscription_edit_spec.md §11.3 — 수강권 본인 값이 있으면 우선,
        없으면 membership(학생 신청 시점)의 값을 폴백.
        """
        from app.models.lesson import ClassMembership

        response = SubscriptionResponse.model_validate(sub)
        if sub.membership_id is None:
            return response

        membership = await self.db.get(ClassMembership, sub.membership_id)
        if membership is None:
            return response

        if response.lesson_location_id is None:
            response.lesson_location_id = membership.lesson_location_id
        if response.travel_time_minutes is None:
            response.travel_time_minutes = membership.travel_time_minutes
        # spec §2.5 — 수강권 1개 = 멤버십 1개 = 악기 1개. 멤버십 instrument 를 SSOT
        # 로 노출하되, 레거시 default="" 는 null 로 내려 FE 가 학생값으로 폴백한다.
        response.instrument = membership.instrument or None
        return response

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

    async def confirm_payment(
        self, subscription_id: str, data: ConfirmPaymentRequest, current_user: Any
    ) -> SubscriptionResponse:
        """Confirm a manual tuition deposit.

        동시 두 호출이 모두 ``payment_confirmed=False`` 체크를 통과해 알림톡·푸시·
        relation status 가 두 번 처리되는 race 를 막기 위해 row lock 후 재확인.
        """
        from app.models.subscription import PaymentMethod, Subscription
        from app.services.notification_service import NotificationService

        await self.access.require_teacher_subscription(subscription_id, current_user)
        sub = await self.db.scalar(select(Subscription).where(Subscription.id == subscription_id).with_for_update())
        if sub is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        if sub.payment_confirmed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment already confirmed",
            )
        sub.payment_confirmed = True
        if sub.paid_at is None:
            sub.paid_at = datetime.now(UTC)
        sub.payment_confirmed_at = datetime.now(UTC)
        if data.payment_method:
            sub.payment_method = PaymentMethod(data.payment_method)

        # #426: stash relation status so Undo can restore it.
        await self._link_subscription_to_relation(sub)

        await self._notify_deposit_confirmed(sub, NotificationService(self.db))

        # #423 — fire-and-forget LNZ_PAYMENT_CONFIRM. Failure must not break the confirm flow.
        try:
            await self._send_alimtalk_payment_confirm(sub)
        except Exception:  # noqa: BLE001
            logger.exception("alimtalk LNZ_PAYMENT_CONFIRM trigger failed sub=%s", sub.id)

        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def _send_alimtalk_payment_confirm(self, sub: Any) -> None:
        """#423 — push LNZ_PAYMENT_CONFIRM alimtalk to the student/parent after E3."""
        from app.models.student import Student
        from app.services.alimtalk_service import build_alimtalk_service

        student = await self.db.get(Student, sub.student_id)
        if student is None:
            return
        phone = student.parent_phone or student.phone or ""
        service = build_alimtalk_service(self.db)
        await service.send_payment_confirm(
            subscription_id=sub.id,
            recipient_phone=phone,
            variables={
                "student_name": student.name or "",
                "subscription_id": sub.id,
                "amount": str(sub.amount or 0),
            },
            # #423 — alimtalk fail → FCM push fallback to the linked user.
            fallback_user_id=student.user_id,
        )

    async def undo_confirm_payment(self, subscription_id: str, current_user: Any) -> SubscriptionResponse:
        """Undo a manual tuition deposit confirmation (#426).

        Allowed when:
          - payment was confirmed (payment_confirmed=True)
          - first lesson has not yet been consumed (first_lesson_consumed_at is None)
          - within 24h of payment_confirmed_at
        """
        from app.services.notification_service import NotificationService

        sub = await self.access.require_teacher_subscription(subscription_id, current_user)

        if not sub.payment_confirmed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment is not confirmed; nothing to undo",
            )
        if sub.first_lesson_consumed_at is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="첫 레슨 차감 후에는 입금 확인을 되돌릴 수 없습니다.",
            )

        confirmed_at = sub.payment_confirmed_at
        now = datetime.now(UTC)
        if confirmed_at is not None:
            confirmed_at_aware = confirmed_at if confirmed_at.tzinfo else confirmed_at.replace(tzinfo=UTC)
            if (now - confirmed_at_aware) > timedelta(hours=24):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="입금 확인 24h window 가 만료되었습니다.",
                )

        # 1) Roll back subscription deposit state.
        sub.payment_confirmed = False
        sub.payment_confirmed_at = None

        # 2) Restore relation from previous_status stash.
        await self._unlink_subscription_from_relation(sub)

        # 3) Cancel auto-generated future lessons tied to this subscription.
        await self._cancel_auto_generated_lessons(sub)

        # 4) Notify student/parent that the deposit confirmation was undone.
        await self._notify_deposit_undone(sub, NotificationService(self.db))

        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def _link_subscription_to_relation(self, subscription: Any) -> None:
        """Stash relation status and mark this subscription as the active one (#426)."""
        from app.models.relationship import RelationStatus, TeacherStudentRelation

        teacher_ids = await self._teacher_ids_for_subscription(subscription)
        if not teacher_ids:
            return
        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id.in_(teacher_ids),
                TeacherStudentRelation.student_id == subscription.student_id,
            )
        )
        if relation is None:
            return
        if relation.status != RelationStatus.active:
            relation.previous_status = relation.status
            relation.status = RelationStatus.active
        relation.active_subscription_id = subscription.id

    async def _unlink_subscription_from_relation(self, subscription: Any) -> None:
        """Restore previous_status and clear active_subscription_id on Undo (#426)."""
        from app.models.relationship import TeacherStudentRelation

        teacher_ids = await self._teacher_ids_for_subscription(subscription)
        if not teacher_ids:
            return
        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id.in_(teacher_ids),
                TeacherStudentRelation.student_id == subscription.student_id,
            )
        )
        if relation is None:
            return
        if relation.previous_status is not None:
            relation.status = relation.previous_status
            relation.previous_status = None
        if relation.active_subscription_id == subscription.id:
            relation.active_subscription_id = None

    async def _teacher_ids_for_subscription(self, subscription: Any) -> list[str]:
        """Return teacher_id(s) that own the subscription via its membership."""
        from app.models.lesson import ClassMembership, LessonClass

        teacher_id = await self.db.scalar(
            select(LessonClass.teacher_id)
            .join(ClassMembership, ClassMembership.lesson_class_id == LessonClass.id)
            .where(ClassMembership.id == subscription.membership_id)
        )
        return [teacher_id] if teacher_id else []

    async def _cancel_auto_generated_lessons(self, subscription: Any) -> None:
        """Cancel future subscription-generated lessons attached to this sub (#426)."""
        from app.models.lesson import Lesson, LessonSource, LessonStatus

        result = await self.db.scalars(
            select(Lesson).where(
                Lesson.subscription_id == subscription.id,
                Lesson.lesson_source == LessonSource.subscription_generated,
                Lesson.status == LessonStatus.scheduled,
            )
        )
        for lesson in result.all():
            lesson.status = LessonStatus.cancelled

    async def _notify_deposit_undone(self, subscription: Any, notification_service: Any) -> None:
        """Notify student/parent that the teacher reverted the deposit confirmation (#426)."""
        from app.models.notification import NotificationPriority
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
        from app.models.student import Student

        student = await self.db.get(Student, subscription.student_id)
        if student is None:
            return

        recipient_user_ids: set[str] = set()
        if student.user_id:
            recipient_user_ids.add(student.user_id)

        parent_user_ids = await self.db.scalars(
            select(Parent.user_id)
            .join(ParentChildRelation, ParentChildRelation.parent_id == Parent.id)
            .where(
                ParentChildRelation.student_id == subscription.student_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        recipient_user_ids.update(user_id for user_id in parent_user_ids.all() if user_id)

        for user_id in sorted(recipient_user_ids):
            await notification_service.create_and_send(
                user_id=user_id,
                notification_type="paymentUndone",
                title="입금 확인이 취소되었습니다",
                body=f"{student.name} 수강권의 입금 확인을 선생님이 되돌렸습니다.",
                priority=NotificationPriority.normal,
                data={
                    "subscriptionId": subscription.id,
                    "studentId": subscription.student_id,
                    "source": "subscription_deposit",
                },
                action_url=f"/subscriptions/{subscription.id}",
                action_label="수강권 보기",
            )

    async def notify_payment(
        self,
        subscription_id: str,
        data: NotifyPaymentRequest,
        current_user: Any,
    ) -> SubscriptionResponse:
        """Record that a student or parent reports an external tuition deposit."""
        from app.models.subscription import PaymentMethod
        from app.services.notification_service import NotificationService

        sub = await self.access.get_subscription_for_user(subscription_id, current_user)
        if self.access.actor_type(current_user) == "teacher":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Teachers must use confirm-payment for manual tuition deposits",
            )
        if sub.payment_confirmed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment already confirmed",
            )
        if data.payment_method:
            sub.payment_method = PaymentMethod(data.payment_method)
        sub.paid_at = datetime.now(UTC)
        await self._notify_deposit_received(sub, NotificationService(self.db))
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    def _reject_deposit_state_update(self, subscription: Any, update_data: dict[str, Any]) -> None:
        """Keep manual deposit state transitions on dedicated endpoints."""
        restricted_fields = {
            "payment_confirmed",
            "paid_at",
            "payment_confirmed_at",
            "payment_method",
        }
        for field_name in restricted_fields & update_data.keys():
            if not self._same_deposit_value(update_data[field_name], getattr(subscription, field_name)):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="Use notify-payment or confirm-payment to change manual tuition deposit state",
                )

    def _same_deposit_value(self, incoming: Any, current: Any) -> bool:
        if incoming is None or current is None:
            return incoming is current
        if isinstance(incoming, datetime) or isinstance(current, datetime):
            return incoming == current
        return self._enum_value(incoming) == self._enum_value(current)

    async def notify_payment_as_parent(
        self,
        subscription_id: str,
        data: NotifyPaymentRequest,
        current_user: Any,
    ) -> SubscriptionResponse:
        """Issue #635 — 학부모가 자녀 수강권 입금을 선생님에게 알림.

        spec parent_system.md §6.
        - parent role 전용 (teacher/student 403)
        - ParentChildRelation 검증은 access.get_subscription_for_user 통과로 충족
        - 알림 body 에 'paid by parent' 명시
        - 기존 notify_payment 로직 (paid_at + payment_method) 재사용
        """
        from app.models.subscription import PaymentMethod
        from app.services.notification_service import NotificationService

        if self.access.actor_type(current_user) != "parent":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Parent role required",
            )
        sub = await self.access.get_subscription_for_user(subscription_id, current_user)
        if sub.payment_confirmed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment already confirmed",
            )
        if data.payment_method:
            sub.payment_method = PaymentMethod(data.payment_method)
        sub.paid_at = datetime.now(UTC)
        await self._notify_deposit_received(
            sub,
            NotificationService(self.db),
            paid_by_parent=True,
        )
        await self.db.flush()
        await self.db.refresh(sub)
        return await self._subscription_response(sub)

    async def _notify_deposit_received(
        self,
        subscription: Any,
        notification_service: Any,
        *,
        paid_by_parent: bool = False,
    ) -> None:
        """Notify the teacher that a student-side external deposit was reported.

        Issue #635 — paid_by_parent=True 시 알림 body 에 학부모 결제 명시.
        """
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.notification import NotificationPriority
        from app.models.student import Student

        row = (
            await self.db.execute(
                select(Teacher.user_id, Student.name)
                .join(LessonClass, LessonClass.teacher_id == Teacher.id)
                .join(ClassMembership, ClassMembership.lesson_class_id == LessonClass.id)
                .join(Student, Student.id == subscription.student_id)
                .where(ClassMembership.id == subscription.membership_id)
            )
        ).one_or_none()
        if row is None:
            return

        teacher_user_id, student_name = row
        body = (
            f"{student_name}님 학부모가 입금 완료를 알렸습니다."
            if paid_by_parent
            else f"{student_name}님이 입금 완료를 알렸습니다."
        )
        await notification_service.create_and_send(
            user_id=teacher_user_id,
            notification_type="paymentReceived",
            title="입금 완료 알림",
            body=body,
            priority=NotificationPriority.high,
            data={
                "subscriptionId": subscription.id,
                "studentId": subscription.student_id,
                "source": "subscription_deposit",
                "paidByParent": paid_by_parent,
            },
            action_url=f"/subscriptions/{subscription.id}",
            action_label="입금 확인",
        )

    async def _notify_deposit_confirmed(self, subscription: Any, notification_service: Any) -> None:
        """Notify student-side recipients that the teacher confirmed the external deposit."""
        from app.models.notification import NotificationPriority
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
        from app.models.student import Student

        student = await self.db.get(Student, subscription.student_id)
        if student is None:
            return

        recipient_user_ids: set[str] = set()
        if student.user_id:
            recipient_user_ids.add(student.user_id)

        parent_user_ids = await self.db.scalars(
            select(Parent.user_id)
            .join(ParentChildRelation, ParentChildRelation.parent_id == Parent.id)
            .where(
                ParentChildRelation.student_id == subscription.student_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        recipient_user_ids.update(user_id for user_id in parent_user_ids.all() if user_id)

        for user_id in sorted(recipient_user_ids):
            await notification_service.create_and_send(
                user_id=user_id,
                notification_type="paymentConfirmed",
                title="입금 확인 완료",
                body=f"{student.name} 수강권 입금이 확인되었습니다.",
                priority=NotificationPriority.normal,
                data={
                    "subscriptionId": subscription.id,
                    "studentId": subscription.student_id,
                    "source": "subscription_deposit",
                },
                action_url=f"/subscriptions/{subscription.id}",
                action_label="수강권 보기",
            )

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

        identifiers = await self.access.teacher_identifiers(current_user)
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

        identifiers = await self.access.teacher_identifiers(current_user)
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

        sub = await self.access.require_teacher_subscription(previous_subscription_id, current_user)
        tid = await resolve_teacher_id(self.db, current_user.id)

        # Find a matching active template by teacher + subscription type
        template = await self.db.scalar(
            select(SubscriptionTemplate)
            .where(
                SubscriptionTemplate.teacher_id == tid,
                SubscriptionTemplate.type == sub.type,
                SubscriptionTemplate.is_active == True,  # noqa: E712
            )
            .limit(1)
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
        role = self.access.actor_type(user)
        if role == "teacher":
            query = query.where(SubscriptionProposal.teacher_id.in_(await self.access.teacher_identifiers(user)))
        elif role == "student":
            query = query.where(SubscriptionProposal.student_id.in_(await self.access.student_identifiers(user)))
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

        role = self.access.actor_type(current_user)
        if role == "teacher":
            identifiers = await self.access.teacher_identifiers(current_user)
            if proposal.teacher_id in identifiers:
                return proposal
        elif role == "student":
            # #468 (1a): a student may only read a proposal addressed to one of
            # their own linked Student profiles. The previous role-only bypass
            # that granted access to ANY proposal whose Student.user_id IS NULL
            # was an IDOR (an unrelated student could read another teacher's
            # offline-student proposal) — removed.
            identifiers = await self.access.student_identifiers(current_user)
            if proposal.student_id in identifiers:
                return proposal

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _get_proposal_for_teacher(self, proposal_id: str, current_user: Any) -> Any:
        """Return a proposal only if the current teacher owns it."""
        proposal = await self._get_proposal_for_user(proposal_id, current_user)
        if self.access.actor_type(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return proposal

    async def create_proposal(
        self, data: SubscriptionProposalCreate, current_user: Any
    ) -> SubscriptionProposalResponse:
        """Send a subscription proposal."""
        from datetime import timedelta

        from app.models.subscription import SubscriptionProposal

        tid = await resolve_teacher_id(self.db, current_user.id)
        teacher_ids = await self.access.teacher_identifiers(current_user)
        await self._assert_proposal_create_resources(data, teacher_ids)

        # #696 — §3.1.5 single active proposal constraint: raise 409 if a
        # pending/paymentNotified proposal already exists for (teacher, student).
        await self._assert_no_active_proposal(tid, data.student_id)
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

        # #423 — fire-and-forget alimtalk LNZ_INVOICE. Failure must not break proposal creation.
        try:
            await self._send_alimtalk_invoice(proposal)
        except Exception:  # noqa: BLE001
            logger.exception("alimtalk LNZ_INVOICE trigger failed proposal=%s", proposal.id)

        return SubscriptionProposalResponse.model_validate(proposal)

    async def _send_alimtalk_invoice(self, proposal: Any) -> None:
        """#423 — push LNZ_INVOICE alimtalk to the student/parent right after E1."""
        from app.models.student import Student
        from app.services.alimtalk_service import build_alimtalk_service

        student = await self.db.get(Student, proposal.student_id)
        if student is None:
            return
        phone = student.parent_phone or student.phone or ""
        service = build_alimtalk_service(self.db)
        await service.send_invoice(
            proposal_id=proposal.id,
            recipient_phone=phone,
            variables={
                "student_name": student.name or "",
                "proposal_id": proposal.id,
                "expires_at": proposal.expires_at.isoformat() if proposal.expires_at else "",
            },
            # #423 — alimtalk fail → FCM push fallback to the linked user.
            fallback_user_id=student.user_id,
        )

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

    async def _assert_no_active_proposal(self, teacher_id: str, student_id: str) -> None:
        """#696 §3.1.5 — ensure at most one pending/paymentNotified proposal per (teacher, student).

        Raises 409 with ``active_proposal_exists`` + the conflicting proposalId so
        FE can offer [기존 제안 보기] / [기존 제안 취소 후 재제안] dialog.
        """
        from app.models.subscription import ProposalStatus, SubscriptionProposal

        existing = await self.db.scalar(
            select(SubscriptionProposal).where(
                SubscriptionProposal.teacher_id == teacher_id,
                SubscriptionProposal.student_id == student_id,
                SubscriptionProposal.status.in_([ProposalStatus.pending, ProposalStatus.paymentNotified]),
            )
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error": "active_proposal_exists",
                    "proposalId": existing.id,
                },
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

    async def expire_old_proposals(self, teacher_id: str) -> int:
        """Mark expired pending proposals as expired — 해당 강사 본인의 제안서만.

        teacher_id 가 없으면 전 시스템 sweep 이 되어 임의 강사가 다른 강사의 제안서
        상태를 바꿀 수 있다 (#468 1d).
        """
        from app.models.subscription import ProposalStatus, SubscriptionProposal

        now = datetime.now(UTC)
        result = await self.db.scalars(
            select(SubscriptionProposal).where(
                SubscriptionProposal.teacher_id == teacher_id,
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

    async def confirm_proposal(
        self,
        proposal_id: str,
        current_user: Any,
        *,
        subscription_id_hint: str | None = None,
    ) -> SubscriptionProposalResponse:
        """Confirm a manual deposit and issue the subscription.

        Handles GAP-2 (membership), GAP-3 (relationship), GAP-4 (confirmation card),
        GAP-6 (request status transition) in addition to subscription creation.

        FE 가 subscription_id_hint 를 보내면 (renewal/manual-link 케이스) ownership
        검증 후 proposal 에 link. 새로 mint 하지 않음.
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

        # Access gate (ownership + 404).
        await self._get_proposal_for_teacher(proposal_id, current_user)

        # #468 (1b): re-fetch the proposal row with FOR UPDATE so concurrent
        # confirm requests serialize on the same row. This prevents the
        # double-issue race where two callers both observe an empty
        # ``subscription_id`` and each mint a Subscription. No-op on SQLite,
        # real row lock on Postgres. No DB migration / unique index added.
        proposal = await self.db.scalar(
            select(SubscriptionProposal).where(SubscriptionProposal.id == proposal_id).with_for_update()
        )

        # #10 A-C2 — confirming a proposal mints a Subscription, the same hard
        # gate that `create()` uses. Without this the gate is bypassed via the
        # proposal flow (#430 phone_verification_policy.md §4).
        await self._require_phone_verification(current_user)

        if proposal.status != "paymentNotified":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Proposal must be paymentNotified before confirmation",
            )

        now = datetime.now(UTC)

        # FE 명시 hint — ownership 검증 후 proposal 에 link (새로 mint 하지 않음).
        if subscription_id_hint and not proposal.subscription_id:
            existing_sub = await self.access.require_teacher_subscription(subscription_id_hint, current_user)
            if existing_sub is not None:
                proposal.subscription_id = existing_sub.id

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
                proposal,
                original_amount,
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

    async def _require_phone_verification(self, current_user: Any) -> None:
        """E3 hard gate: raise if the acting teacher has not verified their phone.

        Non-teacher users are not gated here — role-level access is enforced
        upstream by ``get_current_teacher`` on the API route.
        """
        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == current_user.id))
        if teacher is None:
            # No teacher profile yet — let downstream membership lookup raise.
            return
        if not teacher.is_phone_verified:
            raise PhoneVerificationRequiredException("수강권 발급에는 전화인증이 필요해요")

    async def _find_or_create_membership(self, teacher_id: str, student_id: str, instrument: str | None = None) -> str:
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

    async def _activate_relationship(self, teacher_id: str, student_id: str, subscription_id: str) -> None:
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

    async def _apply_golden_time_discount(self, proposal: Any, teacher_id: str) -> None:
        """Tag auto-proposals with golden-time discount metadata.

        The actual discount amount is calculated at confirmation time
        (see ``_resolve_discount_amount``), because we need to know
        how many hours elapsed between proposal creation and student
        acceptance.
        """
        from app.models.settings import ProposalSettings

        if not proposal.is_auto_proposal:
            return

        settings = await self.db.scalar(select(ProposalSettings).where(ProposalSettings.teacher_id == teacher_id))
        if settings is None:
            return

        if settings.golden_time_discount_percent > 0:
            proposal.discount_amount = None  # Resolved at confirmation
            proposal.discount_reason = (
                f"golden_time_{settings.golden_time_hours}h_{settings.golden_time_discount_percent}%"
            )
            await self.db.flush()

    async def _resolve_discount_amount(self, proposal: Any, original_amount: int) -> int:
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
