"""Phase 6a — Postgres advisory lock helper tests.

Plan C §1 다중 인스턴스 발화 방어:
- pg_try_advisory_lock(<key>) 으로 동시 실행 방지
- sqlite/test 환경: no-op (항상 True)
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest


@pytest.mark.asyncio
async def test_advisory_lock_sqlite_returns_true() -> None:
    """sqlite (테스트) dialect 에서는 lock 우회 — 항상 True."""
    from app.core.scheduler import try_advisory_lock

    bind = MagicMock()
    bind.dialect.name = "sqlite"
    conn = AsyncMock()
    conn.get_bind = MagicMock(return_value=bind)

    acquired = await try_advisory_lock(conn, key=12345)
    assert acquired is True


@pytest.mark.asyncio
async def test_advisory_lock_postgres_acquires_when_free() -> None:
    """Postgres 에서 lock 미점유 시 True 반환."""
    from app.core.scheduler import try_advisory_lock

    bind = MagicMock()
    bind.dialect.name = "postgresql"
    conn = AsyncMock()
    conn.get_bind = MagicMock(return_value=bind)

    result = MagicMock()
    result.scalar_one = MagicMock(return_value=True)
    conn.execute = AsyncMock(return_value=result)

    acquired = await try_advisory_lock(conn, key=12345)
    assert acquired is True
    conn.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_advisory_lock_postgres_blocks_when_held() -> None:
    """Postgres 에서 lock 이 다른 인스턴스 점유 시 False 반환."""
    from app.core.scheduler import try_advisory_lock

    bind = MagicMock()
    bind.dialect.name = "postgresql"
    conn = AsyncMock()
    conn.get_bind = MagicMock(return_value=bind)

    result = MagicMock()
    result.scalar_one = MagicMock(return_value=False)
    conn.execute = AsyncMock(return_value=result)

    acquired = await try_advisory_lock(conn, key=12345)
    assert acquired is False


@pytest.mark.asyncio
async def test_advisory_lock_key_for_job_is_deterministic() -> None:
    """동일 job_name 에 대해 advisory lock key 가 동일 (다중 인스턴스 동기화 보장)."""
    from app.core.scheduler import advisory_lock_key

    k1 = advisory_lock_key("subscription_expiry_check")
    k2 = advisory_lock_key("subscription_expiry_check")
    k3 = advisory_lock_key("attendance_unconfirmed_check")
    assert k1 == k2
    assert k1 != k3
    # PG advisory lock 은 bigint — int64 범위 내
    assert -(2**63) <= k1 < 2**63
