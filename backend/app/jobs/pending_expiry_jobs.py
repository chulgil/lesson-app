"""Pending lesson-request (14d) + subscription-proposal (7d) expiry cron jobs (#1198).

신청/제안 만료는 그동안 internal-API 엔드포인트로만 집행돼, 외부 cron 이 설정되지
않은 배포에서는 만료가 영영 실행되지 않아 신청/제안이 영구 pending 으로 잔존했다.
subscription 만료 · schedule-change 72h 만료와 동일하게 in-process APScheduler
daily job 으로 등록해 배포 config 의존을 제거한다 (wiring 은 `app.main` lifespan).

각 runner 는 테스트에서 session 을 주입하고, 프로덕션에서는 새 세션을 열어 PG
advisory lock 으로 다중 인스턴스 동시 발화를 방어한다 (schedule_change_expiry
패턴 미러). 처리 건수를 dict 로 반환해 ops 관측에 쓴다.
"""

from __future__ import annotations

import logging
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.scheduler import (
    advisory_lock_key,
    release_advisory_lock,
    try_advisory_lock,
)

logger = logging.getLogger(__name__)

JOB_ID_LESSON_REQUEST_EXPIRY = "lesson_request_expiry_daily"
JOB_ID_PROPOSAL_EXPIRY = "subscription_proposal_expiry_daily"


async def _run_lesson_request_expiry(session: AsyncSession | None = None) -> dict[str, Any]:
    async def _do(s: AsyncSession) -> dict[str, Any]:
        from app.services.lesson_request_service import LessonRequestService

        return {"expired": await LessonRequestService(s).process_expired()}

    if session is not None:
        out = await _do(session)
        out["lock_acquired"] = True
        return out

    async with AsyncSessionLocal() as new_session:
        lock_key = advisory_lock_key(JOB_ID_LESSON_REQUEST_EXPIRY)
        acquired = await try_advisory_lock(new_session, key=lock_key)
        if not acquired:
            logger.info("%s: advisory lock not acquired, skip cycle", JOB_ID_LESSON_REQUEST_EXPIRY)
            return {"expired": 0, "lock_acquired": False}
        try:
            out = await _do(new_session)
            await new_session.commit()
        finally:
            await release_advisory_lock(new_session, key=lock_key)
        out["lock_acquired"] = True
    logger.info("lesson_request_expiry_job: %s", out)
    return out


async def run_lesson_request_expiry_job(session: AsyncSession | None = None) -> dict[str, Any]:
    """Daily — expire pending/negotiating lesson requests past their 14d TTL.

    Idempotent: `process_expired` only touches rows still pending/negotiating
    with `expires_at <= now`. Test injects `session`; prod opens its own.
    """
    return await _run_lesson_request_expiry(session=session)


async def _run_proposal_expiry(session: AsyncSession | None = None) -> dict[str, Any]:
    async def _do(s: AsyncSession) -> dict[str, Any]:
        from app.services.subscription_service import SubscriptionService

        return {"expired": await SubscriptionService(s).expire_stale_proposals_systemwide()}

    if session is not None:
        out = await _do(session)
        out["lock_acquired"] = True
        return out

    async with AsyncSessionLocal() as new_session:
        lock_key = advisory_lock_key(JOB_ID_PROPOSAL_EXPIRY)
        acquired = await try_advisory_lock(new_session, key=lock_key)
        if not acquired:
            logger.info("%s: advisory lock not acquired, skip cycle", JOB_ID_PROPOSAL_EXPIRY)
            return {"expired": 0, "lock_acquired": False}
        try:
            out = await _do(new_session)
            await new_session.commit()
        finally:
            await release_advisory_lock(new_session, key=lock_key)
        out["lock_acquired"] = True
    logger.info("proposal_expiry_job: %s", out)
    return out


async def run_proposal_expiry_job(session: AsyncSession | None = None) -> dict[str, Any]:
    """Daily — expire pending/paymentNotified subscription proposals past 7d TTL.

    Uses the system-wide sweep (no teacher filter) — safe because the caller is
    the scheduler, not a teacher acting via the API (see #468 1d guard).
    """
    return await _run_proposal_expiry(session=session)
