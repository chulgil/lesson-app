"""Bulk teacher action orchestration."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import LessonStatus
from app.models.notification import NotificationPriority
from app.models.request_event import RequestEventType
from app.models.subscription import SubscriptionStatus, SubscriptionType
from app.schemas.lesson import BulkCancelLessonResponse, BulkLessonEventCreated
from app.schemas.notification import BroadcastNotificationResponse
from app.services.notification_service import NotificationService
from app.services.teacher_id_resolver import resolve_teacher_id

ACTIVE_SUBSCRIPTION_STATUSES = {
    SubscriptionStatus.active,
    SubscriptionStatus.expiringSoon,
}


class BulkTeacherActionService:
    """Handle teacher bulk cancel and broadcast actions."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def bulk_cancel_lessons(
        self,
        *,
        teacher_id: str,
        student_ids: list[str],
        target_date: Any,
        reason: str | None,
        notification_title: str,
        current_user: Any,
    ) -> BulkCancelLessonResponse:
        """Cancel matching lessons and create subscription chat events."""
        return await self._bulk_cancel_lessons(
            teacher_id=teacher_id,
            student_ids=student_ids,
            target_date=target_date,
            reason=reason,
            notification_title=notification_title,
            current_user=current_user,
            preview=False,
        )

    async def preview_bulk_cancel_lessons(
        self,
        *,
        teacher_id: str,
        student_ids: list[str],
        target_date: Any,
        reason: str | None,
        notification_title: str,
        current_user: Any,
    ) -> BulkCancelLessonResponse:
        """Preview matching lesson cancellations without side effects."""
        return await self._bulk_cancel_lessons(
            teacher_id=teacher_id,
            student_ids=student_ids,
            target_date=target_date,
            reason=reason,
            notification_title=notification_title,
            current_user=current_user,
            preview=True,
        )

    async def _bulk_cancel_lessons(
        self,
        *,
        teacher_id: str,
        student_ids: list[str],
        target_date: Any,
        reason: str | None,
        notification_title: str,
        current_user: Any,
        preview: bool,
    ) -> BulkCancelLessonResponse:
        from app.models.lesson import Lesson
        from app.models.request_event import RequestEvent

        resolved_teacher_id = await self._authorize_teacher(teacher_id, current_user)
        students = await self._students_by_id(resolved_teacher_id, student_ids)
        subscriptions = await self._active_subscriptions_by_student(resolved_teacher_id, student_ids)

        result = await self.db.scalars(
            select(Lesson).where(
                Lesson.teacher_id == resolved_teacher_id,
                Lesson.student_id.in_(student_ids),
                Lesson.date == target_date,
                Lesson.status.in_([LessonStatus.scheduled, LessonStatus.reschedulePending]),
            )
        )
        lessons = result.all()
        lessons_by_student: dict[str, list[Any]] = {}
        for lesson in lessons:
            lessons_by_student.setdefault(lesson.student_id, []).append(lesson)

        events_created: list[BulkLessonEventCreated] = []
        notified_students: set[str] = set()
        skipped_student_ids: list[str] = []
        notification_service = NotificationService(self.db)

        for student_id in student_ids:
            student = students.get(student_id)
            subscription = subscriptions.get(student_id)
            student_lessons = lessons_by_student.get(student_id, [])
            if student is None or subscription is None or not student_lessons:
                skipped_student_ids.append(student_id)
                continue

            for lesson in student_lessons:
                session_number = await self._session_number_for_lesson(lesson)
                if not preview:
                    lesson.status = LessonStatus.cancelledByTeacher
                    event = RequestEvent(
                        request_id=subscription.id,
                        actor_type="teacher",
                        actor_id=current_user.id,
                        event_type=RequestEventType.lesson_cancelled_by_teacher,
                        subscription_id=subscription.id,
                        session_number=session_number,
                        message=reason,
                        change_credit_used=0,
                        change_credit_remaining_after=(
                            subscription.total_reschedule_allowance - subscription.used_reschedule_count
                        ),
                        keeps_session_number=True,
                    )
                    self.db.add(event)
                    body = self._bulk_cancel_body(lesson, reason, session_number)
                    await notification_service.create_and_send(
                        user_id=student.user_id or student.id,
                        notification_type="lessonCancelled",
                        title=notification_title,
                        body=body,
                        priority=NotificationPriority.high,
                        data={
                            "teacherId": resolved_teacher_id,
                            "lessonId": lesson.id,
                            "subscriptionId": subscription.id,
                            "sessionNumber": session_number,
                            "source": "bulk_teacher_action",
                            "actionUrl": f"/subscriptions/{subscription.id}",
                            "actionLabel": "보강 요청",
                        },
                        action_url=f"/subscriptions/{subscription.id}",
                        action_label="보강 요청",
                    )
                events_created.append(
                    BulkLessonEventCreated(
                        student_id=student_id,
                        lesson_id=lesson.id,
                        session_number=session_number,
                        subscription_id=subscription.id,
                    )
                )
                notified_students.add(student_id)

        await self.db.flush()
        return BulkCancelLessonResponse(
            cancelled_lesson_count=len(events_created),
            notified_student_count=len(notified_students),
            skipped_student_ids=skipped_student_ids,
            events_created=events_created,
        )

    async def broadcast(
        self,
        *,
        teacher_id: str,
        student_ids: list[str],
        target_filter: str,
        title: str,
        body: str,
        current_user: Any,
    ) -> BroadcastNotificationResponse:
        """Send a teacher broadcast and create chat events for active subscriptions."""
        from app.models.request_event import RequestEvent

        resolved_teacher_id = await self._authorize_teacher(teacher_id, current_user)
        students = await self._students_by_id(resolved_teacher_id, student_ids)
        subscriptions = await self._active_subscriptions_by_student(resolved_teacher_id, student_ids)
        notification_service = NotificationService(self.db)

        sent_count = 0
        event_created_count = 0
        filtered_out_count = 0

        for student_id in student_ids:
            student = students.get(student_id)
            subscription = subscriptions.get(student_id)
            if student is None:
                filtered_out_count += 1
                continue
            if target_filter == "active_subscription" and subscription is None:
                filtered_out_count += 1
                continue

            if subscription is not None:
                self.db.add(
                    RequestEvent(
                        request_id=subscription.id,
                        actor_type="teacher",
                        actor_id=current_user.id,
                        event_type=RequestEventType.teacher_announcement,
                        subscription_id=subscription.id,
                        message=f"{title}\n{body}",
                    )
                )
                event_created_count += 1

            await notification_service.create_and_send(
                user_id=student.user_id or student.id,
                notification_type="generalAnnouncement",
                title=title,
                body=body,
                priority=NotificationPriority.normal,
                data={
                    "teacherId": resolved_teacher_id,
                    "subscriptionId": subscription.id if subscription is not None else None,
                    "source": "bulk_teacher_action",
                },
            )
            sent_count += 1

        await self.db.flush()
        return BroadcastNotificationResponse(
            sent_count=sent_count,
            event_created_count=event_created_count,
            filtered_out_count=filtered_out_count,
        )

    async def _authorize_teacher(self, teacher_id: str, current_user: Any) -> str:
        resolved_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if teacher_id not in {current_user.id, resolved_teacher_id}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access denied")
        return resolved_teacher_id

    async def _students_by_id(self, teacher_id: str, student_ids: list[str]) -> dict[str, Any]:
        from app.models.student import Student

        result = await self.db.scalars(
            select(Student).where(
                Student.teacher_id == teacher_id,
                Student.id.in_(student_ids),
                Student.is_active.is_(True),
            )
        )
        return {student.id: student for student in result.all()}

    async def _active_subscriptions_by_student(self, teacher_id: str, student_ids: list[str]) -> dict[str, Any]:
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        result = await self.db.scalars(
            select(Subscription)
            .join(ClassMembership, Subscription.membership_id == ClassMembership.id)
            .join(LessonClass, ClassMembership.lesson_class_id == LessonClass.id)
            .where(
                LessonClass.teacher_id == teacher_id,
                Subscription.student_id.in_(student_ids),
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
        subscriptions_by_student: dict[str, Any] = {}
        for subscription in result.all():
            subscriptions_by_student.setdefault(subscription.student_id, subscription)
        return subscriptions_by_student

    async def _session_number_for_lesson(self, lesson: Any) -> int | None:
        from app.models.lesson import Lesson

        if lesson.subscription_id is None:
            return None

        result = await self.db.scalars(
            select(Lesson)
            .where(Lesson.subscription_id == lesson.subscription_id)
            .order_by(Lesson.date.asc(), Lesson.start_time.asc(), Lesson.id.asc())
        )
        for index, subscription_lesson in enumerate(result.all(), start=1):
            if subscription_lesson.id == lesson.id:
                return index
        return None

    def _bulk_cancel_body(self, lesson: Any, reason: str | None, session_number: int | None) -> str:
        session_text = f"{session_number}회차 " if session_number is not None else ""
        body = f"{session_text}{lesson.date.isoformat()} {lesson.start_time} 레슨이 휴강 처리되었습니다."
        if reason:
            body = f"{body}\n사유: {reason}"
        return body
