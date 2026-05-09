"""Re-engagement daily cron job — Gap #1 entry point.

비활성 사용자에게 단계별 복귀 알림 발송:
1. 7일 비활성: 온화한 리마인더 (이번 주 레슨을 정리해보세요)
2. 14일 비활성: 에스컬레이션 (학생들이 기다리고 있어요)
3. 30일 비활성: 윈백 오퍼 (복귀 혜택을 확인하세요)

Wiring (register_daily_kst_job hour=9 minute=0 KST = 00:00 UTC) 은 `app.main` lifespan 에서.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

from app.core.database import AsyncSessionLocal
from app.services.reengagement_service import send_reengagement_notifications

logger = logging.getLogger(__name__)

JOB_ID = "reengagement_daily"


async def run_reengagement_job() -> dict[str, Any]:
    """Daily re-engagement notification job.

    Returns metrics dict for ops observability::

        {
            "completed": bool,
            "timestamp": str,
        }
    """
    async with AsyncSessionLocal() as session:
        try:
            await send_reengagement_notifications(session)
            logger.info("reengagement_job: completed successfully")
            return {
                "completed": True,
                "timestamp": datetime.now(UTC).isoformat(),
            }
        except Exception as e:
            logger.error("reengagement_job: failed with error: %s", e, exc_info=True)
            return {
                "completed": False,
                "timestamp": datetime.now(UTC).isoformat(),
            }
