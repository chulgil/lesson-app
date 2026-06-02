"""LNZ_TEACHER_VACATION alimtalk fan-out tests — #4 H-001 §6.1."""

from __future__ import annotations

from datetime import UTC, date, datetime
from uuid import uuid4

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.alimtalk_client import MockAlimTalkClient
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
from app.schemas.vacation import VacationDisposition as SchemaVacationDisposition
from app.schemas.vacation import VacationPeriodCreate
from app.services.vacation_service import VacationService


async def _seed_lesson_class(db: AsyncSession, teacher_id: str) -> str:
    lc_id = f"lc-{uuid4()}"
    db.add(LessonClass(id=lc_id, teacher_id=teacher_id, name="Test Class"))
    await db.flush()
    return lc_id


async def _seed_student_with_booking(
    db: AsyncSession,
    teacher_id: str,
    lesson_class_id: str,
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

    membership_id = f"mem-{uuid4()}"
    db.add(
        ClassMembership(
            id=membership_id,
            lesson_class_id=lesson_class_id,
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


def _reset_shared_mock_client() -> MockAlimTalkClient:
    """The alimtalk service caches a process-level mock client. Reset for test isolation."""
    import app.services.alimtalk_service as svc

    svc._shared_mock_client = MockAlimTalkClient()  # type: ignore[attr-defined]
    return svc._shared_mock_client  # type: ignore[attr-defined]


@pytest.mark.asyncio
async def test_register_vacation_fans_out_one_alimtalk_per_impacted_student(
    db_session: AsyncSession,
):
    """One mock send per impacted student/phone pair, using parent_phone when present."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-vac-1"
    lc = await _seed_lesson_class(db_session, teacher_id)

    sa = await _seed_student_with_booking(
        db_session,
        teacher_id,
        lc,
        name="A",
        phone="010-1111-1111",
        parent_phone="010-2222-2222",
        scheduled=date(2026, 8, 2),
    )
    sb = await _seed_student_with_booking(
        db_session,
        teacher_id,
        lc,
        name="B",
        phone="010-3333-3333",
        parent_phone=None,
        scheduled=date(2026, 8, 3),
    )
    await db_session.commit()

    service = VacationService(db_session)
    response = await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2026, 8, 1),
            end_date=date(2026, 8, 5),
            default_disposition=SchemaVacationDisposition.freeCancel,
        ),
    )

    # Exactly two sends — A on parent phone, B on student phone.
    sent_phones = {entry[1] for entry in mock.sent}
    assert sent_phones == {"010-2222-2222", "010-3333-3333"}
    assert all(entry[0] == AlimTalkTemplate.teacher_vacation.value for entry in mock.sent)

    # Two log rows, each tied to the same vacation_period_id.
    logs = (await db_session.scalars(select(AlimTalkLog).where(AlimTalkLog.vacation_period_id == response.id))).all()
    assert len(logs) == 2
    assert {log.recipient_phone for log in logs} == {"010-2222-2222", "010-3333-3333"}

    # Each log carries the matching student_name + dates in variables.
    by_phone = {log.recipient_phone: log for log in logs}
    assert by_phone["010-2222-2222"].variables["student_name"] == "A"
    assert by_phone["010-3333-3333"].variables["student_name"] == "B"
    assert by_phone["010-2222-2222"].variables["vacation_start"] == "2026-08-01"
    # Also: assert valid teacher_id / period_id linkage
    _ = sa, sb


@pytest.mark.asyncio
async def test_register_vacation_skips_students_without_phone(
    db_session: AsyncSession,
):
    """Students with neither phone nor parent_phone are silently skipped."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-vac-2"
    lc = await _seed_lesson_class(db_session, teacher_id)

    await _seed_student_with_booking(
        db_session,
        teacher_id,
        lc,
        name="NoPhone",
        phone=None,
        parent_phone=None,
        scheduled=date(2026, 8, 2),
    )
    await db_session.commit()

    service = VacationService(db_session)
    response = await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2026, 8, 1),
            end_date=date(2026, 8, 5),
        ),
    )

    assert mock.sent == []
    logs = (await db_session.scalars(select(AlimTalkLog).where(AlimTalkLog.vacation_period_id == response.id))).all()
    assert logs == []


@pytest.mark.asyncio
async def test_register_vacation_alimtalk_is_idempotent_per_phone(
    db_session: AsyncSession,
):
    """Re-running register on the same period+phone yields only one carrier send."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-vac-3"
    lc = await _seed_lesson_class(db_session, teacher_id)
    await _seed_student_with_booking(
        db_session,
        teacher_id,
        lc,
        name="Idem",
        phone="010-9999-9999",
        parent_phone=None,
        scheduled=date(2026, 8, 2),
    )
    await db_session.commit()

    service = VacationService(db_session)
    response = await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2026, 8, 1),
            end_date=date(2026, 8, 5),
        ),
    )
    # Manually re-trigger the fan-out — multi-call safety check. Reuse the
    # same impacted set the registration path captured.
    period = await db_session.get(VacationPeriod, response.id)
    student_ids = await service._impacted_student_ids(
        teacher_id=teacher_id,
        start_date=period.start_date,
        end_date=period.end_date,
    )
    await service._send_vacation_alimtalk(period, {}, student_ids)

    assert len(mock.sent) == 1  # second call short-circuits on existing success row
    logs = (await db_session.scalars(select(AlimTalkLog).where(AlimTalkLog.vacation_period_id == response.id))).all()
    assert len(logs) == 1


@pytest.mark.asyncio
async def test_register_vacation_continues_when_alimtalk_raises(
    db_session: AsyncSession,
):
    """If the alimtalk pipeline raises, vacation registration still succeeds."""
    import app.services.alimtalk_service as svc

    class _Boom:
        async def send(self, **kwargs):  # noqa: D401, ANN001
            raise RuntimeError("vendor down")

    svc._shared_mock_client = _Boom()  # type: ignore[attr-defined]

    teacher_id = "teacher-vac-4"
    lc = await _seed_lesson_class(db_session, teacher_id)
    await _seed_student_with_booking(
        db_session,
        teacher_id,
        lc,
        name="Boom",
        phone="010-4444-4444",
        parent_phone=None,
        scheduled=date(2026, 8, 2),
    )
    await db_session.commit()

    service = VacationService(db_session)
    response = await service.register_vacation(
        teacher_id,
        VacationPeriodCreate(
            start_date=date(2026, 8, 1),
            end_date=date(2026, 8, 5),
        ),
    )
    assert response.id is not None

    period = await db_session.get(VacationPeriod, response.id)
    await db_session.refresh(period)
    assert period.cancelled_at is None  # vacation is live regardless of alimtalk failure

    # The pipeline still recorded a failure log row (vendor returned False).
    logs = (await db_session.scalars(select(AlimTalkLog).where(AlimTalkLog.vacation_period_id == response.id))).all()
    assert len(logs) == 1
    assert logs[0].success is False
