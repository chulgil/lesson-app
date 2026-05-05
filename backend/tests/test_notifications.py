"""Notification endpoint tests."""

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification, NotificationPriority


@pytest.mark.asyncio
async def test_list_notifications(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/notifications returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/notifications", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_get_unread_count(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/notifications/unread-count returns count."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["count"] == 0


@pytest.mark.asyncio
async def test_mark_all_read(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /api/v1/notifications/read-all marks all as read."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.patch("/api/v1/notifications/read-all", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


@pytest.mark.asyncio
async def test_notification_response_matches_frontend_read_state_contract(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """GET /notifications exposes the fields needed by the remote Flutter repository."""
    await create_test_user(user_id="test-user-id", role="teacher")
    scheduled_at = datetime.now(UTC) + timedelta(hours=1)
    sent_at = datetime.now(UTC)
    notification = Notification(
        user_id="test-user-id",
        type="lessonReminder",
        priority=NotificationPriority.high,
        title="레슨 알림",
        body="30분 후 레슨이 있습니다",
        data={"lessonId": "lesson-1"},
        scheduled_at=scheduled_at,
        sent_at=sent_at,
        is_push=False,
        is_in_app=True,
        action_url="/lessons/lesson-1",
        action_label="일정 보기",
    )
    db_session.add(notification)
    await db_session.flush()

    response = await client.get("/api/v1/notifications", headers=auth_headers)

    assert response.status_code == 200
    item = response.json()["items"][0]
    assert item["id"] == notification.id
    assert item["user_id"] == "test-user-id"
    assert item["type"] == "lessonReminder"
    assert item["priority"] == "high"
    assert item["title"] == "레슨 알림"
    assert item["body"] == "30분 후 레슨이 있습니다"
    assert item["data"] == {"lessonId": "lesson-1"}
    assert item["scheduled_at"] is not None
    assert item["sent_at"] is not None
    assert item["read_at"] is None
    assert item["is_read"] is False
    assert item["is_push"] is False
    assert item["is_in_app"] is True
    assert item["action_url"] == "/lessons/lesson-1"
    assert item["action_label"] == "일정 보기"
    assert item["created_at"] is not None


@pytest.mark.asyncio
async def test_unread_badge_count_tracks_current_user_read_at_only(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Unread badge count is scoped to the current user and read_at nullness."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-user-id",
        role="student",
        name="Other Student",
        email="other@test.com",
    )
    read_at = datetime.now(UTC) - timedelta(minutes=10)
    db_session.add_all(
        [
            Notification(
                user_id="test-user-id",
                type="lessonReminder",
                priority=NotificationPriority.normal,
                title="읽지 않은 알림",
                body="현재 사용자 미읽음",
            ),
            Notification(
                user_id="test-user-id",
                type="lessonCompleted",
                priority=NotificationPriority.low,
                title="읽은 알림",
                body="현재 사용자 읽음",
                read_at=read_at,
            ),
            Notification(
                user_id="other-user-id",
                type="lessonReminder",
                priority=NotificationPriority.normal,
                title="다른 사용자 알림",
                body="카운트 제외",
            ),
        ]
    )
    await db_session.flush()

    count_response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    unread_response = await client.get("/api/v1/notifications?is_read=false", headers=auth_headers)

    assert count_response.status_code == 200
    assert count_response.json() == {"count": 1}
    assert unread_response.status_code == 200
    unread_items = unread_response.json()["items"]
    assert len(unread_items) == 1
    assert unread_items[0]["title"] == "읽지 않은 알림"
    assert unread_items[0]["is_read"] is False
    assert unread_items[0]["read_at"] is None


@pytest.mark.asyncio
async def test_mark_read_is_user_scoped_and_preserves_existing_read_timestamp(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """PATCH /notifications/{id}/read does not touch other users or rewrite read_at."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-user-id",
        role="student",
        name="Other Student",
        email="other-read@test.com",
    )
    original_read_at = datetime.now(UTC) - timedelta(days=1)
    own_read = Notification(
        user_id="test-user-id",
        type="lessonCompleted",
        priority=NotificationPriority.low,
        title="이미 읽은 알림",
        body="읽음 시각 보존",
        read_at=original_read_at,
    )
    own_unread = Notification(
        user_id="test-user-id",
        type="lessonReminder",
        priority=NotificationPriority.normal,
        title="새 알림",
        body="읽음 처리 대상",
    )
    other_unread = Notification(
        user_id="other-user-id",
        type="lessonReminder",
        priority=NotificationPriority.normal,
        title="다른 사용자 알림",
        body="접근 불가",
    )
    db_session.add_all([own_read, own_unread, other_unread])
    await db_session.flush()
    await db_session.refresh(own_read)
    persisted_read_at = own_read.read_at

    reread_response = await client.patch(f"/api/v1/notifications/{own_read.id}/read", headers=auth_headers)
    mark_response = await client.patch(f"/api/v1/notifications/{own_unread.id}/read", headers=auth_headers)
    forbidden_response = await client.patch(
        f"/api/v1/notifications/{other_unread.id}/read",
        headers=auth_headers,
    )
    await db_session.refresh(own_read)
    await db_session.refresh(own_unread)
    await db_session.refresh(other_unread)

    assert reread_response.status_code == 200
    assert mark_response.status_code == 200
    assert forbidden_response.status_code == 403
    assert own_read.read_at == persisted_read_at
    assert own_unread.read_at is not None
    assert other_unread.read_at is None


@pytest.mark.asyncio
async def test_mark_all_read_only_updates_current_user_unread_notifications(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """PATCH /notifications/read-all clears the current user's red badge only."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-user-id",
        role="student",
        name="Other Student",
        email="other-all@test.com",
    )
    db_session.add_all(
        [
            Notification(
                user_id="test-user-id",
                type="lessonReminder",
                priority=NotificationPriority.normal,
                title="현재 사용자 미읽음 1",
                body="전체 읽음 대상",
            ),
            Notification(
                user_id="test-user-id",
                type="paymentReminder",
                priority=NotificationPriority.high,
                title="현재 사용자 미읽음 2",
                body="전체 읽음 대상",
            ),
            Notification(
                user_id="other-user-id",
                type="lessonReminder",
                priority=NotificationPriority.normal,
                title="다른 사용자 미읽음",
                body="전체 읽음 제외",
            ),
        ]
    )
    await db_session.flush()

    response = await client.patch("/api/v1/notifications/read-all", headers=auth_headers)
    count_response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    other_notification = (
        await db_session.scalars(select(Notification).where(Notification.user_id == "other-user-id"))
    ).one()

    assert response.status_code == 200
    assert count_response.status_code == 200
    assert count_response.json() == {"count": 0}
    assert other_notification.read_at is None
