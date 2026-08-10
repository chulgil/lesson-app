"""Vacation return announcement cron — #4 H-001 §6.3.

Daily KST 08:05 job that walks `VacationPeriod` rows whose `end_date` was
yesterday (in KST) and `cancelled_at IS NULL`, then fans out the
`LNZ_TEACHER_VACATION_RETURNED` alimtalk to every student/phone that
originally received the announce notice.

Idempotency: alimtalk side already keys rows by
`(vacation_period_id, recipient_phone, template_id)`, so re-running this job
on subsequent days is safe — already-sent rows short-circuit.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.scheduler import (  # noqa: F401  release 는 finally 블록에서 사용 — ruff 가 일부 케이스에서 detect 못함.
    advisory_lock_key,
    release_advisory_lock,
    try_advisory_lock,
)
from app.models.schedule import LessonBooking, VacationPeriod

logger = logging.getLogger(__name__)

JOB_ID = "vacation_return_announcement"

_KST = timezone(timedelta(hours=9))


async def _send_returns_for_period(session: AsyncSession, period: VacationPeriod) -> int:
    """Fan out LNZ_TEACHER_VACATION_RETURNED to every impacted student.

    Audience is the union of:
      * students whose bookings still carry this `vacation_period_id`
        (freeCancel / makeupCredit dispositions left a trail)
      * students who had active bookings during the period (rollForward path)
    Mirrors the announce/cancel audience policy so all three dispositions
    receive the return notice.
    """
    from app.models.student import Student
    from app.services.alimtalk_service import build_alimtalk_service
    from app.services.notification_service import (
        NotificationService,  # spec §6.3 in-app companion
    )

    student_ids: set[str] = set()

    cancelled_rows = (
        await session.scalars(
            select(LessonBooking.student_id).where(
                LessonBooking.vacation_period_id == period.id,
            )
        )
    ).all()
    student_ids.update(s for s in cancelled_rows if s)

    active_during = (
        await session.scalars(
            select(LessonBooking.student_id).where(
                LessonBooking.teacher_id == period.teacher_id,
                LessonBooking.scheduled_date >= period.start_date,
                LessonBooking.scheduled_date <= period.end_date,
            )
        )
    ).all()
    student_ids.update(s for s in active_during if s)

    if not student_ids:
        return 0

    students = (await session.scalars(select(Student).where(Student.id.in_(student_ids)))).all()
    service = build_alimtalk_service(session)
    notification_service = NotificationService(session)

    # In-app/push dedupe by (user_id, vacation_period_id). The 7-day catch-up
    # window re-matches the same period on every daily run; the alimtalk side
    # has a vendor idempotency key, but without this marker check the in-app
    # row and push were re-created each day — 7 duplicate pushes per return.
    from app.models.notification import Notification

    student_user_ids = [s.user_id for s in students if s.user_id]
    already_notified: set[str] = set()
    if student_user_ids:
        rows = (
            await session.execute(
                select(Notification.user_id, Notification.data).where(
                    Notification.type == "teacherVacationReturned",
                    Notification.user_id.in_(student_user_ids),
                )
            )
        ).all()
        already_notified = {user_id for user_id, data in rows if (data or {}).get("vacation_period_id") == period.id}
    sent = 0
    for student in students:
        phone = student.parent_phone or student.phone or ""
        if phone:
            log = await service.send_teacher_vacation_returned(
                vacation_period_id=period.id,
                recipient_phone=phone,
                variables={
                    "student_name": student.name or "",
                    "vacation_end": period.end_date.isoformat(),
                    "reason": period.reason or "",
                },
            )
            if log is not None and log.success:
                sent += 1
        # spec §6.3 — in-app companion, deduped above by
        # (user_id, vacation_period_id).
        if student.user_id and student.user_id not in already_notified:
            try:
                await notification_service.create_and_send(
                    user_id=student.user_id,
                    notification_type="teacherVacationReturned",
                    title="선생님 복귀",
                    body=f"{student.name or '학생'} 학생, 선생님이 휴가에서 복귀했어요.",
                    data={"vacation_period_id": period.id},
                    is_push=True,
                    is_in_app=True,
                )
            except Exception:  # noqa: BLE001
                import logging

                logging.getLogger(__name__).exception(
                    "vacation return in-app failed period=%s student=%s", period.id, student.id
                )
    return sent


async def _run(session: AsyncSession | None = None) -> dict[str, Any]:
    """Common runner — accepts an injected session (tests) or opens one (prod)."""

    async def _do(s: AsyncSession) -> dict[str, Any]:
        # KST "yesterday" — vacation_end_date == yesterday means the teacher is back today.
        # 검색 윈도우를 어제 단일 날짜에서 최근 7일 범위로 확장 — cron 이 하루 missed (advisory
        # lock 실패 / 인스턴스 중단 / 배포 윈도우) 되어도 catch-up 가능. alimtalk 멱등 키
        # (vacation_period_id, recipient_phone, template_id) 가 중복 발송을 차단하므로 안전.
        today_kst = datetime.now(UTC).astimezone(_KST).date()
        target = today_kst - timedelta(days=1)
        catch_up_floor = today_kst - timedelta(days=7)

        periods = (
            await s.scalars(
                select(VacationPeriod).where(
                    VacationPeriod.end_date <= target,
                    VacationPeriod.end_date >= catch_up_floor,
                    VacationPeriod.cancelled_at.is_(None),
                )
            )
        ).all()

        total_sent = 0
        for period in periods:
            try:
                total_sent += await _send_returns_for_period(s, period)
            except Exception:  # noqa: BLE001
                logger.exception("vacation return fan-out failed period=%s", period.id)
        await s.commit()
        return {
            "job_id": JOB_ID,
            "target_date": target.isoformat(),
            "periods": len(periods),
            "sent": total_sent,
        }

    if session is not None:
        return await _do(session)

    async with AsyncSessionLocal() as new_session:
        lock_key = advisory_lock_key(JOB_ID)
        acquired = await try_advisory_lock(new_session, key=lock_key)
        if not acquired:
            logger.info("%s: advisory lock not acquired, skip cycle", JOB_ID)
            return {"job_id": JOB_ID, "periods": 0, "sent": 0, "lock_acquired": False}
        try:
            out = await _do(new_session)
        finally:
            # PG advisory lock 누수 차단.
            await release_advisory_lock(new_session, key=lock_key)
        out["lock_acquired"] = True
        return out


async def run_vacation_return_announcement(session: AsyncSession | None = None) -> dict[str, Any]:
    """Public entry — registered as a daily KST 08:05 job."""
    return await _run(session)
