"""Issue #606 — dual-write onboarding endpoint + diff validator regression.

Acceptance Criteria:
- onboarding 호출 시 TeacherAvailability + TeacherSettings.available_slots 모두 기록
- 이미 settings 가 있으면 갱신
- diff validator: synced 시 diff_count=0, mismatched fixtures 시 목록 반환
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_onboarding_writes_to_both_stores(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """POST /teacher/availability/onboarding — 두 저장소 동시 기록."""
    from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
    from app.models.settings import TeacherSettings
    from app.services.teacher_id_resolver import resolve_teacher_id

    await create_test_user(user_id="test-user-id", role="teacher")
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/availability/onboarding",
        headers=auth_headers,
        json={
            "slots": [
                {"day_of_week": 0, "start_time": "09:00", "end_time": "12:00"},
                {"day_of_week": 0, "start_time": "13:00", "end_time": "18:00"},
                {"day_of_week": 2, "start_time": "10:00", "end_time": "20:00"},
            ]
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["schedule_slot_count"] == 3
    assert body["settings_slot_count"] == 3

    db_session.expire_all()
    # SSOT — TeacherAvailability + AvailabilityTimeSlot.
    avails = (
        await db_session.scalars(select(TeacherAvailability).where(TeacherAvailability.teacher_id == teacher_id))
    ).all()
    assert len(avails) == 2  # 요일 2개 (월, 수).
    total_time_slots = 0
    for avail in avails:
        slots = (
            await db_session.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
            )
        ).all()
        total_time_slots += len(slots)
    assert total_time_slots == 3

    # 역호환 — TeacherSettings.available_slots JSON.
    settings = await db_session.scalar(select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id))
    assert settings is not None
    assert len(settings.available_slots) == 3


@pytest.mark.asyncio
async def test_onboarding_replaces_existing(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """기존 availability 가 있어도 전체 교체 (SSOT 일관성)."""
    from app.models.schedule import TeacherAvailability
    from app.models.settings import TeacherSettings
    from app.services.teacher_id_resolver import resolve_teacher_id

    await create_test_user(user_id="test-user-id", role="teacher")
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    await db_session.commit()

    # 1차 — 슬롯 2개.
    await client.post(
        "/api/v1/teacher/availability/onboarding",
        headers=auth_headers,
        json={
            "slots": [
                {"day_of_week": 1, "start_time": "09:00", "end_time": "10:00"},
                {"day_of_week": 1, "start_time": "11:00", "end_time": "12:00"},
            ]
        },
    )

    # 2차 — 슬롯 1개 (덮어쓰기).
    response = await client.post(
        "/api/v1/teacher/availability/onboarding",
        headers=auth_headers,
        json={"slots": [{"day_of_week": 3, "start_time": "14:00", "end_time": "15:00"}]},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    avails = (
        await db_session.scalars(select(TeacherAvailability).where(TeacherAvailability.teacher_id == teacher_id))
    ).all()
    assert len(avails) == 1
    assert avails[0].day_of_week == 3
    settings = await db_session.scalar(select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id))
    assert len(settings.available_slots) == 1
    assert settings.available_slots[0]["day_of_week"] == 3


@pytest.mark.asyncio
async def test_diff_validator_returns_zero_when_synced(
    create_test_user,
    db_session: AsyncSession,
):
    """validator: 두 저장소가 동기된 상태에서 diff_count=0."""
    from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
    from app.models.settings import TeacherSettings
    from app.services.teacher_id_resolver import resolve_teacher_id
    from scripts.validators.teacher_availability_diff import _collect_settings, _collect_ssot

    await create_test_user(user_id="test-user-id", role="teacher")
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    # 양쪽 같은 슬롯.
    avail = TeacherAvailability(teacher_id=teacher_id, day_of_week=4)
    db_session.add(avail)
    await db_session.flush()
    db_session.add(AvailabilityTimeSlot(availability_id=avail.id, start_time="09:00", end_time="10:00"))
    db_session.add(
        TeacherSettings(
            teacher_id=teacher_id,
            available_slots=[{"day_of_week": 4, "start_time": "09:00", "end_time": "10:00"}],
        )
    )
    await db_session.flush()

    ssot = await _collect_ssot(db_session, teacher_id)
    settings = await _collect_settings(db_session, teacher_id)
    assert ssot == settings


@pytest.mark.asyncio
async def test_diff_validator_detects_mismatch(
    create_test_user,
    db_session: AsyncSession,
):
    """validator: ssot 와 settings 가 다르면 diff 검출."""
    from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
    from app.models.settings import TeacherSettings
    from app.services.teacher_id_resolver import resolve_teacher_id
    from scripts.validators.teacher_availability_diff import _collect_settings, _collect_ssot

    await create_test_user(user_id="test-user-id", role="teacher")
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    avail = TeacherAvailability(teacher_id=teacher_id, day_of_week=5)
    db_session.add(avail)
    await db_session.flush()
    db_session.add(AvailabilityTimeSlot(availability_id=avail.id, start_time="13:00", end_time="14:00"))
    # settings 는 다른 시간.
    db_session.add(
        TeacherSettings(
            teacher_id=teacher_id,
            available_slots=[{"day_of_week": 5, "start_time": "15:00", "end_time": "16:00"}],
        )
    )
    await db_session.flush()

    ssot = await _collect_ssot(db_session, teacher_id)
    settings = await _collect_settings(db_session, teacher_id)
    assert ssot != settings
    assert ssot == {(5, "13:00", "14:00")}
    assert settings == {(5, "15:00", "16:00")}
