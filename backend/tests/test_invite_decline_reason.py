"""Issue #632 — 학원 초대 decline reason 저장 + owner 알림 regression."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

OWNER_USER_ID = "owner-user-id"
INVITEE_USER_ID = "invitee-user-id"


def _owner_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": OWNER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _invitee_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": INVITEE_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_users(create_test_user) -> None:
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="원장", email="o@test.com")
    await create_test_user(user_id=INVITEE_USER_ID, role="teacher", name="강사", email="i@test.com")


async def _issue_invite(client: AsyncClient) -> str:
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "decline-test", "name": "거절 테스트"},
    )
    academy_id = academy_resp.json()["id"]
    issue_resp = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_owner_headers(),
        json={"roles": ["teacher"]},
    )
    return issue_resp.json()["token"]


@pytest.mark.asyncio
async def test_decline_with_reason_persists_and_notifies_owner(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """decline 호출 시 declined_reason 컬럼 저장 + owner 알림 발송."""
    from app.models.academy import AcademyInvite, AcademyInviteState
    from app.models.notification import Notification

    await _seed_users(create_test_user)
    token = await _issue_invite(client)

    response = await client.post(
        "/api/v1/academies/invites/decline",
        headers=_invitee_headers(),
        params={"token": token},
        json={"reason": "다른 학원 계약 중입니다"},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    invite = await db_session.scalar(select(AcademyInvite).where(AcademyInvite.state == AcademyInviteState.declined))
    assert invite is not None
    assert invite.declined_reason == "다른 학원 계약 중입니다"
    # 알림 — owner 에게.
    notifs = (
        await db_session.scalars(
            select(Notification)
            .where(Notification.user_id == OWNER_USER_ID)
            .where(Notification.type == "academyInviteDeclined")
        )
    ).all()
    assert len(notifs) == 1
    assert "다른 학원 계약 중" in (notifs[0].body or "")
    assert (notifs[0].data or {}).get("reason") == "다른 학원 계약 중입니다"


@pytest.mark.asyncio
async def test_decline_with_empty_reason_stores_none(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """빈 reason → declined_reason=None + 알림 body 는 사유 없이."""
    from app.models.academy import AcademyInvite, AcademyInviteState
    from app.models.notification import Notification

    await _seed_users(create_test_user)
    token = await _issue_invite(client)

    response = await client.post(
        "/api/v1/academies/invites/decline",
        headers=_invitee_headers(),
        params={"token": token},
        json={"reason": "   "},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    invite = await db_session.scalar(select(AcademyInvite).where(AcademyInvite.state == AcademyInviteState.declined))
    assert invite.declined_reason is None
    notif = await db_session.scalar(
        select(Notification)
        .where(Notification.user_id == OWNER_USER_ID)
        .where(Notification.type == "academyInviteDeclined")
    )
    assert notif is not None
    assert "사유" not in (notif.body or "")


@pytest.mark.asyncio
async def test_decline_without_reason_field(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """reason 키 자체 미전송 → declined_reason=None."""
    from app.models.academy import AcademyInvite, AcademyInviteState

    await _seed_users(create_test_user)
    token = await _issue_invite(client)

    response = await client.post(
        "/api/v1/academies/invites/decline",
        headers=_invitee_headers(),
        params={"token": token},
        json={},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    invite = await db_session.scalar(select(AcademyInvite).where(AcademyInvite.state == AcademyInviteState.declined))
    assert invite.declined_reason is None
