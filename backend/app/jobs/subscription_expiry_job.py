"""Subscription expiry daily cron job — Plan C Phase 6c entry point.

Composes:
1. PG advisory lock (다중 인스턴스 발화 방어)
2. `SubscriptionExpiryService.run_daily_check()` — status 전이 + milestones
3. `SubscriptionExpiryDispatcher.dispatch_milestones()` — FCM + in-app + dedup_log

Wiring (register_daily_kst_job hour=0 minute=5 KST = 15:05 UTC) 은 `app.main` lifespan 에서.
"""

from __future__ import annotations

import logging
from typing import Any

from app.core.database import AsyncSessionLocal
from app.core.scheduler import (  # noqa: F401  release 는 finally 블록에서 사용 — ruff 가 일부 케이스에서 detect 못함.
    advisory_lock_key,
    release_advisory_lock,
    try_advisory_lock,
)
from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher
from app.services.subscription_expiry_service import SubscriptionExpiryService

logger = logging.getLogger(__name__)

JOB_ID = "subscription_expiry_daily"


async def run_subscription_expiry_job() -> dict[str, Any]:
    """Daily run — caller agnostic (scheduler or manual API).

    Returns metrics dict for ops observability::

        {
            "transitions": int,
            "milestones": int,         # milestones found (= notif candidate count)
            "sent": int,
            "deduplicated": int,
            "today_kst": date,
            "lock_acquired": bool,
        }

    `lock_acquired=False` 시 다른 인스턴스가 이미 처리 중. status 전이/dispatch skip.
    """
    lock_key = advisory_lock_key(JOB_ID)

    async with AsyncSessionLocal() as session:
        acquired = await try_advisory_lock(session, key=lock_key)
        if not acquired:
            logger.info("subscription_expiry_job: advisory lock not acquired, skip cycle")
            return {
                "transitions": 0,
                "milestones": 0,
                "sent": 0,
                "deduplicated": 0,
                "today_kst": None,
                "lock_acquired": False,
            }

        try:
            service = SubscriptionExpiryService(session)
            check = await service.run_daily_check()

            # status 전이를 먼저 commit — 이후 dispatch 가 실패해도 전이는 보존되어 다음 cycle 에서
            # dedup_log 가 dispatch 만 redo 한다. 이전엔 단일 commit 으로 묶여 dispatch 실패 시
            # 전이도 rollback 되었다.
            await session.commit()

            dispatcher = SubscriptionExpiryDispatcher(session)
            dispatch = await dispatcher.dispatch_milestones(
                check["milestones"],
                today_kst=check["today_kst"],
            )

            await session.commit()
        finally:
            # PG advisory lock 누수 차단 — pool 반환된 connection 이 lock 을 들고 있으면
            # 다음 사용자가 무관한 코드에서 그 lock 을 들고 있는 상태가 된다.
            await release_advisory_lock(session, key=lock_key)

        result = {
            "transitions": check["transitions"],
            "milestones": len(check["milestones"]),
            "sent": dispatch["sent"],
            "deduplicated": dispatch["deduplicated"],
            "today_kst": check["today_kst"],
            "lock_acquired": True,
        }
        logger.info("subscription_expiry_job: %s", result)
        return result
