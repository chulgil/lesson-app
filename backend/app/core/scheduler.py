"""APScheduler in-process cron infrastructure — Plan C Phase 6a.

다중 인스턴스 발화 방어:
1. PostgreSQL advisory lock (`pg_try_advisory_lock`) — 서로 다른 인스턴스 간 동기화
2. dedup table (subscription_expiry_dispatch_log UNIQUE) — 알림 중복 차단

KST 타임존 기준 cron schedule (00:05 KST = 15:05 UTC).
"""

from __future__ import annotations

import hashlib
import logging
from collections.abc import Awaitable, Callable
from typing import Any, Protocol

from apscheduler.schedulers.asyncio import AsyncIOScheduler  # type: ignore[import-untyped]
from apscheduler.triggers.cron import CronTrigger  # type: ignore[import-untyped]
from apscheduler.triggers.interval import (
    IntervalTrigger,  # type: ignore[import-untyped]  # noqa: F401 — used in register_interval_job
)
from sqlalchemy import text

from app.core.timezones import DEFAULT_TIMEZONE_NAME

logger = logging.getLogger(__name__)

# KST timezone — patch_plans/C §1 Lore-constraint: KST 자정 기준 D-day 산정
SCHEDULER_TIMEZONE = DEFAULT_TIMEZONE_NAME

_scheduler: AsyncIOScheduler | None = None


class _AsyncBindLike(Protocol):
    """AsyncConnection-compatible interface for advisory_lock helper."""

    async def execute(self, statement, *args, **kwargs): ...  # type: ignore[no-untyped-def]

    def get_bind(self): ...  # type: ignore[no-untyped-def]


def advisory_lock_key(job_name: str) -> int:
    """Map job_name → deterministic int64 advisory lock key.

    PG `pg_try_advisory_lock(bigint)` 는 int64. blake2b 16-byte digest 의 상위
    8바이트를 signed int64 로 변환.
    """
    digest = hashlib.blake2b(job_name.encode("utf-8"), digest_size=8).digest()
    raw = int.from_bytes(digest, "big", signed=False)
    if raw >= 2**63:
        raw -= 2**64
    return raw


async def try_advisory_lock(conn: _AsyncBindLike, *, key: int) -> bool:
    """Postgres `pg_try_advisory_lock` — 다른 dialect (sqlite test) 는 항상 True.

    **중요**: PG advisory lock 은 session-scope 라 connection pool 에 반환되면 다음 사용자가
    그 connection 을 빌리면서 lock 도 함께 빌리게 된다. 누수 방지를 위해 호출자는 작업 종료 후
    반드시 ``release_advisory_lock`` 을 ``finally`` 블록에서 호출해야 한다.
    """
    bind = conn.get_bind()
    if bind.dialect.name != "postgresql":
        return True

    result = await conn.execute(text("SELECT pg_try_advisory_lock(:key)").bindparams(key=key))
    acquired = bool(result.scalar_one())
    if not acquired:
        logger.info("advisory_lock not acquired (held by another instance) key=%s", key)
    return acquired


async def release_advisory_lock(conn: _AsyncBindLike, *, key: int) -> None:
    """Postgres `pg_advisory_unlock` — connection pool 누수 차단.

    SQLite / 기타 dialect 는 노옵. PG 에서 unlock 실패해도 예외를 던지지 않고 logger.warning
    만 남긴다 (이미 작업은 끝났고 다음 cycle 에서 lock 재시도하면 됨).
    """
    bind = conn.get_bind()
    if bind.dialect.name != "postgresql":
        return
    try:
        await conn.execute(text("SELECT pg_advisory_unlock(:key)").bindparams(key=key))
    except Exception:  # noqa: BLE001
        logger.warning("advisory_lock release failed key=%s — connection 회수 시 자연 해제 기대", key)


def get_scheduler() -> AsyncIOScheduler:
    """Return module-level singleton scheduler (lazy init)."""
    global _scheduler
    if _scheduler is None:
        _scheduler = AsyncIOScheduler(timezone=SCHEDULER_TIMEZONE)
    return _scheduler


def register_daily_kst_job(
    func: Callable[[], Awaitable[Any]],
    *,
    job_id: str,
    hour: int,
    minute: int,
) -> None:
    """Register a daily KST job. Idempotent (replace_existing=True)."""
    sched = get_scheduler()
    sched.add_job(
        func,
        trigger=CronTrigger(hour=hour, minute=minute, timezone=SCHEDULER_TIMEZONE),
        id=job_id,
        replace_existing=True,
        misfire_grace_time=300,  # 5min — 인스턴스 시작 직후 catch-up 허용
    )
    logger.info("scheduler: registered job id=%s at %02d:%02d KST", job_id, hour, minute)


def register_interval_job(
    func: Callable[[], Awaitable[Any]],
    *,
    job_id: str,
    hours: int = 0,
    minutes: int = 0,
) -> None:
    """Register a repeating interval job. Idempotent (replace_existing=True).

    72h 정밀도 만료 처리처럼 매 N시간마다 실행이 필요한 job 에 사용한다.
    """
    sched = get_scheduler()
    sched.add_job(
        func,
        trigger=IntervalTrigger(hours=hours, minutes=minutes),
        id=job_id,
        replace_existing=True,
        misfire_grace_time=300,
    )
    logger.info(
        "scheduler: registered interval job id=%s every %dh%dm",
        job_id,
        hours,
        minutes,
    )


def start_scheduler() -> None:
    """Start the scheduler (idempotent)."""
    sched = get_scheduler()
    if not sched.running:
        sched.start()
        logger.info("scheduler: started (jobs=%d)", len(sched.get_jobs()))


def shutdown_scheduler() -> None:
    """Shutdown the scheduler (idempotent). wait=False — 진행 중 job 강제 중단."""
    global _scheduler
    if _scheduler is not None and _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("scheduler: shutdown complete")
    _scheduler = None
