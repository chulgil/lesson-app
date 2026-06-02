"""Vacation return announcement cron tests — #4 H-001 §6.3."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta, timezone
from uuid import uuid4

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.alimtalk_client import MockAlimTalkClient
from app.jobs.vacation_return_jobs import run_vacation_return_announcement
from app.models.alimtalk_log import AlimTalkLog, AlimTalkTemplate
from app.models.lesson import ClassMembership, LessonClass
from app.models.schedule import (
    BookingLessonType,
    BookingStatus,
    LessonBooking,
    VacationPeriod,
)
from app.models.student import Student
from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

_KST = timezone(timedelta(hours=9))


def _reset_shared_mock_client() -> MockAlimTalkClient:
    import app.services.alimtalk_service as svc

    svc._shared_mock_client = MockAlimTalkClient()  # type: ignore[attr-defined]
    return svc._shared_mock_client  # type: ignore[attr-defined]


async def _seed_student_with_booking(
    db: AsyncSession,
    teacher_id: str,
    *,
    name: str,
    phone: str | None,
    parent_phone: str | None,
    scheduled: date,
) -> str:
    student_id = f"student-{uuid4()}"
    db.add(
        Student(
            id=student_id,
            teacher_id=teacher_id,
            name=name,
            phone=phone,
            parent_phone=parent_phone,
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
            start_date=date(2026, 6, 1),
            end_date=date(2026, 7, 31),
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
    return student_id


def _yesterday_kst() -> date:
    return (datetime.now(UTC).astimezone(_KST).date()) - timedelta(days=1)


@pytest.mark.asyncio
async def test_cron_announces_return_for_vacations_ended_yesterday(
    db_session: AsyncSession,
):
    """One announce per impacted student/phone for vacations ending yesterday."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-return-1"
    yesterday = _yesterday_kst()

    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="A",
        phone="010-1111-1111",
        parent_phone=None,
        scheduled=yesterday - timedelta(days=2),
    )
    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="B",
        phone=None,
        parent_phone="010-2222-2222",
        scheduled=yesterday - timedelta(days=1),
    )

    db_session.add(
        VacationPeriod(
            id=f"vac-{uuid4()}",
            teacher_id=teacher_id,
            start_date=yesterday - timedelta(days=4),
            end_date=yesterday,
        )
    )
    await db_session.commit()

    result = await run_vacation_return_announcement(db_session)
    assert result["periods"] == 1
    assert result["sent"] == 2

    sent_phones = {entry[1] for entry in mock.sent}
    assert sent_phones == {"010-1111-1111", "010-2222-2222"}
    assert all(entry[0] == AlimTalkTemplate.teacher_vacation_returned.value for entry in mock.sent)


@pytest.mark.asyncio
async def test_cron_skips_cancelled_vacations(db_session: AsyncSession):
    """Cancelled vacations are excluded even if end_date matches."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-return-2"
    yesterday = _yesterday_kst()

    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="X",
        phone="010-3333-3333",
        parent_phone=None,
        scheduled=yesterday - timedelta(days=1),
    )

    db_session.add(
        VacationPeriod(
            id=f"vac-{uuid4()}",
            teacher_id=teacher_id,
            start_date=yesterday - timedelta(days=2),
            end_date=yesterday,
            cancelled_at=datetime.now(UTC),
        )
    )
    await db_session.commit()

    result = await run_vacation_return_announcement(db_session)
    assert result["periods"] == 0
    assert result["sent"] == 0
    assert mock.sent == []


@pytest.mark.asyncio
async def test_cron_skips_vacations_ending_other_days(db_session: AsyncSession):
    """Only vacations whose end_date equals yesterday in KST trigger the cron."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-return-3"
    yesterday = _yesterday_kst()

    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="Y",
        phone="010-4444-4444",
        parent_phone=None,
        scheduled=yesterday - timedelta(days=5),
    )

    db_session.add(
        VacationPeriod(
            id=f"vac-too-early-{uuid4()}",
            teacher_id=teacher_id,
            start_date=yesterday - timedelta(days=10),
            end_date=yesterday - timedelta(days=5),
        )
    )
    db_session.add(
        VacationPeriod(
            id=f"vac-future-{uuid4()}",
            teacher_id=teacher_id,
            start_date=yesterday + timedelta(days=2),
            end_date=yesterday + timedelta(days=5),
        )
    )
    await db_session.commit()

    result = await run_vacation_return_announcement(db_session)
    assert result["periods"] == 0
    assert mock.sent == []


@pytest.mark.asyncio
async def test_cron_is_idempotent_across_runs(db_session: AsyncSession):
    """Re-running the cron the same day does not duplicate alimtalk rows."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-return-4"
    yesterday = _yesterday_kst()
    period_id = f"vac-{uuid4()}"

    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="Idem",
        phone="010-5555-5555",
        parent_phone=None,
        scheduled=yesterday - timedelta(days=1),
    )

    db_session.add(
        VacationPeriod(
            id=period_id,
            teacher_id=teacher_id,
            start_date=yesterday - timedelta(days=3),
            end_date=yesterday,
        )
    )
    await db_session.commit()

    first = await run_vacation_return_announcement(db_session)
    second = await run_vacation_return_announcement(db_session)

    # Both runs report the success log they observed — `sent` counts success
    # rows, not new carrier hits. Idempotency is verified by:
    #   * carrier was hit only once (mock.sent)
    #   * exactly one alimtalk_log row exists for this (period, phone, template)
    assert first["sent"] == 1
    assert second["sent"] == 1
    assert len(mock.sent) == 1  # carrier was not called the second time
    logs = (
        await db_session.scalars(
            select(AlimTalkLog).where(
                AlimTalkLog.vacation_period_id == period_id,
                AlimTalkLog.template_id == AlimTalkTemplate.teacher_vacation_returned.value,
            )
        )
    ).all()
    assert len(logs) == 1
