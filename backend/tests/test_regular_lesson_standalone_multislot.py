"""#301: standalone 주N회 등록 — POST /bookings with fixed_time_slots.

register_regular_lesson_screen 이 N개 동시 주간 슬롯을 보내면, BE 가 recurring
레슨을 그 N슬롯에 주차별로 분배 생성해야 한다 (이전: 단일 pending booking 1건).
"""

import pytest
from httpx import AsyncClient
from sqlalchemy import select


@pytest.mark.asyncio
async def test_standalone_two_slots_distributes_lessons_across_weekdays(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """주2회·두 요일(월/수) → 8개 레슨(2슬롯×4주)이 월 4 / 수 4 로 분배 생성."""
    from app.models.lesson import Lesson, LessonSource

    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": "student-301",
            "student_name": "주2회 학생",
            "lesson_type": "regular",
            "start_date": "2026-07-01",
            "duration": 60,
            "instrument": "violin",
            "lessons_per_week": 2,
            "fixedTimeSlots": [
                {"day_of_week": 0, "start_time": "10:00", "duration_minutes": 60},
                {"day_of_week": 2, "start_time": "14:00", "duration_minutes": 60},
            ],
        },
    )

    assert response.status_code == 201, response.text

    lessons = (
        await db_session.scalars(select(Lesson).where(Lesson.student_id == "student-301").order_by(Lesson.date))
    ).all()

    # 2 slots × 4 weeks = 8 recurring lessons (no subscription → 1-month horizon).
    assert len(lessons) == 8
    mondays = [le for le in lessons if le.date.weekday() == 0]
    wednesdays = [le for le in lessons if le.date.weekday() == 2]
    assert len(mondays) == 4
    assert len(wednesdays) == 4
    # standalone (no subscription) lessons are manual-sourced, not subscription-generated.
    assert all(le.lesson_source == LessonSource.manual for le in lessons)
    assert {le.start_time for le in mondays} == {"10:00"}
    assert {le.start_time for le in wednesdays} == {"14:00"}


@pytest.mark.asyncio
async def test_standalone_single_slot_still_works(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """주1회·단일 슬롯 → 4개 레슨(1슬롯×4주), 백워드 호환."""
    from app.models.lesson import Lesson

    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": "student-302",
            "lesson_type": "regular",
            "start_date": "2026-07-01",
            "duration": 45,
            "lessons_per_week": 1,
            "fixedTimeSlots": [
                {"day_of_week": 4, "start_time": "16:00", "duration_minutes": 45},
            ],
        },
    )

    assert response.status_code == 201, response.text
    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == "student-302"))).all()
    assert len(lessons) == 4
    assert all(le.date.weekday() == 4 for le in lessons)
    assert all(le.duration == 45 for le in lessons)


@pytest.mark.asyncio
async def test_standalone_conflicting_occurrence_is_skipped_and_warned(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
    caplog,
):
    """#301: 일부 슬롯이 기존 일정과 충돌하면 그 회차만 제외되고(부분 손실),
    조용히 사라지지 않도록 경고 로그로 surface 된다."""
    import datetime as dt
    import logging

    from app.models.lesson import Lesson
    from app.models.schedule import LessonBooking

    await create_test_user(user_id="test-user-id", role="teacher")

    # 교사의 기존 예약이 월요일 첫 회차(2026-07-06 10:00)와 충돌하도록 미리 생성.
    db_session.add(
        LessonBooking(
            teacher_id="test-user-id-prof",
            student_id="existing-student",
            lesson_type="regular",
            scheduled_date=dt.date(2026, 7, 6),
            scheduled_time="10:00",
            duration=60,
            status="confirmed",
        )
    )
    await db_session.flush()

    with caplog.at_level(logging.WARNING):
        response = await client.post(
            "/api/v1/bookings",
            headers=auth_headers,
            json={
                "teacher_id": "test-user-id",
                "student_id": "student-303",
                "lesson_type": "regular",
                "start_date": "2026-07-01",  # Wednesday
                "duration": 60,
                "lessons_per_week": 2,
                "fixedTimeSlots": [
                    {"day_of_week": 0, "start_time": "10:00", "duration_minutes": 60},
                    {"day_of_week": 2, "start_time": "14:00", "duration_minutes": 60},
                ],
            },
        )

    assert response.status_code == 201, response.text
    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == "student-303"))).all()
    # 8회 요청 중 충돌 1회(월 07-06) 제외 → 7회 생성 (월 3 / 수 4).
    assert len(lessons) == 7
    assert sum(1 for le in lessons if le.date.weekday() == 0) == 3
    assert sum(1 for le in lessons if le.date.weekday() == 2) == 4
    # 부분 손실이 로그로 surface 됨.
    assert any("skipped" in r.message and "#301" in r.message for r in caplog.records)
