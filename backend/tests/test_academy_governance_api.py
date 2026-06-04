"""Tests for academy governance endpoints — AC-M1 그룹 B."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import AcademyMember, AcademyMemberRole
from app.models.academy_governance import (
    AcademyActivityLog,
    AcademyContext,
    AcademyDelegationAction,
    ContextSwitchLog,
    ContextSwitchTrigger,
)

pytestmark = pytest.mark.asyncio


OWNER_USER_ID = "test-user-id"
OTHER_USER_ID = "other-user-id"


def _owner_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': OWNER_USER_ID, 'role': 'teacher'})}"}


def _other_user_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}


async def _create_academy_with_teacher(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> tuple[str, str]:
    """Helper: 학원 + 강사 1명 (other user 가 강사 멤버) 셋업.

    Returns: (academy_id, teacher_member_id)
    """
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", name="이강사", email="t2@test.com")

    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": f"gov-{uuid4().hex[:8]}", "name": "거버넌스 테스트"},
    )
    academy_id = academy_resp.json()["id"]

    # 다른 사용자를 강사로 초대 + 수락.
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
    return academy_id, teacher_member_id


# ---------------------------------------------------------------------------
# Delegation start + active query
# ---------------------------------------------------------------------------


async def test_start_delegation_requires_confirmation(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """UX: 명시 confirmation 없이는 시작 불가."""
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)

    now = datetime.now(UTC)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/delegations",
        headers=_owner_headers(),
        json={
            "delegatee_member_id": teacher_member_id,
            "permissions": ["billing.collect"],
            "starts_at": now.isoformat(),
            "ends_at": (now + timedelta(days=1)).isoformat(),
            "reason": "trip",
            "confirmation": False,
        },
    )
    assert response.status_code == 400


async def test_start_delegation_happy_path_creates_active(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)

    now = datetime.now(UTC)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/delegations",
        headers=_owner_headers(),
        json={
            "delegatee_member_id": teacher_member_id,
            "permissions": ["billing.collect", "inbox.reply"],
            "starts_at": now.isoformat(),
            "ends_at": (now + timedelta(days=3)).isoformat(),
            "reason": "trip",
            "reason_note": "출장 3일",
            "confirmation": True,
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["state"] == "active"
    assert body["permissions"] == ["billing.collect", "inbox.reply"]


async def test_start_delegation_blocks_concurrent(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """동시 위임 1개 제한 — 두 번째 시도 409."""
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)
    now = datetime.now(UTC)
    payload = {
        "delegatee_member_id": teacher_member_id,
        "permissions": ["billing.collect"],
        "starts_at": now.isoformat(),
        "ends_at": (now + timedelta(days=1)).isoformat(),
        "reason": "trip",
        "confirmation": True,
    }
    r1 = await client.post(f"/api/v1/academies/{academy_id}/delegations", headers=_owner_headers(), json=payload)
    assert r1.status_code == 201
    r2 = await client.post(f"/api/v1/academies/{academy_id}/delegations", headers=_owner_headers(), json=payload)
    assert r2.status_code == 409


async def test_start_delegation_blocks_invalid_range(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)
    now = datetime.now(UTC)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/delegations",
        headers=_owner_headers(),
        json={
            "delegatee_member_id": teacher_member_id,
            "permissions": ["inbox.reply"],
            "starts_at": (now + timedelta(days=2)).isoformat(),
            "ends_at": (now + timedelta(days=1)).isoformat(),  # 잘못된 순서
            "reason": "trip",
            "confirmation": True,
        },
    )
    assert response.status_code == 400


async def test_get_active_delegation_returns_null_when_none(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    academy_id, _ = await _create_academy_with_teacher(client, db_session, create_test_user)
    response = await client.get(f"/api/v1/academies/{academy_id}/delegations/active", headers=_owner_headers())
    assert response.status_code == 200
    assert response.json() is None


async def test_revoke_delegation_owner_only(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)
    now = datetime.now(UTC)
    start_resp = await client.post(
        f"/api/v1/academies/{academy_id}/delegations",
        headers=_owner_headers(),
        json={
            "delegatee_member_id": teacher_member_id,
            "permissions": ["inbox.reply"],
            "starts_at": now.isoformat(),
            "ends_at": (now + timedelta(days=1)).isoformat(),
            "reason": "trip",
            "confirmation": True,
        },
    )
    delegation_id = start_resp.json()["id"]

    # 학원장이 아닌 다른 사용자 → 403.
    response = await client.delete(f"/api/v1/academies/delegations/{delegation_id}", headers=_other_user_headers())
    assert response.status_code == 403

    # 학원장 OK.
    response = await client.delete(f"/api/v1/academies/delegations/{delegation_id}", headers=_owner_headers())
    assert response.status_code == 200
    assert response.json()["state"] == "revoked"


# ---------------------------------------------------------------------------
# Delegation actions — audit + 검토
# ---------------------------------------------------------------------------


async def test_review_actions_bulk_approve(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)
    now = datetime.now(UTC)
    start_resp = await client.post(
        f"/api/v1/academies/{academy_id}/delegations",
        headers=_owner_headers(),
        json={
            "delegatee_member_id": teacher_member_id,
            "permissions": ["inbox.reply"],
            "starts_at": now.isoformat(),
            "ends_at": (now + timedelta(days=1)).isoformat(),
            "reason": "trip",
            "confirmation": True,
        },
    )
    delegation_id = start_resp.json()["id"]

    # 액션 audit 행 수기 삽입 (실제로는 middleware 가 기록).
    action_ids = []
    for i in range(3):
        action = AcademyDelegationAction(
            delegation_id=delegation_id,
            performed_at=now,
            performed_by_user_id=OTHER_USER_ID,
            permission_used="inbox.reply",
            endpoint=f"POST /api/v1/inbox/reply/{i}",
            response_status=200,
        )
        db_session.add(action)
    await db_session.commit()
    actions = (
        await db_session.scalars(
            select(AcademyDelegationAction).where(AcademyDelegationAction.delegation_id == delegation_id)
        )
    ).all()
    action_ids = [a.id for a in actions]
    assert len(action_ids) == 3

    # 리스트 — pending 3건.
    list_resp = await client.get(
        f"/api/v1/academies/delegations/{delegation_id}/actions",
        headers=_owner_headers(),
    )
    assert list_resp.status_code == 200
    assert list_resp.json()["pending_review_count"] == 3

    # 전체 승인.
    review_resp = await client.post(
        f"/api/v1/academies/delegations/{delegation_id}/actions/review",
        headers=_owner_headers(),
        json={"action_ids": action_ids, "bulk_approve": True},
    )
    assert review_resp.status_code == 200
    assert review_resp.json()["reviewed_count"] == 3

    # pending 0 으로 갱신됐는지.
    list_resp = await client.get(
        f"/api/v1/academies/delegations/{delegation_id}/actions",
        headers=_owner_headers(),
    )
    assert list_resp.json()["pending_review_count"] == 0


# ---------------------------------------------------------------------------
# Activity Log — 학원장 전체 / 강사 본인 (NFR-A-5)
# ---------------------------------------------------------------------------


async def test_activity_log_owner_sees_all_teacher_sees_own_only(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)
    # owner member 도 가져오기 (academy 생성 시 자동 생성).
    owner_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.owner)
    )

    # 활동 로그 수기 삽입 (실제로는 다른 서비스 호출).
    now = datetime.now(UTC)
    db_session.add_all(
        [
            AcademyActivityLog(
                academy_id=academy_id,
                actor_member_id=teacher_member_id,
                actor_name="이강사",
                action_type="lesson_completed",
                description="피아노 50분 레슨 완료",
                created_at=now,
            ),
            AcademyActivityLog(
                academy_id=academy_id,
                actor_member_id=owner_member.id,
                actor_name="김원장",
                action_type="announcement_sent",
                description="공지 발송",
                created_at=now,
            ),
        ]
    )
    await db_session.commit()

    # 학원장 = 전체 2건.
    owner_resp = await client.get(f"/api/v1/academies/{academy_id}/activities", headers=_owner_headers())
    assert owner_resp.status_code == 200
    assert owner_resp.json()["total_count"] == 2

    # 강사 = 본인 1건만.
    teacher_resp = await client.get(f"/api/v1/academies/{academy_id}/activities", headers=_other_user_headers())
    assert teacher_resp.status_code == 200
    assert teacher_resp.json()["total_count"] == 1
    assert teacher_resp.json()["activities"][0]["actor_member_id"] == teacher_member_id


async def test_activity_log_teacher_cannot_filter_other_actor(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """강사가 actor_member_id 로 다른 강사 활동 조회 시도 → 403."""
    academy_id, teacher_member_id = await _create_academy_with_teacher(client, db_session, create_test_user)
    owner_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.owner)
    )

    response = await client.get(
        f"/api/v1/academies/{academy_id}/activities",
        headers=_other_user_headers(),
        params={"actor_member_id": owner_member.id},
    )
    assert response.status_code == 403


# ---------------------------------------------------------------------------
# ContextSwitchLog — 학원장 본인 토글 audit (감사 투명성)
# ---------------------------------------------------------------------------


async def test_context_switch_log_lists_own_only(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    academy_id, _ = await _create_academy_with_teacher(client, db_session, create_test_user)
    now = datetime.now(UTC)
    # 토글 audit 수기 삽입.
    db_session.add_all(
        [
            ContextSwitchLog(
                user_id=OWNER_USER_ID,
                academy_id=academy_id,
                from_context=AcademyContext.academy_owner,
                to_context=AcademyContext.teacher,
                switched_at=now,
                triggered_by=ContextSwitchTrigger.user,
            ),
            ContextSwitchLog(
                user_id=OTHER_USER_ID,  # 다른 사용자 로그
                academy_id=academy_id,
                from_context=AcademyContext.academy_owner,
                to_context=AcademyContext.teacher,
                switched_at=now,
                triggered_by=ContextSwitchTrigger.user,
            ),
        ]
    )
    await db_session.commit()

    response = await client.get(f"/api/v1/academies/{academy_id}/context-switches/me", headers=_owner_headers())
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1  # 본인 것만
    assert body["logs"][0]["user_id"] == OWNER_USER_ID
