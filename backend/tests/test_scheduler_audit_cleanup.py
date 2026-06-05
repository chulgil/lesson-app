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
