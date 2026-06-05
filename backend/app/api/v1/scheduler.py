"""Scheduler endpoints for automated attendance processing.

These endpoints are designed to be called by cron jobs or admin tools.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, require_internal_api_key
from app.services.attendance_scheduler_service import AttendanceSchedulerService

router = APIRouter(dependencies=[Depends(require_internal_api_key)])


@router.post(
    "/attendance/notify-unconfirmed",
    status_code=status.HTTP_200_OK,
    summary="Notify unconfirmed lessons (30min+)",
)
async def notify_unconfirmed(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict[str, int]:
    """Send notifications for unconfirmed lessons (30+ minutes past end time)."""
    service = AttendanceSchedulerService(db)
    count = await service.notify_unconfirmed_lessons()
    return {"notified": count}


@router.post(
    "/attendance/auto-complete",
    status_code=status.HTTP_200_OK,
    summary="Auto-complete expired lessons (24h+)",
)
async def auto_complete(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict[str, int]:
    """Auto-complete lessons unconfirmed for 24+ hours."""
    service = AttendanceSchedulerService(db)
    count = await service.auto_complete_expired_lessons()
    return {"auto_completed": count}


@router.post(
    "/attendance/detect-absence-patterns",
    status_code=status.HTTP_200_OK,
    summary="Detect absence patterns (2+ in 14 days)",
)
async def detect_absences(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict[str, int]:
    """Detect and alert consecutive absence patterns."""
    service = AttendanceSchedulerService(db)
    count = await service.detect_absence_patterns()
    return {"alerts_sent": count}


@router.post(
    "/attendance/run-all",
    status_code=status.HTTP_200_OK,
    summary="Run all attendance automation tasks",
)
async def run_all(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict[str, int]:
    """Run all three attendance automation tasks in sequence."""
    service = AttendanceSchedulerService(db)

    notified = await service.notify_unconfirmed_lessons()
    auto_completed = await service.auto_complete_expired_lessons()
    alerts = await service.detect_absence_patterns()

    return {
        "notified": notified,
        "auto_completed": auto_completed,
        "alerts_sent": alerts,
    }


@router.post(
    "/audit/cleanup-context-denials",
    status_code=status.HTTP_200_OK,
    summary="Cleanup ContextAccessDenialLog rows older than retention (§9: 1년 default)",
)
async def cleanup_context_access_denials(
    db: Annotated[AsyncSession, Depends(get_db)],
    retention_days: int = 365,
) -> dict[str, int]:
    """Spec §9 — 권한 매트릭스 차단 audit 1년 보존 cron.

    retention_days 를 override 하면 운영 정책에 따라 연장/단축 가능
    (예: 분쟁 대응 연장 또는 GDPR 단축 요청).
    """
    from app.services.academy_governance_service import AcademyGovernanceService

    deleted = await AcademyGovernanceService(db).cleanup_old_access_denials(retention_days=retention_days)
    return {"deleted": deleted, "retention_days": retention_days}
