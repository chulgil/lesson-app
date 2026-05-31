"""Tests for push notifications on subscription issuance and schedule confirmation card creation."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.notification import Notification


def _student_headers(user_id: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "student"})
    return {"Authorization": f"Bearer {token}"}


async def _create_student_user(db_session: AsyncSession, *, user_id: str, name: str) -> None:
    """Insert a User + Student profile linked to the same user_id."""
    from app.models.student import Student
    from app.models.user import User, UserRole

    user = User(
        id=user_id,
        email=f"{user_id}@test.com",
        name=name,
        role=UserRole.student,
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
        currency="KRW",
    )
    db_session.add(user)
    await db_session.flush()

    student = Student(id=f"{user_id}-profile", user_id=user_id, name=name, teacher_id="test-user-id-prof")
    db_session.add(student)
    await db_session.flush()


@pytest.mark.asyncio
async def test_create_subscription_notifies_student(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """Issuing a subscription via POST /api/v1/subscriptions creates a notification for the student."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _create_student_user(db_session, user_id="notify-student-1", name="김알림")

    response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "notify-student-1-profile",
            "type": "package",
            "total_lessons": 10,
            "amount": 300000,
            "start_date": "2026-06-01",
        },
    )
    assert response.status_code == 201, response.text

    notifications = (
        await db_session.scalars(
            select(Notification).where(Notification.user_id == "notify-student-1")
        )
    ).all()

    assert len(notifications) == 1
    notif = notifications[0]
    assert notif.type == "subscriptionIssued"
    assert "10회" in notif.body
    assert notif.priority.value == "high"
    assert notif.action_url is not None
    assert "subscriptions" in notif.action_url


@pytest.mark.asyncio
async def test_create_schedule_card_notifies_student(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """Creating a schedule confirmation card via POST notifies the linked student."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _create_student_user(db_session, user_id="notify-student-2", name="이알림")

    response = await client.post(
        "/api/v1/schedule/confirmation-cards",
        headers=auth_headers,
        json={
            "student_id": "notify-student-2-profile",
            "card_type": "afterTrial",
            "title": "레슨 일정 확인",
            "message": "레슨 일정을 확인해주세요",
            "proposed_day": "1",
            "proposed_time": "15:00",
            "proposed_duration": 60,
        },
    )
    assert response.status_code == 201, response.text

    notifications = (
        await db_session.scalars(
            select(Notification).where(Notification.user_id == "notify-student-2")
        )
    ).all()

    assert len(notifications) == 1
    notif = notifications[0]
    assert notif.type == "scheduleConfirmationRequired"
    assert notif.priority.value == "high"
    assert notif.action_url is not None
    assert "confirmation-cards" in notif.action_url


@pytest.mark.asyncio
async def test_create_subscription_no_notification_when_student_has_no_user(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """Offline student profile (no user_id) does not trigger a notification."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")

    # Offline student — no user_id
    offline_student = Student(
        id="offline-student-001",
        user_id=None,
        name="오프라인학생",
        teacher_id="test-user-id-prof",
    )
    db_session.add(offline_student)
    await db_session.flush()

    response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "offline-student-001",
            "type": "package",
            "total_lessons": 5,
            "amount": 150000,
        },
    )
    assert response.status_code == 201, response.text

    notifications = (
        await db_session.scalars(select(Notification))
    ).all()

    assert len(notifications) == 0
