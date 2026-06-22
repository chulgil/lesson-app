"""#202: 학생 예약 슬롯의 길이가 교사의 레슨 1회 시간(default_lesson_duration)을 따른다.

이전에는 BE 가 60분(엔드포인트 기본값)을 무조건 슬롯 길이로 써서 교사 설정을 무시했다.
"""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
from app.models.settings import TeacherSettings
from app.services.schedule_service import ScheduleService


async def _seed_availability(db: AsyncSession, teacher_id: str = "test-user-id") -> None:
    """Monday 09:00-12:00 availability window."""
    avail = TeacherAvailability(id="avail-1", teacher_id=teacher_id, day_of_week=0)
    db.add(avail)
    db.add(AvailabilityTimeSlot(id="ts-1", availability_id=avail.id, start_time="09:00", end_time="12:00"))
    await db.flush()


@pytest.mark.asyncio
async def test_slot_duration_follows_teacher_setting(db_session: AsyncSession):
    """교사가 50분으로 설정하면 학생 슬롯도 50분 (60분 하드코딩 아님)."""
    await _seed_availability(db_session)
    db_session.add(TeacherSettings(teacher_id="test-user-id", default_lesson_duration=50))
    await db_session.flush()

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-05-04")

    assert len(result.slots) > 0
    assert {s.duration_minutes for s in result.slots} == {50}
    # 09:00 슬롯은 09:00-09:50.
    by_start = {s.start_time: s for s in result.slots}
    assert by_start["09:00"].end_time == "09:50"


@pytest.mark.asyncio
async def test_slot_duration_falls_back_to_60_without_settings(db_session: AsyncSession):
    """TeacherSettings 행이 없으면 60분 폴백 (기존 동작 보존)."""
    await _seed_availability(db_session)

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-05-04")

    assert len(result.slots) > 0
    assert {s.duration_minutes for s in result.slots} == {60}


@pytest.mark.asyncio
async def test_explicit_duration_overrides_setting(db_session: AsyncSession):
    """명시적 duration 전달(보강예약 등 BC)은 교사 설정보다 우선."""
    await _seed_availability(db_session)
    db_session.add(TeacherSettings(teacher_id="test-user-id", default_lesson_duration=50))
    await db_session.flush()

    svc = ScheduleService(db_session)
    result = await svc.get_available_slots(teacher_id="test-user-id", date="2026-05-04", duration=30)

    assert {s.duration_minutes for s in result.slots} == {30}
