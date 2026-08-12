"""#301: standalone 주N회 등록 — POST /bookings with fixed_time_slots.

register_regular_lesson_screen 이 N개 동시 주간 슬롯을 보내면, BE 가 recurring
레슨을 그 N슬롯에 주차별로 분배 생성해야 한다 (이전: 단일 pending booking 1건).

subscription_required_spec §1 — "lesson.subscriptionId != null, 예외 없음". 이
파일의 테스트는 실재하는 ``Student`` row 를 만들어 쓴다 — 수강권 자동귀속/생성이
``Subscription.student_id`` FK 를 거치므로, 가짜 student_id 문자열로는 더 이상
통과하지 않는다 (수강권 없이 만들어지던 이전 버그의 증상이 바로 이 gap 이었다).
"""

import pytest
from httpx import AsyncClient
from sqlalchemy import select


@pytest.mark.asyncio
async def test_standalone_two_slots_distributes_lessons_across_weekdays(
    teacher,
    client: AsyncClient,
    auth_headers,
    db_session,
):
    """주2회·두 요일(월/수) → 8개 레슨(2슬롯×4주)이 월 4 / 수 4 로 분배 생성.

    학생에게 활성 수강권이 없으므로, 배치 전체(8회)를 커버하는 체험 수강권 1개가
    자동 생성되고 모든 레슨이 그 수강권 하나에 귀속된다 (§2.4 + 배치 확장).
    """
    from app.models.lesson import Lesson, LessonSource
    from app.models.subscription import Subscription

    sid = await teacher.create_student("주2회 학생")

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": sid,
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

    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == sid).order_by(Lesson.date))).all()

    # 2 slots × 4 weeks = 8 recurring lessons (no subscription → 1-month horizon).
    assert len(lessons) == 8
    mondays = [le for le in lessons if le.date.weekday() == 0]
    wednesdays = [le for le in lessons if le.date.weekday() == 2]
    assert len(mondays) == 4
    assert len(wednesdays) == 4
    assert {le.start_time for le in mondays} == {"10:00"}
    assert {le.start_time for le in wednesdays} == {"14:00"}

    # Every lesson carries a non-null subscription_id, and it's the SAME
    # subscription for the whole batch — not one shadow lesson per slot.
    subscription_ids = {le.subscription_id for le in lessons}
    assert None not in subscription_ids
    assert len(subscription_ids) == 1
    # A subscription now backs the batch, so the #426 cascade-cancel path applies.
    assert all(le.lesson_source == LessonSource.subscription_generated for le in lessons)

    (sub_id,) = subscription_ids
    subs = (await db_session.scalars(select(Subscription).where(Subscription.student_id == sid))).all()
    assert len(subs) == 1, "exactly one subscription must be auto-created for the whole batch"
    sub = subs[0]
    assert sub.id == sub_id
    assert sub.type.value == "trial"
    assert sub.total_lessons == 1
    # Trial's remaining_lessons() hardcodes base=1 regardless of total_lessons, so
    # covering the 8-lesson batch goes through bonus_count (§2.3's bonus lever).
    assert sub.bonus_count == 7


@pytest.mark.asyncio
async def test_standalone_single_slot_still_works(
    teacher,
    client: AsyncClient,
    auth_headers,
    db_session,
):
    """주1회·단일 슬롯 → 4개 레슨(1슬롯×4주), 백워드 호환."""
    from app.models.lesson import Lesson

    sid = await teacher.create_student("주1회 학생")

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": sid,
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
    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == sid))).all()
    assert len(lessons) == 4
    assert all(le.date.weekday() == 4 for le in lessons)
    assert all(le.duration == 45 for le in lessons)
    assert all(le.subscription_id is not None for le in lessons)


@pytest.mark.asyncio
async def test_standalone_conflicting_occurrence_pushed_forward_keeps_count(
    teacher,
    client: AsyncClient,
    auth_headers,
    db_session,
    caplog,
):
    """#897: 충돌 회차는 드롭하지 않고 다음 주로 밀어 count(8)를 보장한다.

    교사의 기존 예약이 첫 월요일과 겹쳐도, 그 회차는 이후 월요일로 밀려
    8회 전부 생성되고(부분 손실 0) 충돌일에는 레슨이 없다. count 가 충족되므로
    부분손실 경고도 발생하지 않는다.
    """
    import datetime as dt
    import logging

    from app.models.lesson import Lesson
    from app.models.schedule import LessonBooking

    sid = await teacher.create_student("충돌회피 학생")

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
                "student_id": sid,
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
    # push-forward 로 전부 배치되므로 응답의 skipped 는 0 (FE 안내 스낵바 미발동).
    assert response.json()["recurring_skipped_count"] == 0
    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == sid))).all()
    # 충돌 회차는 밀려서 8회 전부 생성 (월 4 / 수 4), 부분 손실 없음.
    assert len(lessons) == 8
    assert sum(1 for le in lessons if le.date.weekday() == 0) == 4
    assert sum(1 for le in lessons if le.date.weekday() == 2) == 4
    # 충돌일(07-06)에는 레슨이 없고, 충돌은 다음 월요일로 밀렸다.
    assert all(le.date != dt.date(2026, 7, 6) for le in lessons)
    # count 가 충족되므로 부분손실 경고는 없다.
    assert not any("#301" in r.message for r in caplog.records)


@pytest.mark.asyncio
async def test_standalone_batch_reuses_existing_active_subscription(
    teacher,
    client: AsyncClient,
    auth_headers,
    db_session,
):
    """학생에게 활성 수강권이 이미 있으면, 배치 전체가 그 수강권 하나에 귀속된다.

    subscription_id 를 신규 생성하지 않는다 — 트라이얼도 만들지 않는다.
    """
    from app.models.lesson import Lesson
    from app.models.subscription import Subscription

    sid = await teacher.create_student("기존수강권 학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=300000)

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": sid,
            "lesson_type": "regular",
            "start_date": "2026-07-01",
            "duration": 60,
            "lessons_per_week": 1,
            "fixedTimeSlots": [
                {"day_of_week": 4, "start_time": "16:00", "duration_minutes": 60},
            ],
        },
    )

    assert response.status_code == 201, response.text
    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == sid))).all()
    assert len(lessons) == 4
    assert all(le.subscription_id == sub_id for le in lessons)

    subs = (await db_session.scalars(select(Subscription).where(Subscription.student_id == sid))).all()
    assert len(subs) == 1, "no extra (trial) subscription should be created when an active one exists"


@pytest.mark.asyncio
async def test_standalone_explicit_subscription_id_unchanged(
    teacher,
    client: AsyncClient,
    auth_headers,
    db_session,
):
    """회귀: FE 가 subscription_id 를 명시하면 기존 동작(그 수강권 그대로 사용) 불변.

    total_lessons(=6)이 count 를 덮어써 6개 레슨만 생성되던 기존 로직도 그대로다.
    """
    from app.models.lesson import Lesson

    sid = await teacher.create_student("명시수강권 학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=6, amount=200000)

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": sid,
            "lesson_type": "regular",
            "start_date": "2026-07-01",
            "duration": 60,
            "lessons_per_week": 1,
            "subscription_id": sub_id,
            "fixedTimeSlots": [
                {"day_of_week": 4, "start_time": "16:00", "duration_minutes": 60},
            ],
        },
    )

    assert response.status_code == 201, response.text
    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == sid))).all()
    # sub.total_lessons(=6) overrides the default lessons_per_week×4 horizon.
    assert len(lessons) == 6
    assert all(le.subscription_id == sub_id for le in lessons)
