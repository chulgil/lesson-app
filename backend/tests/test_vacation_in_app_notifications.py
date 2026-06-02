"""Vacation in-app notification dispatch — #4 H-001 §6.2.

Spec: docs/specs/schedule/teacher_vacation_mode.md §6.2.

Each impacted student receives one in-app notification per vacation register,
with a disposition-aware body:
  - rollForward   → "만료일 N일 연장됨"
  - freeCancel    → "N건 무료 취소됨"
  - makeupCredit  → "보강 N회 적립됨"
"""

from __future__ import annotations

from datetime import UTC, date, datetime
from uuid import uuid4

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import ClassMembership, LessonClass
from app.models.notification import Notification
from app.models.schedule import (
    BookingLessonType,
    BookingStatus,
    LessonBooking,
    VacationPeriod,
)
from app.models.student import Student
from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType
from app.models.user import User, UserRole
from app.schemas.vacation import VacationDisposition as SchemaVacationDisposition
from app.schemas.vacation import VacationPeriodCreate
from app.services.vacation_service import VacationService


async def _seed_student(
    db: AsyncSession,
    teacher_id: str,
    *,
    name: str,
    scheduled: date,
    user_role: UserRole = UserRole.student,
) -> tuple[str, str]:
    """Create Student + linked User + lesson booking. Returns (student_id, user_id)."""
    user_id = f"user-{uuid4()}"
    db.add(
        User(
            id=user_id,
            email=f"{user_id}@test.com",
            role=user_role,
            name=name,
            is_active=True,
        )
    )
    await db.flush()

    student_id = f"student-{uuid4()}"
    db.add(
        Student(
            id=student_id,
            teacher_id=teacher_id,
            user_id=user_id,
            name=name,
        )
    )
    await db.flush()

    lc_id = f"lc-{uuid4()}"
    db.add(LessonClass(id=lc_id, teacher_id=teacher_id, name="Test Class"))
    await db.flush()
    membership_id = f"mem-{uuid4()}"
    db.add(
        ClassMembership(
            id=membership_id,
            lesson_class_id=lc_id,
            student_id=student_id,
            instrument="violin",
            lesson_duration=60,
        )
    )
    await db.flush()
    sub_id = f"sub-{uuid4()}"
    db.add(
        Subscription(
            id=sub_id,
            student_id=student_id,
            membership_id=membership_id,
            type=SubscriptionType.monthly,
            lessons_per_month=4,
            used_lessons=0,
            start_date=date(2126, 7, 1),
            end_date=date(2126, 8, 31),
            amount=200000,
            status=SubscriptionStatus.active,
            payment_confirmed=True,
            paid_at=datetime.now(UTC),
            payment_confirmed_at=datetime.now(UTC),
        )
    )
    await db.flush()
    db.add(
        LessonBooking(
            id=f"booking-{uuid4()}",
            teacher_id=teacher_id,
            student_id=student_id,
            lesson_type=BookingLessonType.regular,
            scheduled_date=scheduled,
            scheduled_time="14:00",
            duration=60,
            subscription_id=sub_id,
            status=BookingStatus.confirmed,
        )
    )
    await db.flush()
    return student_id, user_id


async def _notifications_for_user(db: AsyncSession, user_id: str) -> list[Notification]:
    return (await db.scalars(select(Notification).where(Notification.user_id == user_id))).all()


@pytest.mark.parametrize(
    "disposition,expected_phrase",
    [
        (SchemaVacationDisposition.rollForward, "연장"),
        (SchemaVacationDisposition.freeCancel, "무료 취소"),
        (SchemaVacationDisposition.makeupCredit, "보강"),
    ],
)
@pytest.mark.asyncio
async def test_vacation_register_dispatches_in_app_per_disposition(
    db_session: AsyncSession,
    disposition: SchemaVacationDisposition,
    expected_phrase: str,
):
    """Each disposition yields a disposition-aware in-app body for the student."""
    teacher_id = f"teacher-in-app-{disposition.value}"
    _, student_user_id = await _seed_student(db_session, teacher_id, name="A", scheduled=date(2126, 8, 2))
    await db_session.commit()

    service = VacationService(db_session)
    await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2126, 8, 1),
            end_date=date(2126, 8, 5),
            default_disposition=disposition,
        ),
    )

    notifications = await _notifications_for_user(db_session, student_user_id)
    teacher_vacation = [n for n in notifications if n.type == "teacherVacation"]
    assert len(teacher_vacation) == 1
    assert expected_phrase in teacher_vacation[0].body


@pytest.mark.asyncio
async def test_vacation_register_skips_in_app_for_student_without_user_link(
    db_session: AsyncSession,
):
    """A Student row not linked to a User cannot receive an in-app notification."""
    teacher_id = "teacher-no-link"
    student_id = f"student-{uuid4()}"
    db_session.add(Student(id=student_id, teacher_id=teacher_id, name="NoUser"))
    await db_session.flush()
    lc_id = f"lc-{uuid4()}"
    db_session.add(LessonClass(id=lc_id, teacher_id=teacher_id, name="Test Class"))
    await db_session.flush()
    membership_id = f"mem-{uuid4()}"
    db_session.add(
        ClassMembership(
            id=membership_id,
            lesson_class_id=lc_id,
            student_id=student_id,
            instrument="violin",
            lesson_duration=60,
        )
    )
    await db_session.flush()
    sub_id = f"sub-{uuid4()}"
    db_session.add(
        Subscription(
            id=sub_id,
            student_id=student_id,
            membership_id=membership_id,
            type=SubscriptionType.monthly,
            lessons_per_month=4,
            used_lessons=0,
            start_date=date(2126, 7, 1),
            end_date=date(2126, 8, 31),
            amount=200000,
            status=SubscriptionStatus.active,
            payment_confirmed=True,
            paid_at=datetime.now(UTC),
            payment_confirmed_at=datetime.now(UTC),
        )
    )
    await db_session.flush()
    db_session.add(
        LessonBooking(
            id=f"booking-{uuid4()}",
            teacher_id=teacher_id,
            student_id=student_id,
            lesson_type=BookingLessonType.regular,
            scheduled_date=date(2126, 8, 2),
            scheduled_time="14:00",
            duration=60,
            subscription_id=sub_id,
            status=BookingStatus.confirmed,
        )
    )
    await db_session.commit()

    service = VacationService(db_session)
    await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2126, 8, 1),
            end_date=date(2126, 8, 5),
            default_disposition=SchemaVacationDisposition.freeCancel,
        ),
    )
    # Should not raise. No notification was created (no user linkage).
    all_notifications = (await db_session.scalars(select(Notification))).all()
    teacher_vacation = [n for n in all_notifications if n.type == "teacherVacation"]
    assert teacher_vacation == []


@pytest.mark.asyncio
async def test_cancel_vacation_dispatches_in_app_per_student(
    db_session: AsyncSession,
):
    """spec §7.3 — cancellation in-app mirror for every impacted student."""
    teacher_id = "teacher-cancel-in-app"
    _, user_a = await _seed_student(db_session, teacher_id, name="A", scheduled=date(2126, 8, 2))
    _, user_b = await _seed_student(db_session, teacher_id, name="B", scheduled=date(2126, 8, 3))
    await db_session.commit()

    service = VacationService(db_session)
    period_resp = await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2126, 8, 1),
            end_date=date(2126, 8, 5),
            default_disposition=SchemaVacationDisposition.freeCancel,
        ),
    )
    await service.cancel_vacation(period_resp.id, teacher_id)

    for user_id in (user_a, user_b):
        notifs = await _notifications_for_user(db_session, user_id)
        cancelled = [n for n in notifs if n.type == "teacherVacationCancelled"]
        assert len(cancelled) == 1, f"expected 1 cancelled in-app for {user_id}"
        assert "취소" in cancelled[0].body


@pytest.mark.asyncio
async def test_return_cron_dispatches_in_app_per_student(
    db_session: AsyncSession,
):
    """spec §6.3 — daily cron in-app companion."""
    from datetime import timedelta, timezone

    from app.jobs.vacation_return_jobs import run_vacation_return_announcement

    teacher_id = "teacher-return-in-app"
    yesterday = (datetime.now(UTC).astimezone(timezone(timedelta(hours=9))).date()) - timedelta(days=1)

    _, user_a = await _seed_student(db_session, teacher_id, name="A", scheduled=yesterday - timedelta(days=2))
    db_session.add(
        VacationPeriod(
            id=f"vac-{uuid4()}",
            teacher_id=teacher_id,
            start_date=yesterday - timedelta(days=4),
            end_date=yesterday,
        )
    )
    await db_session.commit()

    await run_vacation_return_announcement(db_session)

    notifs = await _notifications_for_user(db_session, user_a)
    returned = [n for n in notifs if n.type == "teacherVacationReturned"]
    assert len(returned) == 1
    assert "복귀" in returned[0].body


@pytest.mark.asyncio
async def test_vacation_register_per_student_override_drives_in_app_body(
    db_session: AsyncSession,
):
    """Per-student disposition overrides default for that student's in-app body."""
    teacher_id = "teacher-override"
    _, user_a = await _seed_student(db_session, teacher_id, name="A", scheduled=date(2126, 8, 2))
    student_b_id, user_b = await _seed_student(db_session, teacher_id, name="B", scheduled=date(2126, 8, 3))
    await db_session.commit()

    service = VacationService(db_session)
    await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2126, 8, 1),
            end_date=date(2126, 8, 5),
            default_disposition=SchemaVacationDisposition.rollForward,
            per_student_disposition={student_b_id: SchemaVacationDisposition.freeCancel},
        ),
    )

    a_notifs = await _notifications_for_user(db_session, user_a)
    b_notifs = await _notifications_for_user(db_session, user_b)
    a_vac = [n for n in a_notifs if n.type == "teacherVacation"]
    b_vac = [n for n in b_notifs if n.type == "teacherVacation"]
    assert len(a_vac) == 1 and "연장" in a_vac[0].body
    assert len(b_vac) == 1 and "무료 취소" in b_vac[0].body
