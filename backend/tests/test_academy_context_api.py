"""Tests for /auth/context endpoints — AC-M2 Context Toggle."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import jwt as _jwt
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import create_access_token
from app.models.academy import AcademyMember, AcademyMemberRole
from app.models.academy_governance import (
    AcademyContext,
    AcademyDelegation,
    ContextSwitchLog,
    DelegationReason,
    DelegationState,
)

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"
OTHER_USER_ID = "other-user-id"


def _owner_headers(active_context: str | None = None, academy_id: str | None = None) -> dict[str, str]:
    payload = {"sub": OWNER_USER_ID, "role": "teacher"}
    if active_context:
        payload["active_context"] = active_context
    if academy_id:
        payload["academy_id"] = academy_id
    return {"Authorization": f"Bearer {create_access_token(data=payload)}"}


def _decode(token: str) -> dict:
    return _jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


async def _create_academy_with_owner_teacher(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> str:
    """학원장 = 겸직 강사인 학원 셋업. Returns academy_id."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={
            "slug": f"ctx-{uuid4().hex[:8]}",
            "name": "컨텍스트 테스트",
            "also_register_as_teacher": True,
        },
    )
    return academy_resp.json()["id"]


# ---------------------------------------------------------------------------
# GET /context
# ---------------------------------------------------------------------------


async def test_get_context_lists_available_contexts(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원장+겸직 강사 user → available_contexts 2개."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    response = await client.get("/api/v1/auth/context", headers=_owner_headers())
    assert response.status_code == 200
    body = response.json()
    assert body["user_id"] == OWNER_USER_ID
    assert len(body["available_contexts"]) == 2
    contexts = sorted([c["context"] for c in body["available_contexts"]])
    assert contexts == ["academy_owner", "teacher"]


async def test_get_context_active_context_reflects_jwt(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """JWT 페이로드의 active_context/academy_id 가 응답에 반영."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    response = await client.get(
        "/api/v1/auth/context",
        headers=_owner_headers(active_context="academy_owner", academy_id=academy_id),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["active_context"] == "academy_owner"
    assert body["academy_id"] == academy_id


# ---------------------------------------------------------------------------
# POST /context/switch
# ---------------------------------------------------------------------------


async def test_switch_to_teacher_returns_new_jwt(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    response = await client.post(
        "/api/v1/auth/context/switch",
        headers=_owner_headers(active_context="academy_owner", academy_id=academy_id),
        json={"target_context": "teacher", "academy_id": academy_id},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["active_context"] == "teacher"
    assert body["academy_id"] == academy_id
    # 새 JWT 페이로드 검증.
    payload = _decode(body["access_token"])
    assert payload["sub"] == OWNER_USER_ID
    assert payload["active_context"] == "teacher"
    assert payload["academy_id"] == academy_id
    # redirect_url 힌트.
    assert body["redirect_url"] == "/today"


async def test_switch_to_owner_returns_console_redirect(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    response = await client.post(
        "/api/v1/auth/context/switch",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
        json={"target_context": "academy_owner", "academy_id": academy_id},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["active_context"] == "academy_owner"
    assert body["redirect_url"].startswith("/console")


async def test_switch_blocked_when_no_member_role(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원에 멤버 아님 → 403."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", name="외부", email="ext@test.com")

    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}
    response = await client.post(
        "/api/v1/auth/context/switch",
        headers=other_headers,
        json={"target_context": "academy_owner", "academy_id": academy_id},
    )
    assert response.status_code == 403
    detail = response.json()["detail"]
    assert detail["error"] == "FORBIDDEN_CONTEXT_SWITCH"
    assert detail["available_contexts"] == []  # 멤버 아님


async def test_context_switch_logs_audit(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """토글 시 ContextSwitchLog 자동 기록."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    await client.post(
        "/api/v1/auth/context/switch",
        headers=_owner_headers(active_context="academy_owner", academy_id=academy_id),
        json={"target_context": "teacher", "academy_id": academy_id},
    )
    log = await db_session.scalar(
        select(ContextSwitchLog)
        .where(ContextSwitchLog.user_id == OWNER_USER_ID)
        .where(ContextSwitchLog.academy_id == academy_id)
    )
    assert log is not None
    assert log.to_context == AcademyContext.teacher


async def test_owner_return_auto_ends_active_delegation(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원장이 academy_owner 모드로 진입 시 활성 위임 자동 종료."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)
    # teacher 멤버 가져오기 (delegatee 후보 — 학원장 본인 겸직 강사).
    teacher_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    # 활성 위임 수기 삽입.
    now = datetime.now(UTC)
    delegation = AcademyDelegation(
        academy_id=academy_id,
        delegator_user_id=OWNER_USER_ID,
        delegatee_member_id=teacher_member.id,
        permissions=["inbox.reply"],
        starts_at=now - timedelta(hours=1),
        ends_at=now + timedelta(days=1),
        reason=DelegationReason.trip,
        state=DelegationState.active,
    )
    db_session.add(delegation)
    await db_session.commit()

    # 학원장이 academy_owner 모드로 진입 → 위임 자동 종료.
    response = await client.post(
        "/api/v1/auth/context/switch",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
        json={"target_context": "academy_owner", "academy_id": academy_id},
    )
    assert response.status_code == 200

    # 위임 state 확인.
    await db_session.refresh(delegation)
    assert delegation.state == DelegationState.auto_ended


# ---------------------------------------------------------------------------
# GET /auth/me/access-denials — 학원 무관 본인 audit 조회 (spec §9)
# ---------------------------------------------------------------------------


async def test_global_access_denials_includes_academy_less_records(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원 관련 차단 + 학원 무관 차단 모두 본인 audit 에 포함."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    # 학원 관련 차단 발생
    resp_owner = await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
    )
    assert resp_owner.status_code == 403

    # 학원 무관 차단 발생 (recordings)
    resp_global = await client.get(
        "/api/v1/recordings",
        headers=_owner_headers(active_context="academy_owner"),
    )
    assert resp_global.status_code == 403

    # /auth/me/access-denials 는 두 행 모두 포함
    response = await client.get(
        "/api/v1/auth/me/access-denials",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 2
    codes = sorted(log["denial_code"] for log in body["logs"])
    assert codes == ["FORBIDDEN_ACADEMY_OWNER_SCOPE", "FORBIDDEN_TEACHER_SCOPE"]


async def test_global_access_denials_excludes_other_user(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """다른 user 의 차단은 제외."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", email="other@test.com")

    # OTHER user 가 차단당함
    other_token = create_access_token(data={"sub": OTHER_USER_ID, "role": "teacher", "active_context": "academy_owner"})
    resp_other = await client.get(
        "/api/v1/recordings",
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert resp_other.status_code == 403

    # 본인 audit 조회는 OTHER 차단 미포함
    response = await client.get(
        "/api/v1/auth/me/access-denials",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    assert response.json()["total_count"] == 0


async def test_global_access_denials_filters_by_denial_code(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """denial_code 쿼리 파라미터로 필터링."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    # 2종류 차단 발생
    await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
    )
    await client.get(
        "/api/v1/recordings",
        headers=_owner_headers(active_context="academy_owner"),
    )

    response = await client.get(
        "/api/v1/auth/me/access-denials?denial_code=FORBIDDEN_TEACHER_SCOPE",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert body["logs"][0]["denial_code"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_global_access_denials_requires_auth(client: AsyncClient) -> None:
    """인증 없는 호출 → 401."""
    response = await client.get("/api/v1/auth/me/access-denials")
    assert response.status_code == 401


async def test_global_access_denials_works_in_teacher_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """본인 데이터 조회는 모드 무관 — teacher 모드에서도 통과."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)

    # academy_owner 모드로 차단 1건 발생
    await client.get(
        "/api/v1/recordings",
        headers=_owner_headers(active_context="academy_owner"),
    )

    # teacher 모드에서도 본인 audit 조회 가능
    response = await client.get(
        "/api/v1/auth/me/access-denials",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 200
    assert response.json()["total_count"] == 1


# ---------------------------------------------------------------------------
# §7.2 JWT revocation — 토글 직후 이전 JWT 만료, 새 JWT 통과
# ---------------------------------------------------------------------------


async def test_switch_revokes_previous_access_token(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """CT-09 시나리오: 토글 직후 이전 access token 으로 호출 → 401."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)
    previous_headers = _owner_headers(active_context="academy_owner", academy_id=academy_id)
    # 호출 가능 확인
    pre = await client.get("/api/v1/auth/context", headers=previous_headers)
    assert pre.status_code == 200

    # 토글 — 이전 토큰의 jti 가 TokenBlacklist 에 추가됨
    switch = await client.post(
        "/api/v1/auth/context/switch",
        headers=previous_headers,
        json={"target_context": "teacher", "academy_id": academy_id},
    )
    assert switch.status_code == 200
    new_token = switch.json()["access_token"]

    # 이전 토큰 → 401
    post_prev = await client.get("/api/v1/auth/context", headers=previous_headers)
    assert post_prev.status_code == 401

    # 새 토큰 → 200
    post_new = await client.get(
        "/api/v1/auth/context",
        headers={"Authorization": f"Bearer {new_token}"},
    )
    assert post_new.status_code == 200


async def test_switch_records_jti_in_token_blacklist(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """토글 시 이전 토큰 jti 가 TokenBlacklist 에 정확히 등록되는지 검증."""
    from app.models.user import TokenBlacklist

    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)
    headers = _owner_headers(active_context="academy_owner", academy_id=academy_id)
    previous_jti = _decode(headers["Authorization"].split()[1])["jti"]

    await client.post(
        "/api/v1/auth/context/switch",
        headers=headers,
        json={"target_context": "teacher", "academy_id": academy_id},
    )

    row = await db_session.scalar(select(TokenBlacklist).where(TokenBlacklist.jti == previous_jti))
    assert row is not None
    assert row.user_id == OWNER_USER_ID


async def test_jti_less_legacy_token_still_works(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """레거시 토큰 (jti 없음) 은 blacklist 통과 — backward compat."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    # jti 를 제거하기 위해 수동으로 토큰 생성 (decode → del jti → re-encode)
    raw = create_access_token(data={"sub": OWNER_USER_ID, "role": "teacher"})
    payload = _decode(raw)
    payload.pop("jti", None)
    legacy = _jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    response = await client.get(
        "/api/v1/auth/context",
        headers={"Authorization": f"Bearer {legacy}"},
    )
    assert response.status_code == 200


async def test_new_access_token_includes_jti(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """create_access_token 자동 jti 부여 — payload 에 uuid 형식 jti 포함."""
    academy_id = await _create_academy_with_owner_teacher(client, db_session, create_test_user)
    response = await client.post(
        "/api/v1/auth/context/switch",
        headers=_owner_headers(active_context="academy_owner", academy_id=academy_id),
        json={"target_context": "teacher", "academy_id": academy_id},
    )
    assert response.status_code == 200
    payload = _decode(response.json()["access_token"])
    assert "jti" in payload
    assert len(payload["jti"]) >= 32  # uuid4 length
