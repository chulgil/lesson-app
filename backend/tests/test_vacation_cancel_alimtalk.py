"""LNZ_TEACHER_VACATION_CANCELLED Recovery fan-out — #4 H-001 §7.3."""

from __future__ import annotations

from datetime import UTC, date, datetime
from uuid import uuid4

import pytest
from freezegun import freeze_time
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

# UTC 03:00 = KST 12:00 → inside the alimtalk 08:00-20:00 KST send window.
# Far-future vacation dates (year 2126) keep the cancel within the recovery
# window regardless; freezing only pins the alimtalk send-window clock.
_IN_WINDOW_UTC = "2026-06-01 03:00:00"


async def _seed_student_with_booking(
    db: AsyncSession,
    teacher_id: str,
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


def _reset_shared_mock_client() -> MockAlimTalkClient:
    import app.services.alimtalk_service as svc

    svc._shared_mock_client = MockAlimTalkClient()  # type: ignore[attr-defined]
    return svc._shared_mock_client  # type: ignore[attr-defined]


@pytest.mark.asyncio
@freeze_time(_IN_WINDOW_UTC)
async def test_cancel_vacation_fans_out_one_cancelled_alimtalk_per_student(
    db_session: AsyncSession,
):
    """Cancellation sends LNZ_TEACHER_VACATION_CANCELLED to every impacted student."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-cancel-1"
    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="A",
        phone="010-1111-1111",
        parent_phone=None,
        scheduled=date(2126, 8, 2),
    )
    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="B",
        phone=None,
        parent_phone="010-2222-2222",
        scheduled=date(2126, 8, 4),
    )
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
    # 2 announce sends so far.
    assert len(mock.sent) == 2

    await service.cancel_vacation(period_resp.id, teacher_id)

    # 2 cancellation sends in addition.
    cancelled_sends = [e for e in mock.sent if e[0] == AlimTalkTemplate.teacher_vacation_cancelled.value]
    assert {e[1] for e in cancelled_sends} == {"010-1111-1111", "010-2222-2222"}
    assert len(cancelled_sends) == 2

    logs = (
        await db_session.scalars(
            select(AlimTalkLog).where(
                AlimTalkLog.vacation_period_id == period_resp.id,
                AlimTalkLog.template_id == AlimTalkTemplate.teacher_vacation_cancelled.value,
            )
        )
    ).all()
    assert {log.recipient_phone for log in logs} == {"010-1111-1111", "010-2222-2222"}


@pytest.mark.asyncio
@freeze_time(_IN_WINDOW_UTC)
async def test_cancel_vacation_alimtalk_is_idempotent_per_phone(
    db_session: AsyncSession,
):
    """Repeated cancel calls (theoretical) don't duplicate the cancellation row."""
    mock = _reset_shared_mock_client()
    teacher_id = "teacher-cancel-2"
    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="Idem",
        phone="010-9999-9999",
        parent_phone=None,
        scheduled=date(2126, 8, 2),
    )
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
    period = await db_session.get(VacationPeriod, period_resp.id)

    # First Recovery fan-out (no DB-side cancel, just exercise the method).
    student_ids = await service._cancelled_student_ids_for_period(period)
    await service._send_vacation_cancelled_alimtalk(period, student_ids)
    await service._send_vacation_cancelled_alimtalk(period, student_ids)  # double-tap

    cancelled_sends = [e for e in mock.sent if e[0] == AlimTalkTemplate.teacher_vacation_cancelled.value]
    assert len(cancelled_sends) == 1  # idempotency held


@pytest.mark.asyncio
async def test_cancel_vacation_continues_when_alimtalk_raises(
    db_session: AsyncSession,
):
    """Cancellation still succeeds even when the alimtalk pipeline raises."""
    import app.services.alimtalk_service as svc

    class _Boom:
        async def send(self, **kwargs):  # noqa: ANN001, D401
            raise RuntimeError("vendor down")

    svc._shared_mock_client = _Boom()  # type: ignore[attr-defined]

    teacher_id = "teacher-cancel-3"
    await _seed_student_with_booking(
        db_session,
        teacher_id,
        name="Boom",
        phone="010-4444-4444",
        parent_phone=None,
        scheduled=date(2126, 8, 2),
    )
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

    cancelled = await service.cancel_vacation(period_resp.id, teacher_id)
    assert cancelled.cancelled_at is not None

    cancelled_logs = (
        await db_session.scalars(
            select(AlimTalkLog).where(
                AlimTalkLog.vacation_period_id == period_resp.id,
                AlimTalkLog.template_id == AlimTalkTemplate.teacher_vacation_cancelled.value,
            )
        )
    ).all()
    assert len(cancelled_logs) == 1
    assert cancelled_logs[0].success is False
