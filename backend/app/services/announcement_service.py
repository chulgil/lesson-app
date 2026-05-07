"""Teacher announcement service."""

from __future__ import annotations

from datetime import date
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import NotificationPriority
from app.models.subscription import SubscriptionStatus, SubscriptionType
from app.schemas.teacher_announcement import (
    AffectedLesson,
    TeacherAnnouncementCreate,
    TeacherAnnouncementDayOffsResponse,
    TeacherAnnouncementResponse,
)
from app.services.notification_service import NotificationService
from app.services.teacher_id_resolver import resolve_teacher_id

ACTIVE_SUBSCRIPTION_STATUSES = {SubscriptionStatus.active, SubscriptionStatus.expiringSoon}


class AnnouncementService:
    """Handle teacher announcement creation and querying."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_announcement(
        self,
        body: TeacherAnnouncementCreate,
        current_user: Any,
    ) -> TeacherAnnouncementResponse:
        """Create announcement and notify active students."""
        from app.models.teacher_announcement import (
            TeacherAnnouncement,
            TeacherAnnouncementDate,
            TeacherAnnouncementType,
        )

        teacher_id = await self._authorize_teacher(body.teacher_id, current_user)
        normalized_dates = self._normalize_dates(body.dates)

        announcement = TeacherAnnouncement(
            teacher_id=teacher_id,
            type=(TeacherAnnouncementType.day_off if body.type == "dayOff" else TeacherAnnouncementType.general),
            message=body.message,
        )
        self.db.add(announcement)
        await self.db.flush()

        if body.type == "dayOff":
            for announcement_date in normalized_dates:
                self.db.add(
                    TeacherAnnouncementDate(
                        teacher_announcement_id=announcement.id,
                        announcement_date=announcement_date,
                    )
                )

        active_students = await self._active_students_with_active_subscription(teacher_id)

        affected_lessons = []
        if body.type == "dayOff":
            affected_lessons = await self._collect_affected_lessons(
                teacher_id=teacher_id,
                dates=normalized_dates,
                target_students=set(active_students),
            )

        notified_count = await self._notify_active_students(
            announcement_type=body.type,
            message=body.message,
            teacher_id=teacher_id,
            students=active_students,
            announcement_id=announcement.id,
        )
        announcement.notified_count = notified_count

        await self.db.flush()
        await self.db.refresh(announcement)

        return TeacherAnnouncementResponse(
            id=announcement.id,
            teacher_id=announcement.teacher_id,
            type=body.type,
            dates=normalized_dates,
            message=announcement.message,
            created_at=announcement.created_at,
            notified_count=announcement.notified_count,
            affected_lessons=affected_lessons,
        )

    async def list_announcements(
        self,
        *,
        teacher_id: str | None,
        current_user: Any,
    ) -> list[TeacherAnnouncementResponse]:
        """List announcements for a teacher, newest first."""
        from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementType

        resolved_teacher_id = await self._authorize_teacher(teacher_id, current_user)
        rows = await self.db.scalars(
            select(TeacherAnnouncement)
            .where(TeacherAnnouncement.teacher_id == resolved_teacher_id)
            .order_by(TeacherAnnouncement.created_at.desc())
        )

        results: list[TeacherAnnouncementResponse] = []
        for announcement in rows.all():
            dates: list[date] = []
            affected_lessons: list[AffectedLesson] = []
            if announcement.type == TeacherAnnouncementType.day_off:
                dates = await self._announcement_dates(announcement.id)
                affected_lessons = await self._collect_affected_lessons(
                    teacher_id=resolved_teacher_id,
                    dates=dates,
                    target_students=None,
                )

            results.append(
                TeacherAnnouncementResponse(
                    id=announcement.id,
                    teacher_id=announcement.teacher_id,
                    type="dayOff" if announcement.type == TeacherAnnouncementType.day_off else "general",
                    dates=dates,
                    message=announcement.message,
                    created_at=announcement.created_at,
                    notified_count=announcement.notified_count,
                    affected_lessons=affected_lessons,
                )
            )
        return results

    async def list_day_offs(
        self,
        *,
        teacher_id: str | None,
        from_date: date,
        to_date: date,
        current_user: Any,
    ) -> TeacherAnnouncementDayOffsResponse:
        """Return day-off dates in range for a teacher."""
        from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementDate

        if from_date > to_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="from_date cannot be after to_date",
            )

        resolved_teacher_id = await self._authorize_teacher(teacher_id, current_user)
        rows = await self.db.scalars(
            select(TeacherAnnouncementDate.announcement_date)
            .join(
                TeacherAnnouncement,
                TeacherAnnouncement.id == TeacherAnnouncementDate.teacher_announcement_id,
            )
            .where(
                TeacherAnnouncement.teacher_id == resolved_teacher_id,
                TeacherAnnouncementDate.announcement_date >= from_date,
                TeacherAnnouncementDate.announcement_date <= to_date,
            )
            .order_by(TeacherAnnouncementDate.announcement_date.asc())
            .distinct()
        )
        return TeacherAnnouncementDayOffsResponse(dates=list(rows))

    async def _notify_active_students(
        self,
        *,
        announcement_type: str,
        message: str,
        teacher_id: str,
        students: dict[str, str | None],
        announcement_id: str,
    ) -> int:
        """Notify students with active subscription and return notified count."""
        service = NotificationService(self.db)

        title = "휴강 안내" if announcement_type == "dayOff" else "선생님 공지"
        priority = NotificationPriority.high if announcement_type == "dayOff" else NotificationPriority.normal

        notified = 0
        for student_id, user_id in students.items():
            if user_id is None:
                continue

            await service.create_and_send(
                user_id=user_id,
                notification_type="generalAnnouncement",
                title=title,
                body=message,
                priority=priority,
                data={
                    "teacherId": teacher_id,
                    "announcementId": announcement_id,
                    "type": announcement_type,
                    "source": "teacher_announcement",
                    "studentId": student_id,
                },
            )
            notified += 1
        return notified

    async def _active_students_with_active_subscription(
        self,
        teacher_id: str,
    ) -> dict[str, str | None]:
        """Return mapping student_id → user_id for active subscriptions."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.student import Student
        from app.models.subscription import Subscription

        rows = await self.db.execute(
            select(Subscription.student_id, Student.user_id)
            .join(ClassMembership, Subscription.membership_id == ClassMembership.id)
            .join(LessonClass, ClassMembership.lesson_class_id == LessonClass.id)
            .join(Student, Student.id == Subscription.student_id)
            .where(
                LessonClass.teacher_id == teacher_id,
                Student.is_active.is_(True),
                or_(
                    Subscription.status.in_(ACTIVE_SUBSCRIPTION_STATUSES),
                    and_(
                        Subscription.type == SubscriptionType.trial,
                        Subscription.status.in_(ACTIVE_SUBSCRIPTION_STATUSES),
                    ),
                ),
            )
            .order_by(Subscription.created_at.desc(), Subscription.id.desc())
        )

        students: dict[str, str | None] = {}
        for student_id, user_id in rows.all():
            students.setdefault(student_id, user_id)
        return students

    async def _collect_affected_lessons(
        self,
        *,
        teacher_id: str,
        dates: list[date],
        target_students: set[str] | None,
    ) -> list[AffectedLesson]:
        """Collect lessons impacted by 휴강 date set."""
        from app.models.lesson import Lesson, LessonStatus

        if not dates:
            return []

        lessons_query = (
            select(Lesson)
            .where(
                Lesson.teacher_id == teacher_id,
                Lesson.date.in_(dates),
                Lesson.status.in_([LessonStatus.scheduled, LessonStatus.reschedulePending]),
            )
            .order_by(Lesson.date.asc(), Lesson.start_time.asc(), Lesson.id.asc())
        )
        if target_students is not None:
            lessons_query = lessons_query.where(Lesson.student_id.in_(target_students))

        lessons = (await self.db.scalars(lessons_query)).all()
        if not lessons:
            return []

        lessons_with_subscription = [lesson for lesson in lessons if lesson.subscription_id is not None]
        session_map = await self._session_number_by_lesson_id(lessons_with_subscription)

        return [
            AffectedLesson(
                student_id=lesson.student_id,
                student_name=lesson.student_name,
                instrument=lesson.instrument,
                start_time=lesson.start_time,
                session_number=session_map.get(lesson.id),
                subscription_id=lesson.subscription_id,
            )
            for lesson in sorted(lessons, key=lambda row: (row.date, row.start_time, row.id))
        ]

    async def _session_number_by_lesson_id(
        self,
        lessons_with_subscription: list[Any],
    ) -> dict[str, int]:
        """Map lesson_id → session number within the subscription."""
        from app.models.lesson import Lesson

        if not lessons_with_subscription:
            return {}

        subscription_ids = sorted(
            {lesson.subscription_id for lesson in lessons_with_subscription if lesson.subscription_id is not None}
        )
        if not subscription_ids:
            return {}

        all_lessons = await self.db.scalars(
            select(Lesson)
            .where(Lesson.subscription_id.in_(subscription_ids))
            .order_by(Lesson.date.asc(), Lesson.start_time.asc(), Lesson.id.asc())
        )

        counters: dict[str, int] = {}
        lesson_to_session: dict[str, int] = {}
        for lesson in all_lessons:
            if lesson.subscription_id is None:
                continue
            position = counters.get(lesson.subscription_id, 0) + 1
            counters[lesson.subscription_id] = position
            lesson_to_session[lesson.id] = position

        return lesson_to_session

    async def _announcement_dates(self, announcement_id: str) -> list[date]:
        """Collect dates for a day-off announcement."""
        from app.models.teacher_announcement import TeacherAnnouncementDate

        rows = await self.db.scalars(
            select(TeacherAnnouncementDate.announcement_date)
            .where(TeacherAnnouncementDate.teacher_announcement_id == announcement_id)
            .order_by(TeacherAnnouncementDate.announcement_date.asc())
        )
        return list(rows)

    async def _authorize_teacher(self, teacher_id: str | None, current_user: Any) -> str:
        resolved_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if teacher_id is None:
            return resolved_teacher_id
        if teacher_id not in {current_user.id, resolved_teacher_id}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access denied")
        return resolved_teacher_id

    def _normalize_dates(self, dates: list[date]) -> list[date]:
        """Normalize/sort/unique dates."""
        return sorted(set(dates))
