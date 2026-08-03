"""Regression test: stale/invalid FCM token cleanup must not crash notification sends.

Bug: notification_service.py called ``token_service.unregister(token)`` with a
single argument, but ``DeviceTokenService.unregister`` requires ``(token,
user_id)``. Any push send where FCM reports a stale token raised TypeError
inside ``create_and_send``, turning the entire business action (booking,
announcement, payment notice, ...) into a 500.
"""

from __future__ import annotations

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.device_token import DeviceTokenCreate
from app.services.device_token_service import DeviceTokenService
from app.services.notification_service import NotificationService


@pytest.mark.asyncio
async def test_create_and_send_cleans_up_stale_token_without_crashing(
    db_session: AsyncSession, create_test_user, monkeypatch: pytest.MonkeyPatch
) -> None:
    user = await create_test_user(user_id="teacher-stale-token", role="teacher")

    token_service = DeviceTokenService(db_session)
    await token_service.register(user.id, DeviceTokenCreate(token="stale-token-abc", platform="ios"))
    await db_session.flush()

    import app.services.notification_service as notification_service_module

    async def _fake_send_to_user(**kwargs):
        return ["stale-token-abc"]

    monkeypatch.setattr(notification_service_module._fcm_service, "send_to_user", _fake_send_to_user)

    service = NotificationService(db_session)
    await service.create_and_send(
        user_id=user.id,
        notification_type="lesson_reminder",
        title="Test",
        body="Test body",
    )

    remaining_tokens = await token_service.get_tokens_for_user(user.id)
    assert remaining_tokens == []
