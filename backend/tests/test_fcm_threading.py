"""FCM service threading tests (Fix #6).

The Firebase Admin SDK ``messaging.send_each`` / ``messaging.send`` calls are
blocking. They must run via ``asyncio.to_thread`` so they do not block the event
loop inside the async send methods.
"""

from __future__ import annotations

import sys
import types
from unittest.mock import MagicMock

import pytest

from app.models.notification import NotificationPriority
from app.services.fcm_service import FcmService


class _FakeSendResponse:
    def __init__(self) -> None:
        self.exception = None


class _FakeBatchResponse:
    def __init__(self, count: int) -> None:
        self.responses = [_FakeSendResponse() for _ in range(count)]


def _install_fake_messaging(monkeypatch: pytest.MonkeyPatch) -> types.SimpleNamespace:
    """Install a fake ``firebase_admin.messaging`` module and return its handle."""
    messaging = types.SimpleNamespace()

    # Builder types — return MagicMocks so message construction succeeds.
    messaging.Notification = lambda **kw: MagicMock(name="Notification")
    messaging.AndroidConfig = lambda **kw: MagicMock(name="AndroidConfig")
    messaging.AndroidNotification = lambda **kw: MagicMock(name="AndroidNotification")
    messaging.APNSConfig = lambda **kw: MagicMock(name="APNSConfig")
    messaging.APNSPayload = lambda **kw: MagicMock(name="APNSPayload")
    messaging.Aps = lambda **kw: MagicMock(name="Aps")
    messaging.ApsAlert = lambda **kw: MagicMock(name="ApsAlert")
    messaging.Message = lambda **kw: MagicMock(name="Message")

    messaging.send_each = MagicMock(side_effect=lambda msgs: _FakeBatchResponse(len(msgs)))
    messaging.send = MagicMock(return_value="projects/x/messages/1")

    fake_module = types.ModuleType("firebase_admin.messaging")
    for attr in vars(messaging):
        setattr(fake_module, attr, getattr(messaging, attr))
    monkeypatch.setitem(sys.modules, "firebase_admin.messaging", fake_module)
    return messaging


@pytest.mark.asyncio
async def test_send_to_user_uses_to_thread(monkeypatch: pytest.MonkeyPatch) -> None:
    """send_to_user dispatches messaging.send_each through asyncio.to_thread."""
    messaging = _install_fake_messaging(monkeypatch)

    service = FcmService()
    monkeypatch.setattr(service, "_ensure_initialized", lambda: True)

    # Wrap asyncio.to_thread to record what blocking callable it received.
    import app.services.fcm_service as fcm_module

    recorded: list = []
    real_to_thread = fcm_module.asyncio.to_thread

    async def spy_to_thread(func, /, *args, **kwargs):
        recorded.append(func)
        return await real_to_thread(func, *args, **kwargs)

    monkeypatch.setattr(fcm_module.asyncio, "to_thread", spy_to_thread)

    failed = await service.send_to_user(
        tokens=["tok-1", "tok-2"],
        title="t",
        body="b",
        notification_type="lessonStarting",
        priority=NotificationPriority.high,
    )

    assert failed == []  # no failures from the fake batch
    assert messaging.send_each.call_count == 1
    # The blocking send_each must have been routed through to_thread.
    assert messaging.send_each in recorded


@pytest.mark.asyncio
async def test_send_to_topic_uses_to_thread(monkeypatch: pytest.MonkeyPatch) -> None:
    """send_to_topic dispatches messaging.send through asyncio.to_thread."""
    messaging = _install_fake_messaging(monkeypatch)

    service = FcmService()
    monkeypatch.setattr(service, "_ensure_initialized", lambda: True)

    import app.services.fcm_service as fcm_module

    recorded: list = []
    real_to_thread = fcm_module.asyncio.to_thread

    async def spy_to_thread(func, /, *args, **kwargs):
        recorded.append(func)
        return await real_to_thread(func, *args, **kwargs)

    monkeypatch.setattr(fcm_module.asyncio, "to_thread", spy_to_thread)

    ok = await service.send_to_topic(
        topic="news",
        title="t",
        body="b",
        notification_type="announcement",
    )

    assert ok is True
    assert messaging.send.call_count == 1
    assert messaging.send in recorded


@pytest.mark.asyncio
async def test_send_to_user_smoke_returns_empty_when_no_tokens() -> None:
    """No tokens → no send attempted, returns empty list (happy-path unchanged)."""
    service = FcmService()
    failed = await service.send_to_user(
        tokens=[],
        title="t",
        body="b",
        notification_type="lessonStarting",
    )
    assert failed == []
