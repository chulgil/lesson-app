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
from typing import Protocol

from apscheduler.schedulers.asyncio import AsyncIOScheduler  # type: ignore[import-untyped]
from apscheduler.triggers.cron import CronTrigger  # type: ignore[import-untyped]
from sqlalchemy import text

logger = logging.getLogger(__name__)

# KST timezone — patch_plans/C §1 Lore-constraint: KST 자정 기준 D-day 산정
SCHEDULER_TIMEZONE = "Asia/Seoul"

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

    호출자는 같은 connection 에서 작업 종료 후 자동 unlock (session 종료) 또는
    `pg_advisory_unlock` 으로 명시 해제.
    """
    bind = conn.get_bind()
    if bind.dialect.name != "postgresql":
        return True

    result = await conn.execute(text("SELECT pg_try_advisory_lock(:key)").bindparams(key=key))
    acquired = bool(result.scalar_one())
    if not acquired:
        logger.info("advisory_lock not acquired (held by another instance) key=%s", key)
    return acquired


def get_scheduler() -> AsyncIOScheduler:
    """Return module-level singleton scheduler (lazy init)."""
    global _scheduler
    if _scheduler is None:
        _scheduler = AsyncIOScheduler(timezone=SCHEDULER_TIMEZONE)
    return _scheduler


def register_daily_kst_job(
    func: Callable[[], Awaitable[None]],
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
