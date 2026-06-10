"""Issue #631 — 학원 초대 409 응답 detail 에 error_code 명시 필드."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

OWNER_USER_ID = "owner-user-id"
OTHER_USER_ID = "other-user-id"


def _owner_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": OWNER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _other_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": OTHER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_users(create_test_user) -> None:
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장", email="owner@test.com")
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", name="박강사", email="other@test.com")


async def _issue_invite(client: AsyncClient) -> tuple[str, str, str]:
    """학원 + invite 발급 → (academy_id, invite_id, token)."""
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "err-code-test", "name": "error_code 테스트"},
    )
    academy_id = academy_resp.json()["id"]
    issue_resp = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_owner_headers(),
        json={"roles": ["teacher"]},
    )
    return academy_id, issue_resp.json()["id"], issue_resp.json()["token"]


@pytest.mark.asyncio
async def test_accept_revoked_invite_returns_error_code_revoked(
    client: AsyncClient,
    create_test_user,
):
    """이미 회수된 invite 수락 → 409 + detail.error_code='revoked'."""
    await _seed_users(create_test_user)
    _, invite_id, token = await _issue_invite(client)

    # 회수.
    await client.post(
        f"/api/v1/academies/invites/{invite_id}/revoke",
        headers=_owner_headers(),
    )

    # 수락 시도.
    response = await client.post(
        "/api/v1/academies/invites/accept",
        headers=_other_headers(),
        json={"public_page_consent": False},
        params={"token": token},
    )

    assert response.status_code == 409, response.text
    body = response.json()
    detail = body["detail"]
    assert isinstance(detail, dict), f"detail must be dict, got {type(detail)}"
    assert detail["error_code"] == "revoked"
    assert "revoked" in detail["message"]


@pytest.mark.asyncio
async def test_revoke_already_accepted_invite_returns_error_code(
    client: AsyncClient,
    create_test_user,
):
    """이미 수락된 invite 회수 시도 → 409 + detail.error_code='accepted'."""
    await _seed_users(create_test_user)
    _, invite_id, token = await _issue_invite(client)

    # 다른 사용자가 수락.
    await client.post(
        "/api/v1/academies/invites/accept",
        headers=_other_headers(),
        json={"public_page_consent": False},
        params={"token": token},
    )

    # 회수 시도.
    response = await client.post(
        f"/api/v1/academies/invites/{invite_id}/revoke",
        headers=_owner_headers(),
    )

    assert response.status_code == 409, response.text
    detail = response.json()["detail"]
    assert isinstance(detail, dict)
    assert detail["error_code"] == "accepted"


@pytest.mark.asyncio
async def test_accept_expired_invite_returns_error_code_expired(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """만료 시점 지난 invite 수락 → 409 + detail.error_code='expired'."""
    from datetime import UTC, datetime, timedelta

    from app.models.academy import AcademyInvite

    await _seed_users(create_test_user)
    _, invite_id, token = await _issue_invite(client)

    # 만료 시간을 과거로.
    invite = await db_session.get(AcademyInvite, invite_id)
    invite.expires_at = datetime.now(UTC) - timedelta(hours=1)
    await db_session.flush()
    await db_session.commit()

    response = await client.post(
        "/api/v1/academies/invites/accept",
        headers=_other_headers(),
        json={"public_page_consent": False},
        params={"token": token},
    )

    assert response.status_code == 409, response.text
    detail = response.json()["detail"]
    assert isinstance(detail, dict)
    assert detail["error_code"] == "expired"
