"""Lesson and lesson-class service."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.lesson import (
    LessonClassCreate,
    LessonClassResponse,
    LessonClassUpdate,
    LessonCreate,
    LessonFeedbackUpdate,
    LessonResponse,
    LessonSlotPayload,
    LessonUpdate,
    MembershipCreate,
    MembershipResponse,
    MembershipUpdate,
)
from app.services.teacher_id_resolver import resolve_teacher_id


class LessonService:
    """Handle lesson and lesson-class business logic."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Lessons
    # ------------------------------------------------------------------

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        student_id: str | None = None,
        date: str | None = None,
        date_from: str | None = None,
        date_to: str | None = None,
        status: str | None = None,
    ) -> PaginatedResponse[LessonResponse]:
        """List lessons with filters."""
        from app.models.lesson import Lesson

        tid = await resolve_teacher_id(self.db, user.id)
        query = select(Lesson).where(Lesson.teacher_id == tid, Lesson.is_archived == False)  # noqa: E712
        if student_id:
            query = query.where(Lesson.student_id == student_id)
        if date:
            query = query.where(Lesson.date == date)
        if date_from:
            query = query.where(Lesson.date >= date_from)
        if date_to:
            query = query.where(Lesson.date <= date_to)
        if status:
            query = query.where(Lesson.status == status)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.order_by(Lesson.date.desc()).offset(offset).limit(size))
        items = [LessonResponse.model_validate(lesson) for lesson in result.all()]

        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create(self, data: LessonCreate, current_user: Any) -> LessonResponse:
        """Create a new lesson."""
        from app.models.lesson import Lesson, LessonSource
        from app.models.student import Student
        from app.services.user_service import UserService

        tid = await resolve_teacher_id(self.db, current_user.id)

        student_name = data.student_id
        if data.student_id:
            student = await self.db.get(Student, data.student_id)
            if student:
                if student.teacher_id != tid:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Student access denied",
                    )
                student_name = student.name

        session_number = data.session_number
        if data.subscription_id:
            await self._assert_subscription_matches_lesson(
                subscription_id=data.subscription_id,
                student_id=data.student_id,
            )
            if session_number is None:
                session_number = await self._next_subscription_session_number(data.subscription_id)

        lesson = Lesson(
            teacher_id=tid,
            student_id=data.student_id,
            student_name=student_name,
            instrument=data.instrument or "",
            date=data.date,
            start_time=data.start_time or "00:00",
            duration=data.duration,
            subscription_id=data.subscription_id,
            session_number=session_number,
            location_name=data.location_name,
            lesson_source=LessonSource.manual,
        )
        self.db.add(lesson)
        await self.db.flush()
        await self.db.refresh(lesson)
        await UserService(self.db).complete_onboarding_quest(current_user, "teacher.firstLesson")

        # Notify student about new lesson
        if student and student.user_id:
            from app.services.notification_service import NotificationService, NotificationPriority
            notification_service = NotificationService(self.db)
            await notification_service.create_and_send(
                user_id=student.user_id,
                notification_type="lessonBooked",
                title="새 레슨이 등록되었습니다",
                body=f"{data.date} 레슨이 등록되었습니다",
                priority=NotificationPriority.normal,
                action_url=f"/lessons/{lesson.id}",
                action_label="레슨 확인",
            )

        return LessonResponse.model_validate(lesson)

    async def _assert_subscription_matches_lesson(self, *, subscription_id: str, student_id: str) -> None:
        """Ensure a lesson cannot point at another student's subscription."""
        from app.models.subscription import Subscription

        subscription = await self.db.get(Subscription, subscription_id)
        if subscription is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        if subscription.student_id != student_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="subscription_id does not belong to student_id",
            )

    async def _next_subscription_session_number(self, subscription_id: str) -> int:
        """Return the next stable session number for a subscription-linked lesson."""
        from app.models.lesson import Lesson

        max_session = await self.db.scalar(
            select(func.max(Lesson.session_number)).where(
                Lesson.subscription_id == subscription_id,
                Lesson.session_number.is_not(None),
            )
        )
        if max_session is not None:
            return int(max_session) + 1

        existing_count = await self.db.scalar(
            select(func.count()).where(Lesson.subscription_id == subscription_id)
        )
        return int(existing_count or 0) + 1

    async def get_by_id(self, lesson_id: str, current_user: Any) -> LessonResponse:
        """Return a lesson by ID."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        return LessonResponse.model_validate(lesson)

    async def update(self, lesson_id: str, data: LessonUpdate, current_user: Any) -> LessonResponse:
        """Update a lesson."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)

        update_data = data.model_dump(exclude_unset=True, exclude={"pieces"})
        for key, value in update_data.items():
            setattr(lesson, key, value)
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def delete(self, lesson_id: str, current_user: Any) -> None:
        """Delete a lesson."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        await self.db.delete(lesson)
        await self.db.flush()

    async def update_status(self, lesson_id: str, new_status: str, current_user: Any) -> LessonResponse:
        """Change lesson status."""
        from app.models.lesson import LessonStatus
        from app.models.request_event import RequestEvent, RequestEventType

        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        lesson.status = LessonStatus(new_status)

        # Phase 3 event logging
        role = getattr(getattr(current_user, "role", None), "value", None) or "teacher"
        if new_status == LessonStatus.completed.value:
            self.db.add(
                RequestEvent(
                    request_id=lesson.id,
                    actor_type=role,
                    actor_id=current_user.id,
                    event_type=RequestEventType.lessonCompleted,
                    subscription_id=lesson.subscription_id,
                )
            )
        elif new_status.startswith("cancelled") or new_status in (
            LessonStatus.noShow.value,
            LessonStatus.studentAbsent.value,
        ):
            self.db.add(
                RequestEvent(
                    request_id=lesson.id,
                    actor_type=role,
                    actor_id=current_user.id,
                    event_type=RequestEventType.lessonCancelled,
                    subscription_id=lesson.subscription_id,
                    message=new_status,
                )
            )

        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def archive(self, lesson_id: str, current_user: Any) -> LessonResponse:
        """Archive a lesson from active lesson lists."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        lesson.is_archived = True
        lesson.archived_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def unarchive(self, lesson_id: str, current_user: Any) -> LessonResponse:
        """Restore an archived lesson."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        lesson.is_archived = False
        lesson.archived_at = None
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def update_feedback(
        self, lesson_id: str, data: LessonFeedbackUpdate, current_user: Any
    ) -> LessonResponse:
        """Write or update feedback for a lesson."""
        from app.models.request_event import RequestEvent, RequestEventType
        from app.services.user_service import UserService

        lesson = await self._get_accessible_lesson(lesson_id, current_user)

        if data.feedback is not None:
            lesson.feedback = data.feedback
        if data.practice_tips is not None:
            lesson.practice_tips = data.practice_tips

        await UserService(self.db).complete_onboarding_quest(current_user, "teacher.firstNote")

        # Phase 3 event logging
        self.db.add(
            RequestEvent(
                request_id=lesson.id,
                actor_type="teacher",
                actor_id=current_user.id,
                event_type=RequestEventType.lessonNoteAdded,
                subscription_id=lesson.subscription_id,
            )
        )

        await self.db.flush()
        await self.db.refresh(lesson)

        # Notify student about new feedback
        if lesson.student_id:
            from app.models.student import Student
            from app.services.notification_service import NotificationService, NotificationPriority
            student = await self.db.get(Student, lesson.student_id)
            if student and student.user_id:
                notification_service = NotificationService(self.db)
                await notification_service.create_and_send(
                    user_id=student.user_id,
                    notification_type="lessonNoteShared",
                    title="레슨 피드백이 도착했습니다",
                    body=f"{lesson.date} 레슨의 피드백을 확인하세요",
                    priority=NotificationPriority.normal,
                    action_url=f"/lessons/{lesson.id}",
                    action_label="피드백 확인",
                )

        return LessonResponse.model_validate(lesson)

    async def _get_accessible_lesson(self, lesson_id: str, current_user: Any) -> Any:
        """Load a lesson and enforce the current teacher's ownership boundary."""
        from app.models.lesson import Lesson

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if lesson.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Lesson access denied")
        return lesson

    async def get_upcoming(self, current_user: Any, *, limit: int = 10) -> list[LessonResponse]:
        """Return upcoming lessons."""
        from app.models.lesson import Lesson

        today = date.today()
        result = await self.db.scalars(
            select(Lesson)
            .where(Lesson.teacher_id == await resolve_teacher_id(self.db, current_user.id), Lesson.date >= today)
            .order_by(Lesson.date)
            .limit(limit)
        )
        return [LessonResponse.model_validate(lesson) for lesson in result.all()]

    async def get_recent(self, current_user: Any, *, limit: int = 10) -> list[LessonResponse]:
        """Return recently completed lessons."""
        from app.models.lesson import Lesson

        result = await self.db.scalars(
            select(Lesson)
            .where(
                Lesson.teacher_id == await resolve_teacher_id(self.db, current_user.id),
                Lesson.status == "completed",
            )
            .order_by(Lesson.date.desc())
            .limit(limit)
        )
        return [LessonResponse.model_validate(lesson) for lesson in result.all()]

    # ------------------------------------------------------------------
    # Lesson classes
    # ------------------------------------------------------------------

    async def get_all_classes(
        self, current_user: Any, *, page: int, size: int, offset: int
    ) -> PaginatedResponse[LessonClassResponse]:
        """List lesson classes for the teacher."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        query = select(LessonClass).where(
            LessonClass.teacher_id == tid,
            LessonClass.is_archived == False,  # noqa: E712
        )
        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [LessonClassResponse.model_validate(c) for c in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create_class(self, data: LessonClassCreate, current_user: Any) -> LessonClassResponse:
        """Create a lesson class."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        lesson_class = LessonClass(
            teacher_id=tid,
            name=data.name,
            type=data.type,
            payment_type=data.payment_type,
            contact_person=data.contact_person,
            contact_phone=data.contact_phone,
            address=data.address,
        )
        self.db.add(lesson_class)
        await self.db.flush()
        await self.db.refresh(lesson_class)
        return LessonClassResponse.model_validate(lesson_class)

    async def get_class_by_id(self, class_id: str, current_user: Any) -> LessonClassResponse:
        """Return a lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)
        return LessonClassResponse.model_validate(lc)

    async def update_class(
        self, class_id: str, data: LessonClassUpdate, current_user: Any
    ) -> LessonClassResponse:
        """Update a lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(lc, key, value)
        await self.db.flush()
        await self.db.refresh(lc)
        return LessonClassResponse.model_validate(lc)

    async def delete_class(self, class_id: str, current_user: Any) -> None:
        """Archive a lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)
        lc.is_archived = True
        await self.db.flush()

    async def restore_class(self, class_id: str, current_user: Any) -> LessonClassResponse:
        """Restore an archived lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)
        lc.is_archived = False
        await self.db.flush()
        await self.db.refresh(lc)
        return LessonClassResponse.model_validate(lc)

    async def reorder_classes(self, ordered_ids: list[str], current_user: Any) -> None:
        """Set display order for lesson classes."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        for idx, class_id in enumerate(ordered_ids):
            lc = await self.db.get(LessonClass, class_id)
            if lc and lc.teacher_id == tid:
                lc.sort_order = idx
        await self.db.flush()

    async def _get_accessible_class(self, class_id: str, current_user: Any) -> Any:
        """Load a lesson class and enforce read access for the current user."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        lesson_class = await self.db.get(LessonClass, class_id)
        if lesson_class is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson class not found")

        role = getattr(getattr(current_user, "role", None), "value", None)
        if role == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            if lesson_class.teacher_id == teacher_id:
                return lesson_class
        elif role == "parent":
            parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == current_user.id))
            if parent_id is not None:
                linked_child_class = await self.db.scalar(
                    select(ClassMembership.id)
                    .join(ParentChildRelation, ParentChildRelation.student_id == ClassMembership.student_id)
                    .where(
                        ClassMembership.lesson_class_id == class_id,
                        ParentChildRelation.parent_id == parent_id,
                        ParentChildRelation.status == ParentChildRelationStatus.active,
                    )
                )
                if linked_child_class is not None:
                    return lesson_class
        elif role == "student":
            linked_class = await self.db.scalar(
                select(ClassMembership.id).where(
                    ClassMembership.lesson_class_id == class_id,
                    ClassMembership.student_id == current_user.id,
                )
            )
            if linked_class is not None:
                return lesson_class

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Lesson class access denied")

    # ------------------------------------------------------------------
    # Memberships
    # ------------------------------------------------------------------

    @staticmethod
    def _duration_from_slot(slot: LessonSlotPayload) -> int:
        start = datetime.strptime(slot.start_time, "%H:%M")
        end = datetime.strptime(slot.end_time, "%H:%M")
        if end <= start:
            end += timedelta(days=1)
        return int((end - start).total_seconds() // 60)

    @staticmethod
    def _day_of_week(value: str | None) -> int | None:
        if value is None:
            return None
        if value.isdigit():
            return int(value)
        return {
            "mon": 0,
            "monday": 0,
            "tue": 1,
            "tuesday": 1,
            "wed": 2,
            "wednesday": 2,
            "thu": 3,
            "thursday": 3,
            "fri": 4,
            "friday": 4,
            "sat": 5,
            "saturday": 5,
            "sun": 6,
            "sunday": 6,
        }.get(value.lower())

    @staticmethod
    def _end_time(start_time: str, duration_minutes: int) -> str:
        start = datetime.strptime(start_time, "%H:%M")
        return (start + timedelta(minutes=duration_minutes)).strftime("%H:%M")

    @classmethod
    def _membership_response(cls, membership: Any) -> MembershipResponse:
        response = MembershipResponse.model_validate(membership)
        day_of_week = cls._day_of_week(membership.lesson_day)
        if day_of_week is not None and membership.lesson_time is not None:
            response.lesson_slots = [
                LessonSlotPayload(
                    day_of_week=day_of_week,
                    start_time=membership.lesson_time,
                    end_time=cls._end_time(membership.lesson_time, membership.lesson_duration),
                )
            ]
        return response

    async def get_memberships_by_class(
        self, class_id: str, current_user: Any
    ) -> list[MembershipResponse]:
        """List all memberships in a class."""
        from app.models.lesson import ClassMembership

        await self._get_accessible_class(class_id, current_user)
        result = await self.db.scalars(
            select(ClassMembership).where(ClassMembership.lesson_class_id == class_id)
        )
        return [self._membership_response(m) for m in result.all()]

    async def get_memberships(
        self,
        current_user: Any,
        *,
        student_id: str | None = None,
        class_id: str | None = None,
    ) -> list[MembershipResponse]:
        """List memberships with flat student/class filters."""
        from app.models.lesson import ClassMembership, LessonClass

        role = getattr(getattr(current_user, "role", None), "value", None)
        query = select(ClassMembership)

        if student_id:
            query = query.where(ClassMembership.student_id == student_id)
        if class_id:
            query = query.where(ClassMembership.lesson_class_id == class_id)

        if role == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            query = query.join(LessonClass, LessonClass.id == ClassMembership.lesson_class_id).where(
                LessonClass.teacher_id == teacher_id
            )
        elif role == "student":
            query = query.where(ClassMembership.student_id == current_user.id)
        elif role == "parent":
            from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

            parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == current_user.id))
            if parent_id is None:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
            linked_child_ids = select(ParentChildRelation.student_id).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
            if student_id:
                linked = await self.db.scalar(
                    select(ParentChildRelation.id).where(
                        ParentChildRelation.parent_id == parent_id,
                        ParentChildRelation.student_id == student_id,
                        ParentChildRelation.status == ParentChildRelationStatus.active,
                    )
                )
                if linked is None:
                    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
            query = query.where(ClassMembership.student_id.in_(linked_child_ids))
        else:
            query = query.where(ClassMembership.student_id == current_user.id)

        result = await self.db.scalars(query)
        return [self._membership_response(membership) for membership in result.all()]

    async def get_membership_by_id(self, membership_id: str, current_user: Any) -> MembershipResponse:
        """Return a single membership."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user)
        return self._membership_response(m)

    async def add_membership(
        self, class_id: str, data: MembershipCreate, current_user: Any
    ) -> MembershipResponse:
        """Add a student to a class."""
        from app.models.lesson import ClassMembership

        await self._get_accessible_class(class_id, current_user)
        lesson_day = data.lesson_day
        lesson_time = data.lesson_time
        lesson_duration = data.lesson_duration
        if data.lesson_slots:
            primary_slot = data.lesson_slots[0]
            lesson_day = str(primary_slot.day_of_week)
            lesson_time = primary_slot.start_time
            if "lesson_duration" not in data.model_fields_set:
                lesson_duration = self._duration_from_slot(primary_slot)

        membership = ClassMembership(
            lesson_class_id=class_id,
            student_id=data.student_id,
            instrument=data.instrument or "",
            monthly_fee=data.monthly_fee or 0,
            lessons_per_week=data.lessons_per_week or 1,
            lesson_day=lesson_day,
            lesson_time=lesson_time,
            lesson_duration=lesson_duration,
            lesson_location_id=data.lesson_location_id,
            travel_time_minutes=data.travel_time_minutes,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(membership)
        return self._membership_response(membership)

    async def update_membership(
        self, class_id: str, membership_id: str, data: MembershipUpdate, current_user: Any
    ) -> MembershipResponse:
        """Update a class membership."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user)

        update_data = data.model_dump(exclude_unset=True, exclude={"lesson_slots"})
        if data.lesson_slots:
            primary_slot = data.lesson_slots[0]
            update_data["lesson_day"] = str(primary_slot.day_of_week)
            update_data["lesson_time"] = primary_slot.start_time
            if "lesson_duration" not in data.model_fields_set:
                update_data["lesson_duration"] = self._duration_from_slot(primary_slot)
        for key, value in update_data.items():
            setattr(m, key, value)
        await self.db.flush()
        await self.db.refresh(m)
        return self._membership_response(m)

    async def remove_membership(self, class_id: str, membership_id: str, current_user: Any) -> None:
        """Remove a membership from a class."""
        await self.remove_membership_by_id(membership_id, current_user)

    async def update_membership_status(
        self,
        membership_id: str,
        new_status: str,
        current_user: Any,
    ) -> MembershipResponse:
        """Update only membership status."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user, require_teacher=True)
        m.status = ClassMembership.MembershipStatus(new_status)
        await self.db.flush()
        await self.db.refresh(m)
        return self._membership_response(m)

    async def remove_membership_by_id(self, membership_id: str, current_user: Any) -> None:
        """Remove a membership without requiring class_id context."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user, require_teacher=True)
        await self.db.delete(m)
        await self.db.flush()

    async def _assert_membership_access(
        self,
        membership: Any,
        current_user: Any,
        *,
        require_teacher: bool = False,
    ) -> None:
        from app.models.lesson import LessonClass

        role = getattr(getattr(current_user, "role", None), "value", None)
        if role == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            class_teacher_id = await self.db.scalar(
                select(LessonClass.teacher_id).where(LessonClass.id == membership.lesson_class_id)
            )
            if class_teacher_id == teacher_id:
                return
        elif not require_teacher and role == "student" and membership.student_id == current_user.id:
            return

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to access membership")
