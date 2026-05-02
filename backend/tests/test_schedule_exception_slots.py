"""Tests for ScheduleException filtering in get_available_slots (#236)."""

from datetime import date

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
from app.models.schedule_ext import ExceptionType, ScheduleException
from app.services.schedule_service import ScheduleService


async def _seed_availability(db: AsyncSession, teacher_id: str = "test-user-id") -> str:
    """Create a TeacherAvailability + time slot (09:00-12:00) for Monday. Returns avail.id."""
    avail = TeacherAvailability(
        id="avail-1",
        teacher_id=teacher_id,
        day_of_week=0,  # Monday
    )
    db.add(avail)

    ts = AvailabilityTimeSlot(
        id="ts-1",
        availability_id=avail.id,
        start_time="09:00",
        end_time="12:00",
    )
    db.add(ts)
    await db.flush()
    return avail.id


@pytest.mark.asyncio
async def test_whole_day_exception_blocks_all_slots(db_session: AsyncSession):
    """Whole-day holiday exception marks all slots as unavailable."""
    avail_id = await _seed_availability(db_session)

    # Add whole-day holiday (no start_time/end_time)
    exc = ScheduleException(
        id="exc-1",
        teacher_availability_id=avail_id,
        type=ExceptionType.holiday,
        start_date=date(2026, 5, 4),
        end_date=date(2026, 5, 4),
        start_time=None,
        end_time=None,
    )
    db_session.add(exc)
    await db_session.flush()

    svc = ScheduleService(db_session)
    # 2026-05-04 is a Monday
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-05-04")

    assert len(result.slots) > 0, "Should still return slots (for UI disabled display)"
    for slot in result.slots:
        assert slot.status == "unavailable", f"Slot {slot.start_time} should be unavailable"


@pytest.mark.asyncio
async def test_partial_exception_blocks_overlapping_slots(db_session: AsyncSession):
    """Partial exception (10:00-11:00) blocks only overlapping slots."""
    avail_id = await _seed_availability(db_session)

    # Add partial vacation (10:00-11:00)
    exc = ScheduleException(
        id="exc-2",
        teacher_availability_id=avail_id,
        type=ExceptionType.vacation,
        start_date=date(2026, 5, 4),
        end_date=date(2026, 5, 4),
        start_time="10:00",
        end_time="11:00",
    )
    db_session.add(exc)
    await db_session.flush()

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-05-04")

    statuses = {s.start_time: s.status for s in result.slots}

    # 09:00-10:00 should be available (no overlap)
    assert statuses["09:00"] == "available"
    # 10:00-11:00 overlaps the exception fully
    assert statuses["10:00"] == "unavailable"
    # 10:30-11:30 overlaps the exception partially
    assert statuses["10:30"] == "unavailable"
    # 11:00-12:00 should be available (exception ends at 11:00, no overlap)
    assert statuses["11:00"] == "available"
    # 09:30-10:30 overlaps the exception partially
    assert statuses["09:30"] == "unavailable"


@pytest.mark.asyncio
async def test_no_exception_returns_all_available(db_session: AsyncSession):
    """Without exceptions, all slots are available."""
    await _seed_availability(db_session)

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-05-04")

    assert len(result.slots) > 0
    for slot in result.slots:
        assert slot.status == "available", f"Slot {slot.start_time} should be available"
