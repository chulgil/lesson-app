"""Phase 31 — DELETE /notifications/{id} endpoint regression.

FE 가 swipe-to-delete UI 에서 호출하던 endpoint 가 BE 에 부재 → 추가.
"""

from __future__ import annotations

from datetime import UTC, datetime

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


async def _seed_notification(db_session: AsyncSession, user_id: str) -> str:
    from app.models.notification import Notification, NotificationPriority

    notif = Notification(
        user_id=user_id,
        type="lessonBooked",
        priority=NotificationPriority.normal,
        title="레슨 예약",
        body="2126-07-06 14:00 레슨이 예약되었습니다.",
        is_push=True,
        is_in_app=True,
        sent_at=datetime.now(UTC),
    )
    db_session.add(notif)
    await db_session.flush()
    return notif.id


@pytest.mark.asyncio
async def test_delete_notification_removes_row(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """본인 알림 삭제 → 204 + DB 에서 사라짐."""
    from app.models.notification import Notification

    await create_test_user(user_id="test-user-id", role="teacher")
    notif_id = await _seed_notification(db_session, "test-user-id")
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/notifications/{notif_id}",
        headers=_headers("test-user-id", "teacher"),
    )

    assert response.status_code == 204, response.text
    db_session.expire_all()
    assert await db_session.get(Notification, notif_id) is None


@pytest.mark.asyncio
async def test_delete_notification_not_found_returns_404(
    client: AsyncClient,
    create_test_user,
):
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.delete(
        "/api/v1/notifications/00000000-0000-0000-0000-000000000000",
        headers=_headers("test-user-id", "teacher"),
    )

    assert response.status_code == 404, response.text


@pytest.mark.asyncio
async def test_delete_other_users_notification_returns_403(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """다른 사용자 알림 삭제 시도 → 403."""
    await create_test_user(user_id="owner-user-id", role="teacher")
    await create_test_user(user_id="other-user-id", role="teacher", email="o@test.com")
    notif_id = await _seed_notification(db_session, "owner-user-id")
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/notifications/{notif_id}",
        headers=_headers("other-user-id", "teacher"),
    )

    assert response.status_code == 403, response.text
