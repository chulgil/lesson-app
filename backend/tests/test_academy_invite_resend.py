"""Issue #634 — 학원 초대 재발송 endpoint regression."""

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
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="원장", email="o@test.com")
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", name="다른", email="x@test.com")


async def _issue_invite(client: AsyncClient) -> tuple[str, str]:
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "resend-test", "name": "재발송 테스트"},
    )
    academy_id = academy_resp.json()["id"]
    issue_resp = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_owner_headers(),
        json={"roles": ["teacher"]},
    )
    return issue_resp.json()["id"], issue_resp.json()["token"]


@pytest.mark.asyncio
async def test_resend_pending_invite_issues_new_token(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """pending invite 재발송 → 새 token + 갱신된 expires_at."""
    from app.models.academy import AcademyInvite

    await _seed_users(create_test_user)
    invite_id, original_token = await _issue_invite(client)

    # DB 의 원래 token_hash + expires_at 백업.
    original_invite = await db_session.get(AcademyInvite, invite_id)
    original_hash = original_invite.token_hash
    original_expires = original_invite.expires_at
    await db_session.commit()

    response = await client.post(
        f"/api/v1/academies/invites/{invite_id}/resend",
        headers=_owner_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    new_token = body["token"]
    # 새 token 은 원본과 다름.
    assert new_token != original_token
    # share_url 도 새 token 으로 갱신.
    assert new_token in body["share_url"]
    # DB token_hash 가 교체됨.
    db_session.expire_all()
    refreshed = await db_session.get(AcademyInvite, invite_id)
    assert refreshed.token_hash != original_hash
    # expires_at 갱신 (>= 원본).
    assert refreshed.expires_at >= original_expires


@pytest.mark.asyncio
async def test_resend_revoked_invite_returns_409_with_error_code(
    client: AsyncClient,
    create_test_user,
):
    """이미 회수된 invite resend → 409 + error_code='revoked'."""
    await _seed_users(create_test_user)
    invite_id, _ = await _issue_invite(client)

    # 회수.
    await client.post(
        f"/api/v1/academies/invites/{invite_id}/revoke",
        headers=_owner_headers(),
    )

    response = await client.post(
        f"/api/v1/academies/invites/{invite_id}/resend",
        headers=_owner_headers(),
    )

    assert response.status_code == 409, response.text
    detail = response.json()["detail"]
    assert isinstance(detail, dict)
    assert detail["error_code"] == "revoked"


@pytest.mark.asyncio
async def test_resend_by_non_owner_rejected(
    client: AsyncClient,
    create_test_user,
):
    """소유자 아닌 사람의 resend → 403 (require_owner_context)."""
    await _seed_users(create_test_user)
    invite_id, _ = await _issue_invite(client)

    response = await client.post(
        f"/api/v1/academies/invites/{invite_id}/resend",
        headers=_other_headers(),
    )

    assert response.status_code in (403, 404), response.text


@pytest.mark.asyncio
async def test_resend_nonexistent_invite_returns_404(
    client: AsyncClient,
    create_test_user,
):
    await _seed_users(create_test_user)
    # academy 만 생성 (owner_context 통과용).
    await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "nf-test", "name": "404 테스트"},
    )

    response = await client.post(
        "/api/v1/academies/invites/00000000-0000-0000-0000-000000000000/resend",
        headers=_owner_headers(),
    )

    assert response.status_code == 404, response.text
