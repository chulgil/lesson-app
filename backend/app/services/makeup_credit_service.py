"""Make-up Credit service — #432 G3.

Spec: docs/specs/subscription/makeup_credit_spec.md

Responsibilities:
- Accrual (4 sources): teacherVacation / noShowExempt / bulkChangeLoss / manualGrant
  (+ fifthWeekBonus per #432 brief).
- Use (consume on a lesson booking).
- Expire (mark expired credits or filter active).
- scheduled_lessons recalculation for a subscription
  (counts active LessonBookings — for future bulkChange callers).

Notes:
- Service is constructor-injected with AsyncSession (matches existing pattern,
  e.g. SubscriptionService).
- All methods are async + transactional via the caller's session.
- 30-day default expiry; callers may override.
"""

from __future__ import annotations

from collections.abc import Iterable
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.makeup_credit import MakeupCredit, MakeupCreditReason
from app.models.schedule import BookingStatus, LessonBooking
from app.models.subscription import Subscription

# Active LessonBooking statuses that count toward scheduled_lessons.
# Spec §3.2 — "LessonBooking.status in [scheduled, completed]". Our enum has
# pending/confirmed/changeRequested/completed as live states.
_ACTIVE_BOOKING_STATUSES: tuple[BookingStatus, ...] = (
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.changeRequested,
    BookingStatus.completed,
)

DEFAULT_EXPIRY_DAYS = 30


def _utcnow() -> datetime:
    return datetime.now(UTC)


class MakeupCreditService:
    """CRUD + lifecycle for MakeupCredit; helpers for scheduled_lessons track."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Accrual
    # ------------------------------------------------------------------

    async def accrue(
        self,
        *,
        student_id: str,
        teacher_id: str,
        reason: MakeupCreditReason,
        source_subscription_id: str | None = None,
        source_event_id: str | None = None,
        source_lesson_id: str | None = None,
        expires_at: datetime | None = None,
    ) -> MakeupCredit:
        """Create a new credit. Generic entry-point for all 4 (+1) accrual triggers."""
        now = _utcnow()
        credit = MakeupCredit(
            student_id=student_id,
            teacher_id=teacher_id,
            reason=reason,
            source_subscription_id=source_subscription_id,
            source_event_id=source_event_id,
            source_lesson_id=source_lesson_id,
            expires_at=expires_at or (now + timedelta(days=DEFAULT_EXPIRY_DAYS)),
        )
        self.db.add(credit)
        await self.db.flush()
        return credit

    async def accrue_for_vacation(
        self,
        *,
        student_id: str,
        teacher_id: str,
        vacation_id: str,
        vacation_end_date: datetime,
        source_lesson_id: str | None = None,
    ) -> MakeupCredit:
        """Spec §4.1 — teacher vacation creates 1 credit per affected booking.

        Expires at vacation end + 30 days (per spec §4.1 table).
        Called by the vacation flow (#431).
        """
        return await self.accrue(
            student_id=student_id,
            teacher_id=teacher_id,
            reason=MakeupCreditReason.teacherVacation,
            source_event_id=vacation_id,
            source_lesson_id=source_lesson_id,
            expires_at=vacation_end_date + timedelta(days=DEFAULT_EXPIRY_DAYS),
        )

    async def accrue_for_no_show_exempt(
        self,
        *,
        student_id: str,
        teacher_id: str,
        lesson_id: str,
    ) -> MakeupCredit:
        """Spec §4.2 — teacher waives a student no-show. Creates 1 credit, 30d expiry."""
        return await self.accrue(
            student_id=student_id,
            teacher_id=teacher_id,
            reason=MakeupCreditReason.noShowExempt,
            source_event_id=lesson_id,
            source_lesson_id=lesson_id,
        )

    async def accrue_for_bulk_change_loss(
        self,
        *,
        student_id: str,
        teacher_id: str,
        subscription_id: str,
        schedule_change_id: str,
        lost_lesson_id: str | None = None,
    ) -> MakeupCredit:
        """Spec §4.3 — a bulk schedule change couldn't re-place a lesson. 30d expiry."""
        return await self.accrue(
            student_id=student_id,
            teacher_id=teacher_id,
            reason=MakeupCreditReason.bulkChangeLoss,
            source_subscription_id=subscription_id,
            source_event_id=schedule_change_id,
            source_lesson_id=lost_lesson_id,
        )

    async def accrue_manual(
        self,
        *,
        student_id: str,
        teacher_id: str,
        note_event_id: str | None = None,
    ) -> MakeupCredit:
        """Spec §4.4 — teacher manually grants a credit (safety net)."""
        return await self.accrue(
            student_id=student_id,
            teacher_id=teacher_id,
            reason=MakeupCreditReason.manualGrant,
            source_event_id=note_event_id,
        )

    async def accrue_fifth_week_bonus(
        self,
        *,
        student_id: str,
        teacher_id: str,
        subscription_id: str,
    ) -> MakeupCredit:
        """Task brief #432 — 5주차 보너스 적립. 30d expiry."""
        return await self.accrue(
            student_id=student_id,
            teacher_id=teacher_id,
            reason=MakeupCreditReason.fifthWeekBonus,
            source_subscription_id=subscription_id,
        )

    # ------------------------------------------------------------------
    # Use
    # ------------------------------------------------------------------

    async def use_credit(
        self,
        *,
        credit_id: str,
        lesson_id: str,
        at: datetime | None = None,
    ) -> MakeupCredit:
        """Consume an active credit on a lesson booking.

        Raises ValueError if the credit is missing, expired, or already used.
        Caller increments `Subscription.scheduled_lessons` separately (spec §5.3).
        """
        moment = at or _utcnow()
        credit = await self.db.get(MakeupCredit, credit_id)
        if credit is None:
            raise ValueError(f"MakeupCredit not found: {credit_id}")
        if credit.used_at is not None:
            raise ValueError(f"MakeupCredit {credit_id} already used at {credit.used_at}")
        if credit.expires_at < moment:
            raise ValueError(f"MakeupCredit {credit_id} expired at {credit.expires_at} (now={moment})")

        credit.used_at = moment
        credit.used_lesson_id = lesson_id
        await self.db.flush()
        return credit

    async def use_oldest_active_credit_for_student(
        self,
        *,
        student_id: str,
        teacher_id: str,
        lesson_id: str,
    ) -> MakeupCredit | None:
        """Convenience for booking flow — pick the oldest active credit and use it.

        Returns None if no active credit. Otherwise returns the consumed credit.
        """
        credits = await self.list_active_credits(
            student_id=student_id,
            teacher_id=teacher_id,
            limit=1,
        )
        if not credits:
            return None
        # Oldest first (FIFO). list_active_credits orders by expires_at asc.
        return await self.use_credit(credit_id=credits[0].id, lesson_id=lesson_id)

    # ------------------------------------------------------------------
    # Query
    # ------------------------------------------------------------------

    async def list_by_student(self, student_id: str) -> list[MakeupCredit]:
        """All credits for a student (any status)."""
        result = await self.db.scalars(
            select(MakeupCredit).where(MakeupCredit.student_id == student_id).order_by(MakeupCredit.created_at.desc())
        )
        return list(result.all())

    async def list_active_credits(
        self,
        *,
        student_id: str,
        teacher_id: str | None = None,
        at: datetime | None = None,
        limit: int | None = None,
    ) -> list[MakeupCredit]:
        """Credits that are unused AND not yet expired (FIFO by expires_at)."""
        moment = at or _utcnow()
        stmt = (
            select(MakeupCredit)
            .where(MakeupCredit.student_id == student_id)
            .where(MakeupCredit.used_at.is_(None))
            .where(MakeupCredit.expires_at > moment)
            .order_by(MakeupCredit.expires_at.asc())
        )
        if teacher_id is not None:
            stmt = stmt.where(MakeupCredit.teacher_id == teacher_id)
        if limit is not None:
            stmt = stmt.limit(limit)
        result = await self.db.scalars(stmt)
        return list(result.all())

    async def count_active_credits(
        self,
        *,
        student_id: str,
        teacher_id: str | None = None,
        at: datetime | None = None,
    ) -> int:
        """Count of unused, unexpired credits for a student (optionally per teacher)."""
        moment = at or _utcnow()
        stmt = (
            select(func.count(MakeupCredit.id))
            .where(MakeupCredit.student_id == student_id)
            .where(MakeupCredit.used_at.is_(None))
            .where(MakeupCredit.expires_at > moment)
        )
        if teacher_id is not None:
            stmt = stmt.where(MakeupCredit.teacher_id == teacher_id)
        return int((await self.db.scalar(stmt)) or 0)

    async def list_for_teacher(self, teacher_id: str) -> list[MakeupCredit]:
        """All credits issued by a teacher (admin / management view)."""
        result = await self.db.scalars(
            select(MakeupCredit).where(MakeupCredit.teacher_id == teacher_id).order_by(MakeupCredit.created_at.desc())
        )
        return list(result.all())

    # ------------------------------------------------------------------
    # Expire
    # ------------------------------------------------------------------

    async def find_expired_credits(
        self,
        at: datetime | None = None,
    ) -> list[MakeupCredit]:
        """Credits past expiry that were never used. Caller decides what to do
        (logical-only — no status column today; expiry is computed)."""
        moment = at or _utcnow()
        result = await self.db.scalars(
            select(MakeupCredit)
            .where(MakeupCredit.used_at.is_(None))
            .where(MakeupCredit.expires_at < moment)
            .order_by(MakeupCredit.expires_at.asc())
        )
        return list(result.all())

    # ------------------------------------------------------------------
    # Revoke
    # ------------------------------------------------------------------

    async def revoke_credit(
        self,
        *,
        credit_id: str,
        teacher_id: str,
    ) -> None:
        """Spec §8.1 DELETE — teacher revokes a mistakenly granted credit.

        Raises:
            ValueError: credit not found.
            PermissionError: credit belongs to another teacher.
            RuntimeError: credit already used (caller maps to HTTP 409).
        """
        credit = await self.db.get(MakeupCredit, credit_id)
        if credit is None:
            raise ValueError(f"MakeupCredit not found: {credit_id}")
        if credit.teacher_id != teacher_id:
            raise PermissionError(f"MakeupCredit {credit_id} not owned by teacher {teacher_id}")
        if credit.used_at is not None:
            raise RuntimeError(f"MakeupCredit {credit_id} already used at {credit.used_at}")
        await self.db.delete(credit)
        await self.db.flush()

    # ------------------------------------------------------------------
    # scheduled_lessons track
    # ------------------------------------------------------------------

    async def recalculate_scheduled_lessons(self, subscription_id: str) -> int:
        """Recompute Subscription.scheduled_lessons = count of active LessonBookings.

        Active = status in pending/confirmed/changeRequested/completed (spec §3.2).
        Returns the new value.

        Hook point for the future bulkChange caller (spec §7) — call this after
        every bulkChange operation that mutates the booking set, before
        committing.
        """
        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise ValueError(f"Subscription not found: {subscription_id}")

        count_stmt = (
            select(func.count(LessonBooking.id))
            .where(LessonBooking.subscription_id == subscription_id)
            .where(LessonBooking.status.in_(_ACTIVE_BOOKING_STATUSES))
        )
        new_count = int((await self.db.scalar(count_stmt)) or 0)

        sub.scheduled_lessons = new_count
        await self.db.flush()
        return new_count

    async def recalculate_for_bookings(
        self,
        booking_ids: Iterable[str],
    ) -> dict[str, int]:
        """Recompute for every subscription affected by a booking set (bulkChange helper).

        Returns {subscription_id: new_scheduled_lessons}.
        """
        booking_ids_list = [b for b in booking_ids if b]
        if not booking_ids_list:
            return {}

        sub_ids_stmt = (
            select(LessonBooking.subscription_id)
            .where(LessonBooking.id.in_(booking_ids_list))
            .where(LessonBooking.subscription_id.is_not(None))
            .distinct()
        )
        sub_ids = [s for s in (await self.db.scalars(sub_ids_stmt)).all() if s]
        return {sub_id: await self.recalculate_scheduled_lessons(sub_id) for sub_id in sub_ids}

    async def recompute_for_subscriptions(
        self,
        subscription_ids: Iterable[str],
    ) -> dict[str, int]:
        """Recompute scheduled_lessons for an explicit list of subscriptions (#7 H-002).

        Faster than `recalculate_for_bookings` when the bulkChange caller already
        knows which subscriptions are impacted (typical for time-shift / day-shift
        operations that don't materialize fresh booking rows).

        Returns {subscription_id: new_scheduled_lessons}. Unknown ids are silently
        skipped to keep the call defensive against stale inputs.
        """
        unique_ids = {sid for sid in subscription_ids if sid}
        result: dict[str, int] = {}
        for sub_id in unique_ids:
            sub = await self.db.get(Subscription, sub_id)
            if sub is None:
                continue
            result[sub_id] = await self.recalculate_scheduled_lessons(sub_id)
        return result


__all__ = [
    "DEFAULT_EXPIRY_DAYS",
    "MakeupCreditService",
]
