"""Tests for academy endpoints — AC-M1 그룹 A.

Spec: docs/specs/web/academy/README.md (AC-M1).
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import (
    AcademyInvite,
    AcademyMember,
    AcademyMemberRole,
)

pytestmark = pytest.mark.asyncio


OWNER_USER_ID = "test-user-id"
OTHER_USER_ID = "other-user-id"


def _owner_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": OWNER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _other_user_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": OTHER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_owner(create_test_user) -> None:
    """Owner user for tests."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")


async def _seed_other_user(create_test_user) -> None:
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", name="이강사", email="teacher2@test.com")


# ---------------------------------------------------------------------------
# Academy CRUD + 1탭 onboarding (UX)
# ---------------------------------------------------------------------------


async def test_create_academy_auto_creates_owner_member(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await _seed_owner(create_test_user)
    response = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "jaepark-music", "name": "재박 음악학원"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["slug"] == "jaepark-music"
    assert body["owner_user_id"] == OWNER_USER_ID

    # 학원장이 자동으로 owner 멤버.
    member = await db_session.scalar(select(AcademyMember).where(AcademyMember.user_id == OWNER_USER_ID))
    assert member is not None
    assert member.role == AcademyMemberRole.owner


async def test_create_academy_with_also_register_as_teacher_creates_two_members(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """UX 1탭 onboarding — 학원장 + 본인 겸직 강사 1액션."""
    await _seed_owner(create_test_user)
    response = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={
            "slug": "kim-piano",
            "name": "김피아노 학원",
            "also_register_as_teacher": True,
        },
    )
    assert response.status_code == 201

    members = (await db_session.scalars(select(AcademyMember).where(AcademyMember.user_id == OWNER_USER_ID))).all()
    roles = sorted([m.role.value for m in members])
    assert roles == ["owner", "teacher"]


async def test_create_academy_duplicate_slug_returns_409(
    client: AsyncClient,
    create_test_user,
) -> None:
    await _seed_owner(create_test_user)
    response1 = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "dup-slug", "name": "학원1"},
    )
    assert response1.status_code == 201
    response2 = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "dup-slug", "name": "학원2"},
    )
    assert response2.status_code == 409


async def test_list_my_academies_returns_owned_and_member(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await _seed_owner(create_test_user)
    await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "mine-1", "name": "내 학원 1"},
    )
    await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "mine-2", "name": "내 학원 2"},
    )
    response = await client.get("/api/v1/academies/me", headers=_owner_headers())
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 2
    slugs = sorted(a["slug"] for a in body)
    assert slugs == ["mine-1", "mine-2"]


async def test_update_academy_owner_only(
    client: AsyncClient,
    create_test_user,
) -> None:
    await _seed_owner(create_test_user)
    await _seed_other_user(create_test_user)
    create_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "edit-test", "name": "원래 이름"},
    )
    academy_id = create_resp.json()["id"]
    # 다른 사용자 403.
    response = await client.patch(
        f"/api/v1/academies/{academy_id}",
        headers=_other_user_headers(),
        json={"name": "변조"},
    )
    assert response.status_code == 403

    # 학원장 본인은 OK.
    response = await client.patch(
        f"/api/v1/academies/{academy_id}",
        headers=_owner_headers(),
        json={"name": "수정된 이름"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "수정된 이름"


# ---------------------------------------------------------------------------
# Student CRUD
# ---------------------------------------------------------------------------


async def test_create_student_with_teacher_match_sets_matched_status(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """학생 등록 시 teacher_member_id 있으면 status=matched 자동 — 학원장 UX 1탭."""
    await _seed_owner(create_test_user)
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "stu-test", "name": "학생 테스트", "also_register_as_teacher": True},
    )
    academy_id = academy_resp.json()["id"]
    teacher_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )

    response = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={
            "name": "김지민",
            "instrument": "피아노",
            "teacher_member_id": teacher_member.id,
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "matched"
    assert body["matched_at"] is not None


async def test_create_student_without_teacher_sets_waiting(
    client: AsyncClient,
    create_test_user,
) -> None:
    await _seed_owner(create_test_user)
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "wait-test", "name": "대기 테스트"},
    )
    academy_id = academy_resp.json()["id"]

    response = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={"name": "박지수", "instrument": "바이올린"},
    )
    assert response.status_code == 201
    assert response.json()["status"] == "waiting"


async def test_list_students_blocked_for_non_member(
    client: AsyncClient,
    create_test_user,
) -> None:
    await _seed_owner(create_test_user)
    await _seed_other_user(create_test_user)
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "priv-test", "name": "비공개 학원"},
    )
    academy_id = academy_resp.json()["id"]
    await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={"name": "비공개 학생"},
    )
    # 다른 사용자가 학생 리스트 조회 시 403.
    response = await client.get(f"/api/v1/academies/{academy_id}/students", headers=_other_user_headers())
    assert response.status_code == 403


# ---------------------------------------------------------------------------
# Invite lifecycle
# ---------------------------------------------------------------------------


async def test_invite_full_lifecycle_owner_issue_other_accept(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """학원장 발급 → 공개 preview → 강사 수락 → AcademyMember 생성."""
    await _seed_owner(create_test_user)
    await _seed_other_user(create_test_user)
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "invite-flow", "name": "초대 플로우"},
    )
    academy_id = academy_resp.json()["id"]

    # 1. 발급.
    issue_resp = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_owner_headers(),
        json={"roles": ["teacher"], "expires_in_hours": 24},
    )
    assert issue_resp.status_code == 201
    token = issue_resp.json()["token"]
    assert token  # raw token 1회 노출

    # 2. 공개 preview (인증 X).
    preview_resp = await client.get(f"/api/v1/public/academies/invites/{token}/preview")
    assert preview_resp.status_code == 200
    preview = preview_resp.json()
    assert preview["academy_slug"] == "invite-flow"
    assert preview["is_expired"] is False
    assert preview["invited_by_name"].startswith("김")  # 마스킹

    # 3. 다른 사용자가 수락.
    accept_resp = await client.post(
        "/api/v1/academies/invites/accept",
        headers=_other_user_headers(),
        json={"public_page_consent": True},
        params={"token": token},
    )
    assert accept_resp.status_code == 200
    member = accept_resp.json()
    assert member["role"] == "teacher"
    assert member["public_page_consent"] is True

    # 4. AcademyMember 생성 확인.
    inserted = await db_session.scalar(select(AcademyMember).where(AcademyMember.user_id == OTHER_USER_ID))
    assert inserted is not None
    assert inserted.role == AcademyMemberRole.teacher


async def test_invite_revoke_blocks_accept(
    client: AsyncClient,
    create_test_user,
) -> None:
    await _seed_owner(create_test_user)
    await _seed_other_user(create_test_user)
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "revoke-test", "name": "회수 테스트"},
    )
    academy_id = academy_resp.json()["id"]
    issue_resp = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_owner_headers(),
        json={"roles": ["teacher"]},
    )
    token = issue_resp.json()["token"]
    invite_id = issue_resp.json()["id"]

    # 회수.
    revoke_resp = await client.post(
        f"/api/v1/academies/invites/{invite_id}/revoke",
        headers=_owner_headers(),
    )
    assert revoke_resp.status_code == 200
    assert revoke_resp.json()["state"] == "revoked"

    # 회수 후 수락 시도 → 409.
    accept_resp = await client.post(
        "/api/v1/academies/invites/accept",
        headers=_other_user_headers(),
        json={"public_page_consent": False},
        params={"token": token},
    )
    assert accept_resp.status_code == 409


async def test_invite_token_hash_only_stored(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """Raw token 은 DB 에 저장 X — token_hash 만."""
    await _seed_owner(create_test_user)
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "hash-test", "name": "해시 테스트"},
    )
    academy_id = academy_resp.json()["id"]
    issue_resp = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_owner_headers(),
        json={"roles": ["teacher"]},
    )
    raw_token = issue_resp.json()["token"]

    invite = await db_session.scalar(select(AcademyInvite))
    assert invite is not None
    assert invite.token_hash != raw_token
    assert len(invite.token_hash) == 64  # sha256 hex


# ---------------------------------------------------------------------------
# Member consent toggle (강사 본인만)
# ---------------------------------------------------------------------------


async def test_member_consent_owner_cannot_change_teachers_consent(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """학원장도 강사 본인의 public_page_consent 는 변경 불가 (강사 자기결정권)."""
    await _seed_owner(create_test_user)
    await _seed_other_user(create_test_user)
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": "consent-test", "name": "동의 테스트"},
    )
    academy_id = academy_resp.json()["id"]
    # 초대 + 다른 사용자 수락.
    issue_resp = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_owner_headers(),
        json={"roles": ["teacher"]},
    )
    token = issue_resp.json()["token"]
    accept_resp = await client.post(
        "/api/v1/academies/invites/accept",
        headers=_other_user_headers(),
        json={"public_page_consent": False},
        params={"token": token},
    )
    teacher_member_id = accept_resp.json()["id"]

    # 학원장이 강사 동의 변경 시도 → 403.
    response = await client.patch(
        f"/api/v1/academies/members/{teacher_member_id}/consent",
        headers=_owner_headers(),
        json={"public_page_consent": True},
    )
    assert response.status_code == 403

    # 강사 본인은 OK.
    response = await client.patch(
        f"/api/v1/academies/members/{teacher_member_id}/consent",
        headers=_other_user_headers(),
        json={"public_page_consent": True},
    )
    assert response.status_code == 200
    assert response.json()["public_page_consent"] is True
