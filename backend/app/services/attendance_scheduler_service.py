"""Attendance automation service — Phase 3.

Handles:
1. Unconfirmed attendance notifications (30 min after lesson end)
2. 24-hour auto-complete for unconfirmed lessons
3. Consecutive absence pattern detection
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import Lesson, LessonStatus
from app.models.notification import NotificationPriority
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)

# Statuses indicating unconfirmed lesson
_UNCONFIRMED_STATUS = LessonStatus.scheduled

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
        """Send notification for lessons that ended 30+ minutes ago but not confirmed.

        Returns the number of notifications sent.
        """
        now = datetime.now(timezone.utc)
        threshold = now - timedelta(minutes=30)

        # Find lessons where scheduled time is before threshold and still scheduled
        result = await self.db.scalars(
            select(Lesson).where(
                and_(
                    Lesson.status == _UNCONFIRMED_STATUS,
                    Lesson.date < threshold.date(),
                )
            ).limit(100)
        )
        lessons = list(result.all())

        if not lessons:
            return 0

        notification_service = NotificationService(self.db)
        count = 0

        for lesson in lessons:
            try:
                if not lesson.teacher_id:
                    continue
                await notification_service.create_and_send(
                    user_id=lesson.teacher_id,
                    notification_type="attendanceUnconfirmed",
                    title="출석 미확인",
                    body="레슨 출석이 아직 확인되지 않았습니다",
                    priority=NotificationPriority.normal,
                    data={"lessonId": lesson.id},
                    action_url=f"/lessons/{lesson.id}",
                    action_label="확인하기",
                )
                count += 1
            except Exception:
                logger.exception("Failed to send unconfirmed notification for lesson %s", lesson.id)

        return count

    async def auto_complete_expired_lessons(self) -> int:
        """Auto-complete lessons that have been unconfirmed for 24+ hours.

        Sets status to 'completed' and triggers subscription deduction.
        Returns the number of auto-completed lessons.
        """
        now = datetime.now(timezone.utc)
        threshold = now - timedelta(hours=24)

        result = await self.db.scalars(
            select(Lesson).where(
                and_(
                    Lesson.status == _UNCONFIRMED_STATUS,
                    Lesson.date < threshold.date(),
                )
            ).limit(100)
        )
        lessons = list(result.all())

        if not lessons:
            return 0

        notification_service = NotificationService(self.db)
        count = 0

        for lesson in lessons:
            try:
                lesson.status = LessonStatus.completed
                await self.db.flush()

                if not lesson.teacher_id:
                    continue
                # Notify teacher about auto-completion
                await notification_service.create_and_send(
                    user_id=lesson.teacher_id,
                    notification_type="lessonAutoCompleted",
                    title="레슨 자동 완료",
                    body="24시간 미확인 레슨이 자동 완료 처리되었습니다",
                    priority=NotificationPriority.low,
                    data={"lessonId": lesson.id},
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
