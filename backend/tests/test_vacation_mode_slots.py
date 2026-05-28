"""Tests for TeacherAvailability.vacation_mode blocking in get_available_slots (#380).

방학 모드(TeacherAvailability.vacation_mode)와 ScheduleException(type=vacation)은
독립적으로 동작해야 한다. 두 메커니즘이 서로의 역할을 침범하지 않는지 검증.
"""

from datetime import date

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
from app.models.schedule_ext import ExceptionType, ScheduleException
from app.services.schedule_service import ScheduleService


async def _seed_availability(
    db: AsyncSession,
    teacher_id: str = "test-user-id",
    *,
    vacation_mode: bool = False,
    vacation_start: date | None = None,
    vacation_end: date | None = None,
) -> str:
    """Seed a Monday 09:00-12:00 availability slot with optional vacation_mode."""
    avail = TeacherAvailability(
        id="avail-vac-1",
        teacher_id=teacher_id,
        day_of_week=0,  # Monday
        vacation_mode=vacation_mode,
        vacation_start_date=vacation_start,
        vacation_end_date=vacation_end,
    )
    db.add(avail)
    db.add(
        AvailabilityTimeSlot(
            id="ts-vac-1",
            availability_id=avail.id,
            start_time="09:00",
            end_time="12:00",
        )
    )
    await db.flush()
    return avail.id


@pytest.mark.asyncio
async def test_vacation_mode_blocks_all_slots_within_range(db_session: AsyncSession):
    """vacation_mode=true 이고 슬롯 날짜가 [start, end] 사이면 모든 슬롯 unavailable."""
    await _seed_availability(
        db_session,
        vacation_mode=True,
        vacation_start=date(2026, 7, 1),
        vacation_end=date(2026, 8, 31),
    )

    svc = ScheduleService(db_session)
    # 2026-07-06 is a Monday within the vacation range
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-07-06")

    assert len(result.slots) > 0, "should still return slots for UI disabled display"
    for slot in result.slots:
        assert slot.status == "unavailable", f"Slot {slot.start_time} should be unavailable during vacation_mode"


@pytest.mark.asyncio
async def test_vacation_mode_does_not_block_outside_range(db_session: AsyncSession):
    """방학 기간 밖의 날짜는 vacation_mode 영향 없음."""
    await _seed_availability(
        db_session,
        vacation_mode=True,
        vacation_start=date(2026, 7, 1),
        vacation_end=date(2026, 8, 31),
    )

    svc = ScheduleService(db_session)
    # 2026-06-29 is a Monday before vacation_start
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-06-29")

    assert len(result.slots) > 0
    for slot in result.slots:
        assert slot.status == "available", f"Slot {slot.start_time} should be available outside vacation range"


@pytest.mark.asyncio
async def test_vacation_mode_false_ignores_dates(db_session: AsyncSession):
    """vacation_mode=false 면 vacation_start/end_date 가 있어도 무시."""
    await _seed_availability(
        db_session,
        vacation_mode=False,
        vacation_start=date(2026, 7, 1),
        vacation_end=date(2026, 8, 31),
    )

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-07-06")

    assert len(result.slots) > 0
    for slot in result.slots:
        assert slot.status == "available", f"Slot {slot.start_time} should be available when vacation_mode=false"


@pytest.mark.asyncio
async def test_vacation_mode_independent_of_schedule_exception(db_session: AsyncSession):
    """vacation_mode 와 ScheduleException(type=vacation) 은 서로 독립적으로 동작.

    같은 날짜에 두 메커니즘 모두 적용되어도 충돌 없이 unavailable 처리.
    """
    avail_id = await _seed_availability(
        db_session,
        vacation_mode=True,
        vacation_start=date(2026, 7, 1),
        vacation_end=date(2026, 8, 31),
    )

    # ScheduleException(type=vacation) 을 같은 날짜에 partial 로 추가 (10:00-11:00)
    db_session.add(
        ScheduleException(
            id="exc-vac-overlap",
            teacher_availability_id=avail_id,
            type=ExceptionType.vacation,
            start_date=date(2026, 7, 6),
            end_date=date(2026, 7, 6),
            start_time="10:00",
            end_time="11:00",
        )
    )
    await db_session.flush()

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-07-06")

    # vacation_mode 가 전체를 차단하므로 모든 슬롯이 unavailable
    for slot in result.slots:
        assert slot.status == "unavailable"


@pytest.mark.asyncio
async def test_schedule_exception_vacation_without_vacation_mode(
    db_session: AsyncSession,
):
    """ScheduleException(type=vacation) 단독은 partial blocking 만 수행 (기존 동작 보존).

    vacation_mode=false 이고 ScheduleException(type=vacation) 만 있을 때, 기존
    #236 동작 (지정된 시간만 unavailable, 나머지는 available) 이 유지되어야 한다.
    """
    avail_id = await _seed_availability(db_session, vacation_mode=False)

    db_session.add(
        ScheduleException(
            id="exc-vac-only",
            teacher_availability_id=avail_id,
            type=ExceptionType.vacation,
            start_date=date(2026, 7, 6),
            end_date=date(2026, 7, 6),
            start_time="10:00",
            end_time="11:00",
        )
    )
    await db_session.flush()

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-07-06")
    statuses = {s.start_time: s.status for s in result.slots}

    # ScheduleException 의 partial 동작은 그대로
    assert statuses["09:00"] == "available"
    assert statuses["10:00"] == "unavailable"
    assert statuses["11:00"] == "available"
