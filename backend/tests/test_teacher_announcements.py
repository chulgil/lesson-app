"""Teacher announcement API contract tests."""

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import ClassMembership, Lesson, LessonClass, LessonStatus
from app.models.notification import Notification
from app.models.student import Student
from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

TEACHER_USER_ID = "test-user-id"
TEACHER_PROFILE_ID = "test-user-id-prof"


async def _seed_student(
    db_session: AsyncSession,
    *,
    student_id: str,
    user_id: str,
    teacher_id: str = TEACHER_PROFILE_ID,
) -> None:
    db_session.add(
        Student(
            id=student_id,
            user_id=user_id,
            teacher_id=teacher_id,
            name=f"Student {student_id}",
            instrument="piano",
        )
    )
    await db_session.flush()


async def _seed_active_subscription(
    db_session: AsyncSession,
    *,
    student_id: str,
    subscription_id: str,
    status: SubscriptionStatus = SubscriptionStatus.active,
    subscription_type: SubscriptionType = SubscriptionType.monthly,
    teacher_id: str = TEACHER_PROFILE_ID,
) -> None:
    lesson_class = LessonClass(teacher_id=teacher_id, name=f"Class {student_id}", type="private")
    db_session.add(lesson_class)
    await db_session.flush()

    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id=student_id,
        instrument="piano",
        status="active",
    )
    db_session.add(membership)
    await db_session.flush()

    db_session.add(
        Subscription(
            id=subscription_id,
            student_id=student_id,
            membership_id=membership.id,
            type=subscription_type,
            total_lessons=8,
            amount=200000,
            status=status,
        )
    )
    await db_session.flush()


async def _seed_lesson(
    db_session: AsyncSession,
    *,
    lesson_id: str,
    student_id: str,
    subscription_id: str | None,
    lesson_date: date,
    status: LessonStatus = LessonStatus.scheduled,
    teacher_id: str = TEACHER_PROFILE_ID,
    start_time: str = "14:00",
) -> None:
    db_session.add(
        Lesson(
            id=lesson_id,
            teacher_id=teacher_id,
            student_id=student_id,
            student_name=f"Student {student_id}",
            instrument="piano",
            date=lesson_date,
            start_time=start_time,
            duration=60,
            status=status,
            subscription_id=subscription_id,
        )
    )
    await db_session.flush()


@pytest.mark.asyncio
async def test_create_day_off_announcement_notifies_active_students_and_returns_affected_lessons(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-one", role="student", email="one@test.com")
    await create_test_user(user_id="student-two", role="student", email="two@test.com")
    await create_test_user(user_id="student-skip", role="student", email="skip@test.com")

    await _seed_student(db_session, student_id="student-1", user_id="student-one")
    await _seed_student(db_session, student_id="student-2", user_id="student-two")
    await _seed_student(db_session, student_id="student-3", user_id="student-skip")

    await _seed_active_subscription(db_session, student_id="student-1", subscription_id="sub-1")
    await _seed_active_subscription(db_session, student_id="student-2", subscription_id="sub-2")
    await _seed_active_subscription(
        db_session,
        student_id="student-3",
        subscription_id="sub-3",
        status=SubscriptionStatus.expired,
    )

    await _seed_lesson(
        db_session,
        lesson_id="lesson-1",
        student_id="student-1",
        subscription_id="sub-1",
        lesson_date=date(2026, 5, 9),
        start_time="10:00",
    )
    await _seed_lesson(
        db_session,
        lesson_id="lesson-2",
        student_id="student-1",
        subscription_id="sub-1",
        lesson_date=date(2026, 5, 9),
        start_time="14:00",
    )
    await _seed_lesson(
        db_session,
        lesson_id="lesson-3",
        student_id="student-2",
        subscription_id="sub-2",
        lesson_date=date(2026, 5, 9),
        start_time="16:00",
    )
    await _seed_lesson(
        db_session,
        lesson_id="lesson-4",
        student_id="student-3",
        subscription_id="sub-3",
        lesson_date=date(2026, 5, 9),
        start_time="17:00",
        status=LessonStatus.cancelled,
    )

    response = await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "dayOff",
            "dates": ["2026-05-09", "2026-05-09"],
            "message": "개인 사정으로 휴강합니다",
        },
    )
    assert response.status_code == 201

    body = response.json()
    assert body["type"] == "dayOff"
    assert body["dates"] == ["2026-05-09"]
    assert body["notified_count"] == 2
    assert len(body["affected_lessons"]) == 3
    assert [lesson["session_number"] for lesson in body["affected_lessons"]] == [1, 2, 1]

    notifications = (await db_session.scalars(select(Notification))).all()
    assert len(notifications) == 2
    assert {n.type for n in notifications} == {"generalAnnouncement"}
    assert {n.priority.value for n in notifications} == {"high"}


@pytest.mark.asyncio
async def test_create_general_announcement_notifies_active_students_without_day_off_dates(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-one", role="student", email="one@test.com")

    await _seed_student(db_session, student_id="student-1", user_id="student-one")
    await _seed_active_subscription(db_session, student_id="student-1", subscription_id="sub-1")

    response = await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "general",
            "message": "새 공지입니다",
            "dates": [],
        },
    )
    assert response.status_code == 201

    body = response.json()
    assert body["type"] == "general"
    assert body["dates"] == []
    assert body["affected_lessons"] == []
    assert body["notified_count"] == 1

    notifications = (await db_session.scalars(select(Notification))).all()
    assert len(notifications) == 1
    assert notifications[0].priority.value == "normal"


@pytest.mark.asyncio
async def test_teacher_announcements_rejects_invalid_type_payload(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    response = await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "general",
            "dates": ["2026-05-09"],
            "message": "잘못된 요청",
        },
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_list_announcements_returns_sorted_day_off_lessons(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "general",
            "message": "일반 공지",
            "dates": [],
        },
    )
    await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "dayOff",
            "dates": ["2026-05-10", "2026-05-09"],
            "message": "휴강 공지",
        },
    )

    response = await client.get(
        f"/api/v1/announcements?teacher_id={TEACHER_PROFILE_ID}",
        headers=auth_headers,
    )
    assert response.status_code == 200

    body = response.json()
    assert body[0]["type"] == "dayOff"
    assert body[0]["dates"] == ["2026-05-09", "2026-05-10"]
    assert body[1]["type"] == "general"


@pytest.mark.asyncio
async def test_list_announcements_defaults_to_authenticated_teacher(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "general",
            "message": "일반 공지",
            "dates": [],
        },
    )

    response = await client.get("/api/v1/announcements", headers=auth_headers)

    assert response.status_code == 200
    assert response.json()[0]["type"] == "general"


@pytest.mark.asyncio
async def test_list_day_offs_filters_and_deduplicates(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "dayOff",
            "dates": ["2026-05-09", "2026-05-10", "2026-05-10"],
            "message": "휴강 공지 1",
        },
    )
    await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "dayOff",
            "dates": ["2026-05-10", "2026-05-11"],
            "message": "휴강 공지 2",
        },
    )

    response = await client.get(
        f"/api/v1/announcements/day-offs?teacher_id={TEACHER_PROFILE_ID}&from_date=2026-05-09&to_date=2026-05-10",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json() == {"dates": ["2026-05-09", "2026-05-10"]}

    bad_response = await client.get(
        f"/api/v1/announcements/day-offs?teacher_id={TEACHER_PROFILE_ID}&from_date=2026-05-11&to_date=2026-05-10",
        headers=auth_headers,
    )
    assert bad_response.status_code == 400


@pytest.mark.asyncio
async def test_list_day_offs_defaults_to_authenticated_teacher(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    await client.post(
        "/api/v1/announcements",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "type": "dayOff",
            "dates": ["2026-05-09"],
            "message": "휴강 공지",
        },
    )

    response = await client.get(
        "/api/v1/announcements/day-offs?from_date=2026-05-08&to_date=2026-05-10",
        headers=auth_headers,
    )

    assert response.status_code == 200
    assert response.json() == {"dates": ["2026-05-09"]}
