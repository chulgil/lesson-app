"""MakeupCredit (#432 G3) — model + service tests.

Spec: docs/specs/subscription/makeup_credit_spec.md
Covers:
- Accrual (4 sources + fifthWeekBonus).
- Use (success + already-used + expired errors).
- Active vs expired filtering.
- scheduled_lessons recalculation on a subscription.
- Non-negative CHECK constraint for scheduled_lessons.
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import ClassMembership, LessonClass
from app.models.makeup_credit import MakeupCreditReason
from app.models.schedule import BookingStatus, LessonBooking
from app.models.student import Student
from app.models.subscription import Subscription, SubscriptionType
from app.models.teacher import Teacher
from app.services.makeup_credit_service import (
    DEFAULT_EXPIRY_DAYS,
    MakeupCreditService,
)


def _utcnow() -> datetime:
    return datetime.now(UTC)


# ----------------------------------------------------------------------
# Fixtures
# ----------------------------------------------------------------------


async def _make_pair(
    db_session: AsyncSession,
    *,
    teacher_id: str = "t-1",
    student_id: str = "s-1",
) -> tuple[str, str]:
    """Insert a Teacher + Student row pair so FK constraints pass.

    Returns (teacher_id, student_id). Idempotent per test (each test gets a
    fresh DB via conftest setup_db).
    """
    teacher = Teacher(id=teacher_id, user_id=f"{teacher_id}-user", instruments=[])
    student = Student(id=student_id, name="S", instrument="violin")
    db_session.add_all([teacher, student])
    await db_session.flush()
    return teacher_id, student_id


async def _make_subscription(
    db_session: AsyncSession,
    *,
    student_id: str,
    teacher_id: str,
    total_lessons: int = 8,
    used_lessons: int = 0,
    sub_id: str = "sub-1",
) -> str:
    """Insert a minimal class membership + subscription. Returns the subscription id."""
    klass = LessonClass(
        id=f"class-{sub_id}",
        teacher_id=teacher_id,
        name="Class",
    )
    membership = ClassMembership(
        id=f"mem-{sub_id}",
        lesson_class_id=klass.id,
        student_id=student_id,
        instrument="violin",
    )
    sub = Subscription(
        id=sub_id,
        student_id=student_id,
        membership_id=membership.id,
        type=SubscriptionType.package,
        total_lessons=total_lessons,
        used_lessons=used_lessons,
        amount=0,
    )
    db_session.add_all([klass, membership, sub])
    await db_session.flush()
    return sub_id


# ----------------------------------------------------------------------
# Accrual
# ----------------------------------------------------------------------


@pytest.mark.asyncio
async def test_accrue_for_no_show_exempt_creates_credit_with_30d_expiry(
    db_session: AsyncSession,
) -> None:
    """Spec §4.2 — no-show exempt: 1 credit, 30-day expiry."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)

    before = _utcnow()
    credit = await service.accrue_for_no_show_exempt(
        student_id=student_id,
        teacher_id=teacher_id,
        lesson_id="lesson-1",
    )
    after = _utcnow()

    assert credit.reason == MakeupCreditReason.noShowExempt
    assert credit.student_id == student_id
    assert credit.teacher_id == teacher_id
    assert credit.source_event_id == "lesson-1"
    assert credit.source_lesson_id == "lesson-1"
    assert credit.used_at is None
    expected_min = before + timedelta(days=DEFAULT_EXPIRY_DAYS) - timedelta(seconds=2)
    expected_max = after + timedelta(days=DEFAULT_EXPIRY_DAYS) + timedelta(seconds=2)
    assert expected_min <= credit.expires_at <= expected_max


@pytest.mark.asyncio
async def test_accrue_for_vacation_uses_vacation_end_plus_30d(db_session: AsyncSession) -> None:
    """Spec §4.1 — vacation credit expires at vacation_end + 30d."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)
    vacation_end = datetime(2026, 8, 31, tzinfo=UTC)

    credit = await service.accrue_for_vacation(
        student_id=student_id,
        teacher_id=teacher_id,
        vacation_id="vac-1",
        vacation_end_date=vacation_end,
    )

    assert credit.reason == MakeupCreditReason.teacherVacation
    assert credit.source_event_id == "vac-1"
    assert credit.expires_at == vacation_end + timedelta(days=DEFAULT_EXPIRY_DAYS)


@pytest.mark.asyncio
async def test_accrue_for_bulk_change_loss_records_subscription_and_change_id(
    db_session: AsyncSession,
) -> None:
    """Spec §4.3 — bulk change loss credit tracks subscription + change event."""
    teacher_id, student_id = await _make_pair(db_session)
    sub_id = await _make_subscription(
        db_session,
        student_id=student_id,
        teacher_id=teacher_id,
    )
    service = MakeupCreditService(db_session)

    credit = await service.accrue_for_bulk_change_loss(
        student_id=student_id,
        teacher_id=teacher_id,
        subscription_id=sub_id,
        schedule_change_id="chg-1",
        lost_lesson_id="lesson-lost-1",
    )

    assert credit.reason == MakeupCreditReason.bulkChangeLoss
    assert credit.source_subscription_id == sub_id
    assert credit.source_event_id == "chg-1"
    assert credit.source_lesson_id == "lesson-lost-1"


@pytest.mark.asyncio
async def test_accrue_manual_and_fifth_week_bonus(db_session: AsyncSession) -> None:
    """§4.4 manual + #432 brief 5주차 보너스 accrual paths."""
    teacher_id, student_id = await _make_pair(db_session)
    sub_id = await _make_subscription(
        db_session,
        student_id=student_id,
        teacher_id=teacher_id,
    )
    service = MakeupCreditService(db_session)

    manual = await service.accrue_manual(student_id=student_id, teacher_id=teacher_id)
    bonus = await service.accrue_fifth_week_bonus(
        student_id=student_id,
        teacher_id=teacher_id,
        subscription_id=sub_id,
    )

    assert manual.reason == MakeupCreditReason.manualGrant
    assert bonus.reason == MakeupCreditReason.fifthWeekBonus
    assert bonus.source_subscription_id == sub_id


# ----------------------------------------------------------------------
# Use
# ----------------------------------------------------------------------


@pytest.mark.asyncio
async def test_use_credit_marks_used_and_links_lesson(db_session: AsyncSession) -> None:
    """Spec §5.3 — using a credit sets used_at + used_lesson_id."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)

    credit = await service.accrue_for_no_show_exempt(
        student_id=student_id,
        teacher_id=teacher_id,
        lesson_id="lesson-source",
    )
    used = await service.use_credit(credit_id=credit.id, lesson_id="lesson-future")

    assert used.used_at is not None
    assert used.used_lesson_id == "lesson-future"


@pytest.mark.asyncio
async def test_use_credit_rejects_already_used(db_session: AsyncSession) -> None:
    """Already-consumed credit cannot be reused."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)

    credit = await service.accrue_for_no_show_exempt(
        student_id=student_id,
        teacher_id=teacher_id,
        lesson_id="lesson-1",
    )
    await service.use_credit(credit_id=credit.id, lesson_id="lesson-A")

    with pytest.raises(ValueError, match="already used"):
        await service.use_credit(credit_id=credit.id, lesson_id="lesson-B")


@pytest.mark.asyncio
async def test_use_credit_rejects_expired(db_session: AsyncSession) -> None:
    """Expired credit cannot be used (spec §6.3)."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)

    expired_credit = await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=_utcnow() - timedelta(days=1),
    )

    with pytest.raises(ValueError, match="expired"):
        await service.use_credit(credit_id=expired_credit.id, lesson_id="lesson-X")


# ----------------------------------------------------------------------
# Active vs expired filtering
# ----------------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_active_credits_excludes_used_and_expired(
    db_session: AsyncSession,
) -> None:
    """Active credit list: unused AND not yet expired, FIFO by expires_at."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)
    now = _utcnow()

    # Active (latest expiry)
    active_late = await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now + timedelta(days=20),
    )
    # Active (earliest expiry — should appear first)
    active_early = await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now + timedelta(days=5),
    )
    # Used
    used = await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now + timedelta(days=15),
    )
    await service.use_credit(credit_id=used.id, lesson_id="lesson-Z")
    # Expired
    await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now - timedelta(days=1),
    )

    active_list = await service.list_active_credits(student_id=student_id)
    assert [c.id for c in active_list] == [active_early.id, active_late.id]

    assert await service.count_active_credits(student_id=student_id) == 2


@pytest.mark.asyncio
async def test_find_expired_credits(db_session: AsyncSession) -> None:
    """Spec §6.2 — expired = unused AND expires_at < now."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)
    now = _utcnow()

    expired = await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now - timedelta(days=1),
    )
    await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now + timedelta(days=10),
    )

    expired_list = await service.find_expired_credits()
    assert [c.id for c in expired_list] == [expired.id]


# ----------------------------------------------------------------------
# scheduled_lessons track
# ----------------------------------------------------------------------


@pytest.mark.asyncio
async def test_recalculate_scheduled_lessons_counts_active_bookings_only(
    db_session: AsyncSession,
) -> None:
    """Spec §3.2 / §7 — scheduled_lessons counts active bookings (pending /
    confirmed / changeRequested / completed), excludes cancelled/expired/unavailable.
    """
    teacher_id, student_id = await _make_pair(db_session)
    sub_id = await _make_subscription(
        db_session,
        student_id=student_id,
        teacher_id=teacher_id,
    )

    statuses = [
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.changeRequested,
        BookingStatus.completed,
        BookingStatus.cancelled,
        BookingStatus.expired,
        BookingStatus.unavailable,
    ]
    for idx, status in enumerate(statuses):
        db_session.add(
            LessonBooking(
                id=f"booking-{idx}",
                teacher_id=teacher_id,
                student_id=student_id,
                scheduled_date=date(2026, 6, 1) + timedelta(days=idx),
                scheduled_time="10:00",
                duration=60,
                subscription_id=sub_id,
                status=status,
            )
        )
    await db_session.flush()

    service = MakeupCreditService(db_session)
    new_count = await service.recalculate_scheduled_lessons(sub_id)
    assert new_count == 4

    sub = await db_session.get(Subscription, sub_id)
    assert sub is not None
    assert sub.scheduled_lessons == 4


@pytest.mark.asyncio
async def test_recalculate_scheduled_lessons_drops_to_zero_after_all_cancelled(
    db_session: AsyncSession,
) -> None:
    """Regression for spec §7 — bulkChange cancels existing bookings; recompute
    must reflect that (no stale count)."""
    teacher_id, student_id = await _make_pair(db_session)
    sub_id = await _make_subscription(
        db_session,
        student_id=student_id,
        teacher_id=teacher_id,
    )

    booking = LessonBooking(
        id="b-1",
        teacher_id=teacher_id,
        student_id=student_id,
        scheduled_date=date(2026, 6, 1),
        scheduled_time="10:00",
        duration=60,
        subscription_id=sub_id,
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()

    service = MakeupCreditService(db_session)
    assert await service.recalculate_scheduled_lessons(sub_id) == 1

    booking.status = BookingStatus.cancelled
    await db_session.flush()

    assert await service.recalculate_scheduled_lessons(sub_id) == 0
    sub = await db_session.get(Subscription, sub_id)
    assert sub is not None
    assert sub.scheduled_lessons == 0


# ----------------------------------------------------------------------
# Constraint
# ----------------------------------------------------------------------


@pytest.mark.asyncio
async def test_subscription_scheduled_lessons_non_negative(
    db_session: AsyncSession,
) -> None:
    """Updated CHECK ck_subscriptions_non_negative_counters blocks negative scheduled_lessons."""
    teacher_id, student_id = await _make_pair(db_session)
    sub_id = await _make_subscription(
        db_session,
        student_id=student_id,
        teacher_id=teacher_id,
    )
    sub = await db_session.get(Subscription, sub_id)
    assert sub is not None
    sub.scheduled_lessons = -1
    with pytest.raises(IntegrityError):
        await db_session.flush()


@pytest.mark.asyncio
async def test_use_oldest_active_credit_for_student_consumes_fifo(
    db_session: AsyncSession,
) -> None:
    """Convenience method picks the earliest-expiring active credit (FIFO)."""
    teacher_id, student_id = await _make_pair(db_session)
    service = MakeupCreditService(db_session)
    now = _utcnow()

    later = await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now + timedelta(days=20),
    )
    earlier = await service.accrue(
        student_id=student_id,
        teacher_id=teacher_id,
        reason=MakeupCreditReason.manualGrant,
        expires_at=now + timedelta(days=5),
    )

    consumed = await service.use_oldest_active_credit_for_student(
        student_id=student_id,
        teacher_id=teacher_id,
        lesson_id="lesson-FIFO",
    )
    assert consumed is not None
    assert consumed.id == earlier.id
    assert consumed.used_lesson_id == "lesson-FIFO"

    # Confirm one active credit remains (the later-expiring one).
    remaining = await service.list_active_credits(student_id=student_id)
    assert [c.id for c in remaining] == [later.id]
