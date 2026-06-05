"""Tests for /scheduler/audit/cleanup-context-denials — AC-M2 §9 retention cron."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.academy_governance import ContextAccessDenialLog

pytestmark = pytest.mark.asyncio

ENDPOINT = "/api/v1/scheduler/audit/cleanup-context-denials"


def _denial(*, user_id: str, denied_at: datetime) -> ContextAccessDenialLog:
    return ContextAccessDenialLog(
        user_id=user_id,
        active_context="teacher",
        academy_id=None,
        denial_code="FORBIDDEN_TEACHER_SCOPE",
        endpoint_path="/api/v1/test",
        http_method="GET",
        target_resource_id=None,
        denied_at=denied_at,
    )


async def test_cleanup_endpoint_requires_internal_api_key(client: AsyncClient, monkeypatch) -> None:
    """미인증 호출 → 401."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    response = await client.post(ENDPOINT)
    assert response.status_code == 401


async def test_cleanup_endpoint_rejects_wrong_internal_api_key(client: AsyncClient, monkeypatch) -> None:
    """잘못된 키 → 401."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    response = await client.post(ENDPOINT, headers={"X-Internal-API-Key": "wrong"})
    assert response.status_code == 401


async def test_cleanup_deletes_old_denials_within_default_retention(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    monkeypatch,
) -> None:
    """default 365일 — 그 이전 행 삭제, 이후 행 보존."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    user = await create_test_user(user_id="cleanup-user", role="teacher")
    now = datetime.now(UTC)
    old = _denial(user_id=user.id, denied_at=now - timedelta(days=400))
    fresh = _denial(user_id=user.id, denied_at=now - timedelta(days=30))
    db_session.add_all([old, fresh])
    await db_session.commit()

    response = await client.post(ENDPOINT, headers={"X-Internal-API-Key": "test-internal-key"})
    assert response.status_code == 200
    body = response.json()
    assert body["deleted"] == 1
    assert body["retention_days"] == 365

    remaining = await db_session.scalar(select(func.count()).select_from(ContextAccessDenialLog))
    assert remaining == 1
    survivor = await db_session.scalar(select(ContextAccessDenialLog))
    assert survivor.id == fresh.id


async def test_cleanup_honors_retention_days_override(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    monkeypatch,
) -> None:
    """retention_days=7 → 7일 이전 행 모두 삭제."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    user = await create_test_user(user_id="cleanup-user-7", role="teacher")
    now = datetime.now(UTC)
    db_session.add_all(
        [
            _denial(user_id=user.id, denied_at=now - timedelta(days=10)),
            _denial(user_id=user.id, denied_at=now - timedelta(days=8)),
            _denial(user_id=user.id, denied_at=now - timedelta(days=3)),  # 보존
        ]
    )
    await db_session.commit()

    response = await client.post(
        f"{ENDPOINT}?retention_days=7",
        headers={"X-Internal-API-Key": "test-internal-key"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["deleted"] == 2
    assert body["retention_days"] == 7

    remaining = await db_session.scalar(select(func.count()).select_from(ContextAccessDenialLog))
    assert remaining == 1


async def test_cleanup_returns_zero_when_nothing_to_delete(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    monkeypatch,
) -> None:
    """모든 행이 보존 기간 내 → deleted=0."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    user = await create_test_user(user_id="cleanup-user-empty", role="teacher")
    db_session.add(_denial(user_id=user.id, denied_at=datetime.now(UTC)))
    await db_session.commit()

    response = await client.post(ENDPOINT, headers={"X-Internal-API-Key": "test-internal-key"})
    assert response.status_code == 200
    assert response.json()["deleted"] == 0


# ---------------------------------------------------------------------------
# GET /audit/access-denials — 운영자 어드민 전체 조회 (§9)
# ---------------------------------------------------------------------------


ADMIN_LIST_ENDPOINT = "/api/v1/scheduler/audit/access-denials"


async def test_admin_list_requires_internal_api_key(client: AsyncClient, monkeypatch) -> None:
    """인증 없으면 401."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    response = await client.get(ADMIN_LIST_ENDPOINT)
    assert response.status_code == 401


async def test_admin_list_returns_all_users_audit(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    monkeypatch,
) -> None:
    """운영자 조회는 모든 user 의 audit 반환 (본인 조회와 구분)."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    u1 = await create_test_user(user_id="admin-list-u1", role="teacher")
    u2 = await create_test_user(user_id="admin-list-u2", role="teacher", email="u2@test.com")
    now = datetime.now(UTC)
    db_session.add_all(
        [
            _denial(user_id=u1.id, denied_at=now - timedelta(hours=1)),
            _denial(user_id=u2.id, denied_at=now - timedelta(hours=2)),
        ]
    )
    await db_session.commit()

    response = await client.get(ADMIN_LIST_ENDPOINT, headers={"X-Internal-API-Key": "test-internal-key"})
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 2
    user_ids = {log["user_id"] for log in body["logs"]}
    assert user_ids == {u1.id, u2.id}


async def test_admin_list_filters_by_user_id(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    monkeypatch,
) -> None:
    """`?user_id=` 로 특정 user 만 필터링."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    u1 = await create_test_user(user_id="admin-filter-u1", role="teacher")
    u2 = await create_test_user(user_id="admin-filter-u2", role="teacher", email="u2f@test.com")
    now = datetime.now(UTC)
    db_session.add_all([_denial(user_id=u1.id, denied_at=now), _denial(user_id=u2.id, denied_at=now)])
    await db_session.commit()

    response = await client.get(
        f"{ADMIN_LIST_ENDPOINT}?user_id={u1.id}",
        headers={"X-Internal-API-Key": "test-internal-key"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert body["logs"][0]["user_id"] == u1.id


async def test_admin_list_filters_by_time_range(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    monkeypatch,
) -> None:
    """`?from_at=&to_at=` 로 시각 범위 필터."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    user = await create_test_user(user_id="admin-time-u", role="teacher")
    now = datetime.now(UTC)
    db_session.add_all(
        [
            _denial(user_id=user.id, denied_at=now - timedelta(days=10)),  # 범위 밖
            _denial(user_id=user.id, denied_at=now - timedelta(days=3)),  # 범위 내
            _denial(user_id=user.id, denied_at=now - timedelta(days=1)),  # 범위 내
        ]
    )
    await db_session.commit()

    from_at = (now - timedelta(days=5)).isoformat()
    to_at = now.isoformat()
    response = await client.get(
        ADMIN_LIST_ENDPOINT,
        params={"from_at": from_at, "to_at": to_at},
        headers={"X-Internal-API-Key": "test-internal-key"},
    )
    assert response.status_code == 200
    assert response.json()["total_count"] == 2


async def test_admin_list_filters_by_denial_code(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    monkeypatch,
) -> None:
    """`?denial_code=` 로 차단 코드별 조회."""
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")
    user = await create_test_user(user_id="admin-code-u", role="teacher")
    now = datetime.now(UTC)
    teacher_scope = _denial(user_id=user.id, denied_at=now)
    teacher_scope.denial_code = "FORBIDDEN_TEACHER_SCOPE"
    not_yours = _denial(user_id=user.id, denied_at=now)
    not_yours.denial_code = "FORBIDDEN_NOT_YOUR_STUDENT"
    db_session.add_all([teacher_scope, not_yours])
    await db_session.commit()

    response = await client.get(
        f"{ADMIN_LIST_ENDPOINT}?denial_code=FORBIDDEN_NOT_YOUR_STUDENT",
        headers={"X-Internal-API-Key": "test-internal-key"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert body["logs"][0]["denial_code"] == "FORBIDDEN_NOT_YOUR_STUDENT"
