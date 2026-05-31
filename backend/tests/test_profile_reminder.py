"""Tests for ProfileReminderService.

Covers: 24h / 3d / 7d reminder dispatch, pre-condition checks, and
duplicate-send prevention.
"""
from __future__ import annotations

from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, patch

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification, NotificationPriority
from app.models.teacher import Teacher
from app.models.user import User, UserRole
from app.services.profile_reminder_service import (
    ProfileReminderService,
    _TYPE_24H,
    _TYPE_3D,
    _TYPE_7D,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_user(db: AsyncSession, *, user_id: str, created_hours_ago: float, profile_image_url: str | None = None) -> User:
    user = User(
        id=user_id,
        email=f"{user_id}@test.com",
        name="Test Teacher",
        role=UserRole.teacher,
        profile_image_url=profile_image_url,
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
        currency="KRW",
        created_at=datetime.now(UTC) - timedelta(hours=created_hours_ago),
    )
    db.add(user)
    return user


def _make_teacher(db: AsyncSession, *, user_id: str, introduction: str | None = None, instruments: list | None = None) -> Teacher:
    teacher = Teacher(
        id=f"{user_id}-t",
        user_id=user_id,
        instruments=instruments or [],
        introduction=introduction,
    )
    db.add(teacher)
    return teacher


async def _add_sent_notification(db: AsyncSession, *, user_id: str, notification_type: str) -> None:
    notif = Notification(
        id=f"{user_id}-{notification_type}",
        user_id=user_id,
        type=notification_type,
        title="sent",
        body="sent",
        priority=NotificationPriority.normal,
    )
    db.add(notif)
    await db.flush()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_24h_reminder_sent_when_profile_incomplete(db_session: AsyncSession):
    """24h 알림: 가입 후 24~72시간, 완성도 < 50% → 발송."""
    _make_user(db_session, user_id="u1", created_hours_ago=30)
    _make_teacher(db_session, user_id="u1", introduction=None, instruments=[])
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["24h"] == 1
    assert counts["3d"] == 0
    assert counts["7d"] == 0
    mock_send.assert_awaited_once()
    kwargs = mock_send.call_args.kwargs
    assert kwargs["notification_type"] == _TYPE_24H


@pytest.mark.asyncio
async def test_no_reminder_before_24h(db_session: AsyncSession):
    """24h 미만: 어떤 알림도 발송 안 함."""
    _make_user(db_session, user_id="u2", created_hours_ago=12)
    _make_teacher(db_session, user_id="u2", introduction=None, instruments=[])
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts == {"24h": 0, "3d": 0, "7d": 0}
    mock_send.assert_not_awaited()


@pytest.mark.asyncio
async def test_24h_no_reminder_when_profile_complete(db_session: AsyncSession):
    """24h 구간이지만 완성도 >= 50% → 24h 알림 안 보냄."""
    _make_user(db_session, user_id="u3", created_hours_ago=36, profile_image_url="https://img/photo.jpg")
    _make_teacher(
        db_session,
        user_id="u3",
        introduction="This is my introduction with more than twenty chars",
        instruments=["violin"],
    )
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["24h"] == 0
    mock_send.assert_not_awaited()


@pytest.mark.asyncio
async def test_3d_reminder_sent_when_no_photo(db_session: AsyncSession):
    """3d 알림: 가입 후 72~168시간, 프로필 사진 없음 → 발송."""
    _make_user(db_session, user_id="u4", created_hours_ago=96, profile_image_url=None)
    _make_teacher(db_session, user_id="u4")
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["3d"] == 1
    mock_send.assert_awaited_once()
    kwargs = mock_send.call_args.kwargs
    assert kwargs["notification_type"] == _TYPE_3D


@pytest.mark.asyncio
async def test_3d_no_reminder_when_photo_exists(db_session: AsyncSession):
    """3d 구간이지만 프로필 사진 있음 → 3d 알림 안 보냄."""
    _make_user(db_session, user_id="u5", created_hours_ago=100, profile_image_url="https://img/me.jpg")
    _make_teacher(db_session, user_id="u5")
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["3d"] == 0
    mock_send.assert_not_awaited()


@pytest.mark.asyncio
async def test_7d_reminder_sent_when_no_introduction(db_session: AsyncSession):
    """7d 알림: 가입 후 168~336시간, 소개글 없음 → 발송."""
    _make_user(db_session, user_id="u6", created_hours_ago=200)
    _make_teacher(db_session, user_id="u6", introduction=None)
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["7d"] == 1
    mock_send.assert_awaited_once()
    kwargs = mock_send.call_args.kwargs
    assert kwargs["notification_type"] == _TYPE_7D


@pytest.mark.asyncio
async def test_7d_no_reminder_when_introduction_exists(db_session: AsyncSession):
    """7d 구간이지만 소개글 있음 → 7d 알림 안 보냄."""
    _make_user(db_session, user_id="u7", created_hours_ago=200)
    _make_teacher(db_session, user_id="u7", introduction="저는 10년 경력의 바이올린 선생님입니다.")
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["7d"] == 0
    mock_send.assert_not_awaited()


@pytest.mark.asyncio
async def test_no_duplicate_reminders(db_session: AsyncSession):
    """이미 발송된 타입은 중복 발송 안 함."""
    _make_user(db_session, user_id="u8", created_hours_ago=30)
    _make_teacher(db_session, user_id="u8", introduction=None, instruments=[])
    await _add_sent_notification(db_session, user_id="u8", notification_type=_TYPE_24H)

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["24h"] == 0
    mock_send.assert_not_awaited()


@pytest.mark.asyncio
async def test_no_reminder_after_336h(db_session: AsyncSession):
    """336시간 초과: 어떤 알림도 발송 안 함."""
    _make_user(db_session, user_id="u9", created_hours_ago=400)
    _make_teacher(db_session, user_id="u9", introduction=None, instruments=[])
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts == {"24h": 0, "3d": 0, "7d": 0}
    mock_send.assert_not_awaited()


@pytest.mark.asyncio
async def test_multiple_teachers_independent(db_session: AsyncSession):
    """복수 선생님: 각자 독립적으로 처리."""
    # Teacher A: 24h window, incomplete profile
    _make_user(db_session, user_id="ua", created_hours_ago=30)
    _make_teacher(db_session, user_id="ua", instruments=[], introduction=None)
    # Teacher B: 7d window, no introduction
    _make_user(db_session, user_id="ub", created_hours_ago=200)
    _make_teacher(db_session, user_id="ub", introduction=None)
    await db_session.flush()

    with patch(
        "app.services.notification_service.NotificationService.create_and_send",
        new_callable=AsyncMock,
    ) as mock_send:
        service = ProfileReminderService(db_session)
        counts = await service.dispatch_reminders()

    assert counts["24h"] == 1
    assert counts["7d"] == 1
    assert mock_send.await_count == 2
