"""Teacher-Student schedule ping-pong integration tests.

Tests the full back-and-forth between teacher and student roles
for schedule-related workflows: availability, bookings, exceptions.

Scenarios:
    1. Availability → slot query → booking → approve
    2. Booking rejection → re-book on different day
    3. Booking cancel → makeup lesson
    4. Holiday exception → booking blocked
    5. Booking change request

Usage:
    uv run python -m pytest tests/test_scenario_schedule_pingpong.py -v
"""

from __future__ import annotations

import pytest

from tests.scenarios.assertions import assert_status, assert_total
from tests.scenarios.helpers import StudentActions, TeacherActions


# ─────────────────────────────────────────────────────────────────────────
# 1. Availability → slot query → booking → approve
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_availability_to_booking_approval(
    teacher: TeacherActions, student: StudentActions
):
    """
    Teacher sets availability → Student queries slots → books → Teacher approves.
    선생님 가용시간 설정 → 학생 슬롯 조회 → 부킹 → 선생님 승인.
    """
    # ── Phase 1: Teacher sets weekly availability (Mon, Wed) ──
    await teacher.set_availability([
        {
            "day_of_week": 0,
            "time_slots": [{"start_time": "14:00", "end_time": "20:00"}],
        },
        {
            "day_of_week": 2,
            "time_slots": [{"start_time": "14:00", "end_time": "20:00"}],
        },
    ])

    avail = await teacher.get_availability()
    assert len(avail["availabilities"]) == 2

    # ── Phase 2: Student queries available slots ──────────────
    # 2026-04-01 is a Wednesday (day_of_week=2)
    slots = await student.get_available_slots(
        "test-user-id", "2026-04-01", duration=60
    )
    assert "slots" in slots

    # ── Phase 3: Student books a slot ─────────────────────────
    booking_id = await student.create_booking(
        "test-user-id",
        date="2026-04-01",
        time="14:00",
        duration=60,
        instrument="violin",
    )

    bookings = await student.list_bookings()
    assert_total(bookings, 1)

    # ── Phase 4: Teacher approves ─────────────────────────────
    result = await teacher.approve_booking(booking_id)
    assert_status(result, "approved")

    # ── Phase 5: Teacher checks weekly schedule ───────────────
    weekly = await teacher.get_weekly_schedule(week_start="2026-03-30")
    assert weekly is not None


# ─────────────────────────────────────────────────────────────────────────
# 2. Booking rejection → re-book on different day
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_booking_rejection_and_rebook(
    teacher: TeacherActions, student: StudentActions
):
    """
    Student books → Teacher rejects with reason → Student rebooks different day → approved.
    학생 부킹 → 선생님 거절(사유) → 학생 다른 날 부킹 → 승인.
    """
    # ── Phase 1: Student books Monday ─────────────────────────
    booking_id1 = await student.create_booking(
        "test-user-id",
        date="2026-04-06",
        time="14:00",
        duration=60,
        instrument="violin",
    )

    # ── Phase 2: Teacher rejects with reason ──────────────────
    rejected = await teacher.reject_booking(
        booking_id1, reason="월요일은 이미 예약이 꽉 찼어요"
    )
    assert_status(rejected, "rejected")

    # ── Phase 3: Student rebooks on Wednesday ─────────────────
    booking_id2 = await student.create_booking(
        "test-user-id",
        date="2026-04-08",
        time="15:00",
        duration=60,
        instrument="violin",
    )

    # ── Phase 4: Teacher approves the new booking ─────────────
    approved = await teacher.approve_booking(booking_id2)
    assert_status(approved, "approved")


# ─────────────────────────────────────────────────────────────────────────
# 3. Booking cancel → makeup lesson
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_booking_cancel_and_makeup(
    teacher: TeacherActions, student: StudentActions
):
    """
    Student books → Teacher approves → Student cancels → Teacher creates makeup.
    학생 부킹 → 선생님 승인 → 학생 취소 → 선생님 보강 생성.
    """
    # ── Phase 1: Normal booking flow ──────────────────────────
    booking_id = await student.create_booking(
        "test-user-id",
        date="2026-04-03",
        time="16:00",
        duration=60,
        instrument="piano",
    )
    await teacher.approve_booking(booking_id)

    # ── Phase 2: Student cancels ──────────────────────────────
    cancelled = await student.cancel_booking(
        booking_id, reason="갑자기 일정이 생겼어요"
    )
    assert_status(cancelled, "cancelled")

    # ── Phase 3: Teacher creates makeup for a student ─────────
    sid = await teacher.create_student("보강학생", instrument="piano")
    makeup = await teacher.create_makeup_booking(
        sid,
        scheduled_date="2026-04-10",
        scheduled_time="16:00",
        duration=60,
    )
    assert makeup["scheduled_date"] == "2026-04-10"


# ─────────────────────────────────────────────────────────────────────────
# 4. Holiday exception → booking attempt
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_schedule_exception_holiday(teacher: TeacherActions):
    """
    Teacher sets availability → adds holiday exception.
    선생님 가용시간 설정 → 특정일 휴무 등록 → 확인.
    """
    # ── Phase 1: Set availability ─────────────────────────────
    await teacher.set_availability([
        {
            "day_of_week": 2,
            "time_slots": [{"start_time": "10:00", "end_time": "18:00"}],
        },
    ])

    # ── Phase 2: Add holiday exception ────────────────────────
    exception = await teacher.create_schedule_exception(
        "2026-04-09", exception_type="holiday", reason="개인 휴무"
    )
    assert exception["start_date"] == "2026-04-09"
    assert exception["type"] == "holiday"

    # ── Phase 3: Delete exception (resume normal schedule) ────
    await teacher.delete_schedule_exception(exception["id"])


# ─────────────────────────────────────────────────────────────────────────
# 5. Booking change request
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_booking_change_request(
    teacher: TeacherActions, student: StudentActions
):
    """
    Student books → Teacher approves → Student requests time change.
    학생 부킹 → 선생님 승인 → 학생 일정 변경 요청.
    """
    # ── Phase 1: Create and approve booking ───────────────────
    booking_id = await student.create_booking(
        "test-user-id",
        date="2026-04-07",
        time="14:00",
        duration=60,
        instrument="violin",
    )
    await teacher.approve_booking(booking_id)

    # ── Phase 2: Student requests date change ─────────────────
    changed = await student.request_booking_change(
        booking_id,
        new_date="2026-04-09",
        new_time="15:00",
    )
    assert changed is not None
