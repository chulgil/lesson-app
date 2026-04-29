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
from app.core.scheduler import advisory_lock_key, try_advisory_lock
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

        service = SubscriptionExpiryService(session)
        check = await service.run_daily_check()

        dispatcher = SubscriptionExpiryDispatcher(session)
        dispatch = await dispatcher.dispatch_milestones(
            check["milestones"],
            today_kst=check["today_kst"],
        )

        await session.commit()

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
