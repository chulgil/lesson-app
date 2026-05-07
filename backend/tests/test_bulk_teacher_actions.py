"""Bulk teacher action API contract tests."""

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import ClassMembership, Lesson, LessonClass, LessonStatus
from app.models.notification import Notification
from app.models.request_event import RequestEvent
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
    lesson_date: date = date(2026, 5, 9),
    status: LessonStatus = LessonStatus.scheduled,
    teacher_id: str = TEACHER_PROFILE_ID,
) -> None:
    db_session.add(
        Lesson(
            id=lesson_id,
            teacher_id=teacher_id,
            student_id=student_id,
            student_name=f"Student {student_id}",
            instrument="piano",
            date=lesson_date,
            start_time="14:00",
            duration=60,
            status=status,
            subscription_id=subscription_id,
        )
    )
    await db_session.flush()


@pytest.mark.asyncio
async def test_bulk_cancel_rejects_empty_student_list(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    response = await client.post(
        "/api/v1/lessons/bulk-cancel",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": [],
            "target_date": "2026-05-09",
            "notification_title": "휴강 안내",
        },
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_bulk_cancel_preview_returns_events_without_mutation(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-active-user", role="student", email="active@test.com")
    await create_test_user(user_id="student-skipped-user", role="student", email="skipped@test.com")
    await _seed_student(db_session, student_id="student-active", user_id="student-active-user")
    await _seed_student(db_session, student_id="student-skipped", user_id="student-skipped-user")
    await _seed_active_subscription(db_session, student_id="student-active", subscription_id="sub-active")
    await _seed_lesson(
        db_session,
        lesson_id="lesson-active",
        student_id="student-active",
        subscription_id="sub-active",
        status=LessonStatus.reschedulePending,
    )
    await _seed_lesson(
        db_session,
        lesson_id="lesson-skipped",
        student_id="student-skipped",
        subscription_id=None,
    )

    response = await client.post(
        "/api/v1/lessons/bulk-cancel/preview",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": ["student-active", "student-skipped", "student-missing"],
            "target_date": "2026-05-09",
            "reason": "개인 사정으로 휴강합니다",
            "notification_title": "휴강 안내",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["cancelled_lesson_count"] == 1
    assert body["notified_student_count"] == 1
    assert set(body["skipped_student_ids"]) == {"student-skipped", "student-missing"}
    assert body["events_created"] == [
        {
            "student_id": "student-active",
            "lesson_id": "lesson-active",
            "session_number": 1,
            "subscription_id": "sub-active",
        }
    ]

    active_lesson = await db_session.get(Lesson, "lesson-active")
    skipped_lesson = await db_session.get(Lesson, "lesson-skipped")
    assert active_lesson is not None
    assert skipped_lesson is not None
    assert active_lesson.status == LessonStatus.reschedulePending
    assert skipped_lesson.status == LessonStatus.scheduled
    assert (await db_session.scalars(select(RequestEvent))).all() == []
    assert (await db_session.scalars(select(Notification))).all() == []


@pytest.mark.asyncio
async def test_bulk_cancel_creates_events_and_skips_students_without_active_subscription(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-active-user", role="student", email="active@test.com")
    await create_test_user(user_id="student-skipped-user", role="student", email="skipped@test.com")
    await _seed_student(db_session, student_id="student-active", user_id="student-active-user")
    await _seed_student(db_session, student_id="student-skipped", user_id="student-skipped-user")
    await _seed_active_subscription(db_session, student_id="student-active", subscription_id="sub-active")
    await _seed_lesson(
        db_session,
        lesson_id="lesson-active",
        student_id="student-active",
        subscription_id="sub-active",
        status=LessonStatus.reschedulePending,
    )
    await _seed_lesson(
        db_session,
        lesson_id="lesson-skipped",
        student_id="student-skipped",
        subscription_id=None,
    )

    response = await client.post(
        "/api/v1/lessons/bulk-cancel",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": ["student-active", "student-skipped", "student-missing"],
            "target_date": "2026-05-09",
            "reason": "개인 사정으로 휴강합니다",
            "notification_title": "휴강 안내",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["cancelled_lesson_count"] == 1
    assert body["notified_student_count"] == 1
    assert set(body["skipped_student_ids"]) == {"student-skipped", "student-missing"}
    assert body["events_created"] == [
        {
            "student_id": "student-active",
            "lesson_id": "lesson-active",
            "session_number": 1,
            "subscription_id": "sub-active",
        }
    ]

    active_lesson = await db_session.get(Lesson, "lesson-active")
    skipped_lesson = await db_session.get(Lesson, "lesson-skipped")
    assert active_lesson is not None
    assert skipped_lesson is not None
    assert active_lesson.status == LessonStatus.cancelledByTeacher
    assert skipped_lesson.status == LessonStatus.scheduled

    events = (await db_session.scalars(select(RequestEvent))).all()
    assert len(events) == 1
    assert events[0].event_type.value == "lessonCancelledByTeacher"
    assert events[0].subscription_id == "sub-active"
    assert events[0].session_number == 1
    assert events[0].message == "개인 사정으로 휴강합니다"
    assert events[0].change_credit_used == 0
    assert events[0].keeps_session_number is True

    notifications = (await db_session.scalars(select(Notification))).all()
    assert len(notifications) == 1
    assert notifications[0].user_id == "student-active-user"
    assert notifications[0].type == "lessonCancelled"
    assert notifications[0].priority.value == "high"


@pytest.mark.asyncio
async def test_broadcast_rejects_empty_student_list(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    response = await client.post(
        "/api/v1/notifications/broadcast",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": [],
            "target_filter": "active_subscription",
            "title": "발표회 참가 확인",
            "body": "참가 여부를 알려주세요.",
        },
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_broadcast_all_sends_notifications_but_events_only_for_active_subscriptions(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-active-user", role="student", email="active@test.com")
    await create_test_user(user_id="student-no-sub-user", role="student", email="nosub@test.com")
    await _seed_student(db_session, student_id="student-active", user_id="student-active-user")
    await _seed_student(db_session, student_id="student-no-sub", user_id="student-no-sub-user")
    await _seed_active_subscription(db_session, student_id="student-active", subscription_id="sub-active")

    response = await client.post(
        "/api/v1/notifications/broadcast",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": ["student-active", "student-no-sub"],
            "target_filter": "all",
            "title": "발표회 참가 확인",
            "body": "7월 12일 발표회 참가 여부를 알려주세요.",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "sent_count": 2,
        "event_created_count": 1,
        "filtered_out_count": 0,
    }

    events = (await db_session.scalars(select(RequestEvent))).all()
    assert len(events) == 1
    assert events[0].event_type.value == "teacherAnnouncement"
    assert events[0].subscription_id == "sub-active"
    assert events[0].message == "발표회 참가 확인\n7월 12일 발표회 참가 여부를 알려주세요."

    notifications = (await db_session.scalars(select(Notification).order_by(Notification.user_id))).all()
    assert [notification.user_id for notification in notifications] == [
        "student-active-user",
        "student-no-sub-user",
    ]
    assert {notification.type for notification in notifications} == {"generalAnnouncement"}


@pytest.mark.asyncio
async def test_broadcast_active_subscription_filters_out_students_without_subscription(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-active-user", role="student", email="active@test.com")
    await create_test_user(user_id="student-no-sub-user", role="student", email="nosub@test.com")
    await _seed_student(db_session, student_id="student-active", user_id="student-active-user")
    await _seed_student(db_session, student_id="student-no-sub", user_id="student-no-sub-user")
    await _seed_active_subscription(db_session, student_id="student-active", subscription_id="sub-active")

    response = await client.post(
        "/api/v1/notifications/broadcast",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": ["student-active", "student-no-sub"],
            "target_filter": "active_subscription",
            "title": "발표회 참가 확인",
            "body": "7월 12일 발표회 참가 여부를 알려주세요.",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "sent_count": 1,
        "event_created_count": 1,
        "filtered_out_count": 1,
    }

    events = (await db_session.scalars(select(RequestEvent))).all()
    notifications = (await db_session.scalars(select(Notification))).all()
    assert len(events) == 1
    assert len(notifications) == 1
    assert notifications[0].user_id == "student-active-user"


@pytest.mark.asyncio
async def test_broadcast_active_subscription_includes_trial_subscriptions_and_filters_non_active_trials(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Active/expiring/시험생 상태의 수강권만 활성 상태 타깃에 포함된다."""
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-trial-user", role="student", email="trial@test.com")
    await create_test_user(user_id="student-expired-user", role="student", email="expired@test.com")
    await create_test_user(user_id="student-nosub-user", role="student", email="nosub@test.com")

    await _seed_student(db_session, student_id="student-active-trial", user_id="student-trial-user")
    await _seed_student(db_session, student_id="student-expired-trial", user_id="student-expired-user")
    await _seed_student(db_session, student_id="student-no-sub", user_id="student-nosub-user")

    await _seed_active_subscription(
        db_session,
        student_id="student-active-trial",
        subscription_id="sub-trial-active",
        subscription_type=SubscriptionType.trial,
    )
    await _seed_active_subscription(
        db_session,
        student_id="student-expired-trial",
        subscription_id="sub-trial-expired",
        status=SubscriptionStatus.expired,
        subscription_type=SubscriptionType.trial,
    )

    response = await client.post(
        "/api/v1/notifications/broadcast",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": ["student-active-trial", "student-expired-trial", "student-no-sub"],
            "target_filter": "active_subscription",
            "title": "시험 연습 일정",
            "body": "이번 주 연습 변경 건 제안",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "sent_count": 1,
        "event_created_count": 1,
        "filtered_out_count": 2,
    }

    events = (await db_session.scalars(select(RequestEvent))).all()
    notifications = (await db_session.scalars(select(Notification))).all()
    assert len(events) == 1
    assert events[0].subscription_id == "sub-trial-active"
    assert events[0].event_type.value == "teacherAnnouncement"
    assert len(notifications) == 1
    assert notifications[0].user_id == "student-trial-user"


@pytest.mark.asyncio
async def test_bulk_cancel_includes_trial_subscription_and_skips_expired_trial(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """휴강 일괄취소는 활성 트라이얼 수강권만 처리하고 만료 트라이얼은 제외한다."""
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id="student-trial-user", role="student", email="trial@test.com")
    await create_test_user(user_id="student-expired-user", role="student", email="expired@test.com")

    await _seed_student(db_session, student_id="student-active-trial", user_id="student-trial-user")
    await _seed_student(db_session, student_id="student-expired-trial", user_id="student-expired-user")

    await _seed_active_subscription(
        db_session,
        student_id="student-active-trial",
        subscription_id="sub-trial-active",
        subscription_type=SubscriptionType.trial,
    )
    await _seed_active_subscription(
        db_session,
        student_id="student-expired-trial",
        subscription_id="sub-trial-expired",
        status=SubscriptionStatus.expired,
        subscription_type=SubscriptionType.trial,
    )

    await _seed_lesson(
        db_session,
        lesson_id="lesson-trial-active",
        student_id="student-active-trial",
        subscription_id="sub-trial-active",
        status=LessonStatus.scheduled,
    )
    await _seed_lesson(
        db_session,
        lesson_id="lesson-trial-expired",
        student_id="student-expired-trial",
        subscription_id="sub-trial-expired",
        status=LessonStatus.scheduled,
    )

    response = await client.post(
        "/api/v1/lessons/bulk-cancel",
        headers=auth_headers,
        json={
            "teacher_id": TEACHER_PROFILE_ID,
            "student_ids": ["student-active-trial", "student-expired-trial"],
            "target_date": "2026-05-09",
            "reason": "휴강 사유",
            "notification_title": "시험 연습 휴강",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["cancelled_lesson_count"] == 1
    assert body["notified_student_count"] == 1
    assert body["skipped_student_ids"] == ["student-expired-trial"]
    assert body["events_created"] == [
        {
            "student_id": "student-active-trial",
            "lesson_id": "lesson-trial-active",
            "session_number": 1,
            "subscription_id": "sub-trial-active",
        }
    ]

    events = (await db_session.scalars(select(RequestEvent))).all()
    assert len(events) == 1
    assert events[0].subscription_id == "sub-trial-active"
    assert events[0].event_type.value == "lessonCancelledByTeacher"

    active_lesson = await db_session.get(Lesson, "lesson-trial-active")
    expired_lesson = await db_session.get(Lesson, "lesson-trial-expired")
    assert active_lesson is not None
    assert expired_lesson is not None
    assert active_lesson.status == LessonStatus.cancelledByTeacher
    assert expired_lesson.status == LessonStatus.scheduled
