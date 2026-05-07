"""Notification endpoint tests."""

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
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
async def test_in_app_badge_and_list_exclude_push_only_notifications(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """The red badge and in-app list ignore push-only notifications."""
    await create_test_user(user_id="test-user-id", role="teacher")
    in_app_unread = Notification(
        user_id="test-user-id",
        type="lessonReminder",
        priority=NotificationPriority.normal,
        title="인앱 알림",
        body="붉은점 대상",
        is_push=True,
        is_in_app=True,
    )
    push_only_unread = Notification(
        user_id="test-user-id",
        type="lessonStarting",
        priority=NotificationPriority.urgent,
        title="푸시 전용 알림",
        body="앱 알림함에서는 제외",
        is_push=True,
        is_in_app=False,
    )
    db_session.add_all([in_app_unread, push_only_unread])
    await db_session.flush()

    list_response = await client.get("/api/v1/notifications", headers=auth_headers)
    count_response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    read_all_response = await client.patch("/api/v1/notifications/read-all", headers=auth_headers)
    await db_session.refresh(in_app_unread)
    await db_session.refresh(push_only_unread)

    assert list_response.status_code == 200
    items = list_response.json()["items"]
    assert [item["id"] for item in items] == [in_app_unread.id]
    assert count_response.status_code == 200
    assert count_response.json() == {"count": 1}
    assert read_all_response.status_code == 200
    assert in_app_unread.read_at is not None
    assert push_only_unread.read_at is None


@pytest.mark.asyncio
async def test_in_app_badge_and_list_exclude_future_scheduled_notifications(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """The red badge and in-app list ignore notifications scheduled for later."""
    await create_test_user(user_id="test-user-id", role="teacher")
    visible_unread = Notification(
        user_id="test-user-id",
        type="lessonReminder",
        priority=NotificationPriority.normal,
        title="현재 표시 알림",
        body="붉은점 대상",
        is_in_app=True,
    )
    future_scheduled = Notification(
        user_id="test-user-id",
        type="lessonStarting",
        priority=NotificationPriority.urgent,
        title="예약 알림",
        body="아직 표시하지 않음",
        scheduled_at=datetime.now(UTC) + timedelta(hours=1),
        is_in_app=True,
    )
    db_session.add_all([visible_unread, future_scheduled])
    await db_session.flush()

    list_response = await client.get("/api/v1/notifications", headers=auth_headers)
    count_response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    read_all_response = await client.patch("/api/v1/notifications/read-all", headers=auth_headers)
    await db_session.refresh(visible_unread)
    await db_session.refresh(future_scheduled)

    assert list_response.status_code == 200
    items = list_response.json()["items"]
    assert [item["id"] for item in items] == [visible_unread.id]
    assert count_response.status_code == 200
    assert count_response.json() == {"count": 1}
    assert read_all_response.status_code == 200
    assert visible_unread.read_at is not None
    assert future_scheduled.read_at is None


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


@pytest.mark.asyncio
async def test_notification_list_count_and_read_all_follow_recipient_role_policy(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Remote notification inbox matches mock role-target filtering for red-dot state."""
    await create_test_user(user_id="test-user-id", role="teacher")
    teacher_only = Notification(
        user_id="test-user-id",
        type="trialBookingRequest",
        priority=NotificationPriority.high,
        title="교사용 알림",
        body="표시 대상",
    )
    both = Notification(
        user_id="test-user-id",
        type="lessonReminder",
        priority=NotificationPriority.normal,
        title="공통 알림",
        body="표시 대상",
    )
    student_only = Notification(
        user_id="test-user-id",
        type="practiceReminder",
        priority=NotificationPriority.normal,
        title="학생용 알림",
        body="교사에게 숨김",
    )
    db_session.add_all([teacher_only, both, student_only])
    await db_session.flush()

    list_response = await client.get("/api/v1/notifications", headers=auth_headers)
    count_response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    read_all_response = await client.patch("/api/v1/notifications/read-all", headers=auth_headers)
    await db_session.refresh(teacher_only)
    await db_session.refresh(both)
    await db_session.refresh(student_only)

    assert list_response.status_code == 200
    assert {item["type"] for item in list_response.json()["items"]} == {
        "lessonReminder",
        "trialBookingRequest",
    }
    assert count_response.status_code == 200
    assert count_response.json() == {"count": 2}
    assert read_all_response.status_code == 200
    assert teacher_only.read_at is not None
    assert both.read_at is not None
    assert student_only.read_at is None


@pytest.mark.asyncio
async def test_parent_notifications_use_student_and_common_targets(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """Parents receive student-side child/payment notices plus common lesson notices."""
    await create_test_user(user_id="test-parent-id", role="parent", email="parent-notification@test.com")
    parent_auth_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'test-parent-id', 'role': 'parent'})}"
    }
    student_only = Notification(
        user_id="test-parent-id",
        type="paymentReminder",
        priority=NotificationPriority.high,
        title="자녀 수강료 알림",
        body="학부모 표시 대상",
    )
    both = Notification(
        user_id="test-parent-id",
        type="lessonCancelled",
        priority=NotificationPriority.high,
        title="공통 일정 알림",
        body="학부모 표시 대상",
    )
    teacher_only = Notification(
        user_id="test-parent-id",
        type="paymentReceived",
        priority=NotificationPriority.normal,
        title="교사용 입금 확인",
        body="학부모에게 숨김",
    )
    db_session.add_all([student_only, both, teacher_only])
    await db_session.flush()

    response = await client.get("/api/v1/notifications", headers=parent_auth_headers)

    assert response.status_code == 200
    assert {item["type"] for item in response.json()["items"]} == {
        "lessonCancelled",
        "paymentReminder",
    }


@pytest.mark.asyncio
async def test_teacher_notification_preferences_default_and_patch(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Teacher notification preferences are persisted remotely instead of Hive-only state."""
    await create_test_user(user_id="test-user-id", role="teacher")

    default_response = await client.get("/api/v1/notifications/preferences", headers=auth_headers)
    assert default_response.status_code == 200
    defaults = default_response.json()
    assert defaults["user_id"] == "test-user-id"
    assert defaults["role"] == "teacher"
    assert defaults["settings"]["lessonReminderEnabled"] is True
    assert defaults["settings"]["studentPracticeReport"] is False
    assert defaults["settings"]["dndStart"] == {"hour": 22, "minute": 0}
    assert defaults["settings"]["dndEnd"] == {"hour": 8, "minute": 0}
    assert defaults["created_at"] is not None
    assert defaults["updated_at"] is not None

    patch_response = await client.patch(
        "/api/v1/notifications/preferences",
        headers=auth_headers,
        json={
            "settings": {
                "studentPracticeReport": True,
                "dndEnabled": False,
            },
        },
    )
    assert patch_response.status_code == 200
    patched = patch_response.json()
    assert patched["settings"]["studentPracticeReport"] is True
    assert patched["settings"]["dndEnabled"] is False
    assert patched["settings"]["lessonReminderEnabled"] is True


@pytest.mark.asyncio
async def test_student_notification_preferences_use_student_defaults(
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
):
    """Student preferences expose practice/streak/payment settings with defaults."""
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student-pref@test.com",
    )

    response = await client.get("/api/v1/notifications/preferences", headers=student_auth_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["user_id"] == "test-student-id"
    assert body["role"] == "student"
    assert body["settings"]["practiceReminderEnabled"] is True
    assert body["settings"]["practiceReminderTime"] == {"hour": 19, "minute": 0}
    assert body["settings"]["streakWarningTime"] == {"hour": 21, "minute": 0}
    assert body["settings"]["paymentReminderEnabled"] is True
    assert body["settings"]["maxDailyNotifications"] == 5
    assert "newStudentAlert" not in body["settings"]
