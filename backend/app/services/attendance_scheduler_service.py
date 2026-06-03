"""Attendance automation service — Phase 3.

Handles:
1. Unconfirmed attendance notifications (30 min after lesson end)
2. 24-hour auto-complete for unconfirmed lessons
3. Consecutive absence pattern detection
"""

from __future__ import annotations

import logging
from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import Lesson, LessonStatus
from app.models.notification import NotificationPriority
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)

# #469: lesson date + "HH:MM" start_time are stored in KST wall-clock terms.
# Compute the lesson end instant in KST and compare against KST-now so the
# 30-min / 24-hour thresholds respect the actual start_time (the previous
# ``Lesson.date < threshold.date()`` ignored start_time and the UTC/KST offset).
_KST = ZoneInfo("Asia/Seoul")

# Statuses indicating unconfirmed lesson
_UNCONFIRMED_STATUS = LessonStatus.scheduled


def _lesson_end_kst(lesson: Lesson) -> datetime | None:
    """Return the lesson end as a KST-aware datetime, or None if unparseable.

    end = date + start_time("HH:MM") + duration(minutes), interpreted in KST.
    """
    if lesson.start_time is None:
        return None
    try:
        hh, mm = (int(part) for part in lesson.start_time.split(":"))
        start = datetime.combine(lesson.date, time(hour=hh, minute=mm), tzinfo=_KST)
    except (ValueError, TypeError):
        return None
    return start + timedelta(minutes=lesson.duration or 0)


# Statuses indicating absence
_ABSENCE_STATUSES = {
    LessonStatus.studentAbsent,
    LessonStatus.noShow,
    LessonStatus.cancelledByStudentLate,
}


class AttendanceSchedulerService:
    """Automated attendance processing tasks."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def notify_unconfirmed_lessons(self) -> int:
        """Send pre-notice for lessons that ended 30+ minutes ago but not confirmed.

        #469: warns the teacher that the lesson will auto-complete and deduct one
        session in ~24h if not confirmed (사전 안내). Returns notifications sent.
        """
        now_kst = datetime.now(_KST)
        notify_cutoff = now_kst - timedelta(minutes=30)

        # Coarse DB pre-filter on date (bounds the scan); exact end-time check in
        # Python via _lesson_end_kst. The KST date can be one day ahead of UTC,
        # so include today_kst.
        lessons = await self._scheduled_lessons_on_or_before(now_kst.date())
        if not lessons:
            return 0

        notification_service = NotificationService(self.db)
        count = 0

        for lesson in lessons:
            end_kst = _lesson_end_kst(lesson)
            if end_kst is None or end_kst > notify_cutoff:
                continue
            try:
                if not lesson.teacher_id:
                    continue
                await notification_service.create_and_send(
                    user_id=lesson.teacher_id,
                    notification_type="attendanceUnconfirmed",
                    title="출석 미확인",
                    body="레슨 출석이 아직 확인되지 않았습니다. 24시간 내 미확인 시 자동 완료되며 수강권 1회가 차감됩니다.",
                    priority=NotificationPriority.normal,
                    data={"lessonId": lesson.id},
                    action_url=f"/lessons/{lesson.id}",
                    action_label="확인하기",
                )
                count += 1
            except Exception:
                logger.exception("Failed to send unconfirmed notification for lesson %s", lesson.id)

        return count

    async def _scheduled_lessons_on_or_before(self, max_date) -> list[Lesson]:
        """Return scheduled lessons whose date <= max_date (coarse DB pre-filter)."""
        result = await self.db.scalars(
            select(Lesson)
            .where(
                and_(
                    Lesson.status == _UNCONFIRMED_STATUS,
                    Lesson.date <= max_date,
                )
            )
            .limit(100)
        )
        return list(result.all())

    async def auto_complete_expired_lessons(self) -> int:
        """Auto-complete lessons that have been unconfirmed for 24+ hours.

        #469: sets status to 'completed' and, when the lesson is linked to a
        subscription, deducts one session via the idempotent
        ``deduct_for_completed_lesson`` (product-approved 2026-06-03). A result
        alarm is sent to the teacher. Returns the number of auto-completed lessons.
        """
        from app.services.subscription_service import SubscriptionService

        now_kst = datetime.now(_KST)
        complete_cutoff = now_kst - timedelta(hours=24)

        lessons = await self._scheduled_lessons_on_or_before(now_kst.date())
        if not lessons:
            return 0

        notification_service = NotificationService(self.db)
        subscription_service = SubscriptionService(self.db)
        count = 0

        for lesson in lessons:
            end_kst = _lesson_end_kst(lesson)
            if end_kst is None or end_kst > complete_cutoff:
                continue
            try:
                lesson.status = LessonStatus.completed
                await self.db.flush()

                # #469: deduct one subscription session for the auto-completed
                # lesson (idempotent — safe on scheduler re-run).
                deducted = False
                if lesson.subscription_id:
                    deducted = await subscription_service.deduct_for_completed_lesson(
                        lesson.id, lesson.subscription_id
                    )

                if not lesson.teacher_id:
                    continue
                body = (
                    "24시간 미확인 레슨이 자동 완료 처리되어 수강권 1회가 차감되었습니다."
                    if deducted
                    else "24시간 미확인 레슨이 자동 완료 처리되었습니다."
                )
                await notification_service.create_and_send(
                    user_id=lesson.teacher_id,
                    notification_type="lessonAutoCompleted",
                    title="레슨 자동 완료",
                    body=body,
                    priority=NotificationPriority.low,
                    data={"lessonId": lesson.id, "deducted": deducted},
                    action_url=f"/lessons/{lesson.id}",
                )
                count += 1
            except Exception:
                logger.exception("Failed to auto-complete lesson %s", lesson.id)

        logger.info("Auto-completed %d lessons", count)
        return count

    async def detect_absence_patterns(self) -> int:
        """Detect students with consecutive absences and alert their teachers.

        Triggers when a student has 2+ absences within the last 14 days.
        Returns the number of alerts sent.
        """
        now = datetime.now(timezone.utc)
        cutoff = now - timedelta(days=14)

        # Find students with 2+ absences in last 14 days, grouped by teacher
        absence_statuses = [s.value for s in _ABSENCE_STATUSES]

        query = (
            select(
                Lesson.teacher_id,
                Lesson.student_id,
                func.count(Lesson.id).label("absence_count"),
            )
            .where(
                and_(
                    Lesson.status.in_(absence_statuses),
                    Lesson.date >= cutoff.date(),
                )
            )
            .group_by(Lesson.teacher_id, Lesson.student_id)
            .having(func.count(Lesson.id) >= 2)
        )

        result = await self.db.execute(query)
        rows = result.all()

        if not rows:
            return 0

        notification_service = NotificationService(self.db)
        count = 0

        for row in rows:
            teacher_id, student_id, absence_count = row
            try:
                await notification_service.create_and_send(
                    user_id=teacher_id,
                    notification_type="absencePatternDetected",
                    title="결석 패턴 감지",
                    body=f"학생이 최근 14일간 {absence_count}회 결석했습니다. 확인이 필요합니다.",
                    priority=NotificationPriority.high,
                    data={
                        "studentId": student_id,
                        "absenceCount": absence_count,
                        "periodDays": 14,
                    },
                    action_url=f"/students/{student_id}",
                    action_label="학생 확인",
                )
                count += 1
            except Exception:
                logger.exception(
                    "Failed to send absence alert for teacher=%s student=%s",
                    teacher_id,
                    student_id,
                )

        logger.info("Sent %d absence pattern alerts", count)
        return count
