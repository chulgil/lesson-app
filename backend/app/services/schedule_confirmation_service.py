"""Schedule confirmation card service."""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.schedule_confirmation import (
    ScheduleConfirmationCardConfirm,
    ScheduleConfirmationCardCreate,
    ScheduleConfirmationCardDismissAll,
    ScheduleConfirmationCardDismissAllResponse,
    ScheduleConfirmationCardResponse,
    ScheduleConfirmationCardStatusUpdate,
)
from app.services.actor import actor_type

logger = logging.getLogger(__name__)


class ScheduleConfirmationService:
    """Handle schedule confirmation card lifecycle."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_card(
        self, data: ScheduleConfirmationCardCreate, current_user: Any
    ) -> ScheduleConfirmationCardResponse:
        """Teacher creates a schedule confirmation card for a student."""
        from app.models.policy import ScheduleConfirmationCard

        # Validate proposed time doesn't conflict with existing bookings
        if data.proposed_day is not None and data.proposed_time is not None:
            import datetime as dt
            from datetime import timedelta

            base_date = dt.date.today()
            proposed_day = int(data.proposed_day)
            days_ahead = proposed_day - base_date.weekday()
            if days_ahead <= 0:
                days_ahead += 7
            next_date = base_date + timedelta(days=days_ahead)

            conflict = await self._check_time_conflict(
                teacher_id=current_user.id,
                scheduled_date=next_date,
                scheduled_time=data.proposed_time,
                duration=data.proposed_duration or 60,
            )
            if conflict:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="해당 시간에 이미 예약이 있습니다",
                )

        teacher_id = await self._resolve_teacher_id_for_actor(current_user.id)

        card = ScheduleConfirmationCard(
            student_id=data.student_id,
            teacher_id=teacher_id,
            subscription_id=data.subscription_id,
            lesson_request_id=data.lesson_request_id,
            card_type=data.card_type,
            instrument=data.instrument,
            title=data.title,
            message=data.message,
            proposed_day=data.proposed_day,
            proposed_time=data.proposed_time,
            proposed_duration=data.proposed_duration,
            proposed_slots=data.proposed_slots,
            total_lessons=data.total_lessons,
            expires_at=data.expires_at,
        )
        self.db.add(card)
        await self.db.flush()
        await self.db.refresh(card)

        # Notify student about new schedule confirmation card
        from app.models.student import Student

        _student = await self.db.get(Student, card.student_id)
        if _student and _student.user_id:
            from app.models.notification import NotificationPriority
            from app.services.notification_service import NotificationService

            _notification_service = NotificationService(self.db)
            _response = await self._response_for_card(card)
            _teacher_name = _response.teacher_name or "선생님"
            await _notification_service.create_and_send(
                user_id=_student.user_id,
                notification_type="scheduleConfirmationRequired",
                title="레슨 일정을 확인해주세요",
                body=f"{_teacher_name}이 레슨 일정을 제안했습니다",
                priority=NotificationPriority.high,
                action_url=f"/schedule/confirmation-cards/{card.id}",
                action_label="일정 확인",
            )

        return await self._response_for_card(card)

    async def get_cards(
        self,
        current_user: Any,
        *,
        student_id: str | None = None,
        card_status: str | None = None,
    ) -> list[ScheduleConfirmationCardResponse]:
        """List confirmation cards accessible to the current user."""
        from app.models.policy import ScheduleConfirmationCard

        query = select(ScheduleConfirmationCard)
        query = await self._apply_access_filter(query, current_user)

        if student_id:
            query = query.where(ScheduleConfirmationCard.student_id == student_id)
        if card_status:
            query = query.where(ScheduleConfirmationCard.status == card_status)

        query = query.order_by(ScheduleConfirmationCard.created_at.desc())
        result = await self.db.scalars(query)
        return [await self._response_for_card(card) for card in result.all()]

    async def get_card_by_id(self, card_id: str, current_user: Any) -> ScheduleConfirmationCardResponse:
        """Return a single confirmation card by ID."""
        card = await self._get_card_for_user(card_id, current_user)
        return await self._response_for_card(card)

    async def get_card_by_subscription_id(
        self, subscription_id: str, current_user: Any
    ) -> ScheduleConfirmationCardResponse:
        """Return a confirmation card by subscription ID."""
        from app.models.policy import ScheduleConfirmationCard

        card = await self.db.scalar(
            select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == subscription_id)
        )
        if card is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Schedule confirmation card not found",
            )
        if not await self._can_access(card, current_user):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Forbidden",
            )
        return await self._response_for_card(card)

    async def confirm_card(
        self,
        card_id: str,
        data: ScheduleConfirmationCardConfirm,
        current_user: Any,
    ) -> ScheduleConfirmationCardResponse:
        """Student confirms or rejects a schedule confirmation card."""
        from app.models.policy import ConfirmationCardStatus

        card = await self._get_card_for_user(card_id, current_user)

        if card.status != ConfirmationCardStatus.pending:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Card is already {card.status.value}, cannot change status",
            )

        now = datetime.now(UTC)
        card.status = ConfirmationCardStatus(data.action)
        card.response_message = data.response_message
        card.responded_at = now

        # GAP-5: Create LessonBooking records when student confirms
        if data.action == "confirmed" and card.subscription_id:
            if not await self._subscription_has_confirmed_card(card):
                await self._create_bookings_for_subscription(card)

        await self.db.flush()
        await self.db.refresh(card)
        return await self._response_for_card(card)

    async def update_card_status(
        self,
        card_id: str,
        data: ScheduleConfirmationCardStatusUpdate,
        current_user: Any,
    ) -> ScheduleConfirmationCardResponse:
        """Update a confirmation card status through the Flutter repository contract."""
        from app.models.policy import ConfirmationCardStatus

        card = await self._get_card_for_user(card_id, current_user)
        if card.status != ConfirmationCardStatus.pending:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Card is already {card.status.value}, cannot change status",
            )

        card.status = ConfirmationCardStatus(data.status)
        card.response_message = data.response_message
        card.responded_at = data.responded_at or datetime.now(UTC)

        if data.status == "confirmed" and card.subscription_id:
            if not await self._subscription_has_confirmed_card(card):
                await self._create_bookings_for_subscription(card)

        await self.db.flush()
        await self.db.refresh(card)
        return await self._response_for_card(card)

    async def dismiss_all_pending(
        self,
        data: ScheduleConfirmationCardDismissAll,
        current_user: Any,
    ) -> ScheduleConfirmationCardDismissAllResponse:
        """Dismiss all pending visible cards for a student."""
        from app.models.policy import ConfirmationCardStatus, ScheduleConfirmationCard

        query = select(ScheduleConfirmationCard).where(
            ScheduleConfirmationCard.student_id == data.student_id,
            ScheduleConfirmationCard.status == ConfirmationCardStatus.pending,
        )
        query = await self._apply_access_filter(query, current_user)
        cards = (await self.db.scalars(query)).all()

        now = datetime.now(UTC)
        for card in cards:
            card.status = ConfirmationCardStatus.dismissed
            card.responded_at = now

        await self.db.flush()
        return ScheduleConfirmationCardDismissAllResponse(message=f"Dismissed {len(cards)} pending card")

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    async def _response_for_card(self, card: Any) -> ScheduleConfirmationCardResponse:
        response = ScheduleConfirmationCardResponse.model_validate(card)
        response.teacher_name = await self._teacher_name(card.teacher_id)
        return response

    async def _teacher_name(self, teacher_id: str) -> str:
        from app.models.teacher import Teacher
        from app.models.user import User

        user_name = await self.db.scalar(select(User.name).where(User.id == teacher_id))
        if user_name:
            return user_name

        profile_name = await self.db.scalar(
            select(User.name).join(Teacher, Teacher.user_id == User.id).where(Teacher.id == teacher_id)
        )
        return profile_name or ""

    async def _subscription_has_confirmed_card(self, card: Any) -> bool:
        from app.models.policy import ConfirmationCardStatus, ScheduleConfirmationCard

        confirmed_card_id = await self.db.scalar(
            select(ScheduleConfirmationCard.id).where(
                ScheduleConfirmationCard.subscription_id == card.subscription_id,
                ScheduleConfirmationCard.id != card.id,
                ScheduleConfirmationCard.status == ConfirmationCardStatus.confirmed,
            )
        )
        return confirmed_card_id is not None

    async def _create_bookings_for_subscription(self, card: Any) -> None:
        """GAP-5: Create LessonBooking records based on subscription type."""
        import datetime as dt

        from app.models.lesson import LessonSource
        from app.models.student import Student
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, card.subscription_id)
        if sub is None:
            return

        sub_type = sub.type.value if hasattr(sub.type, "value") else sub.type

        if sub_type == "trial":
            count = 1
            lesson_type = "trial"
        elif sub_type == "package":
            count = 1  # Package: book first lesson only
            lesson_type = "regular"
        else:  # monthly / regular
            count = sub.total_lessons or 4
            lesson_type = "regular"

        teacher_profile_id = await self._resolve_teacher_id_for_actor(card.teacher_id)

        student_name = card.student_id
        student = await self.db.get(Student, card.student_id)
        if student is not None:
            student_name = student.name

        # #301: distribute `count` lessons across weekly slots (주N회), week by week.
        # Uses card.proposed_slots when present; falls back to single proposed_day/time.
        base_date = dt.date.today()
        default_time = card.proposed_time or "14:00"
        default_duration = card.proposed_duration or 60

        slots: list[tuple[int, str, int]] = []
        raw_slots = card.proposed_slots
        if isinstance(raw_slots, list):
            for entry in raw_slots:
                if not isinstance(entry, dict) or entry.get("day") is None:
                    continue
                try:
                    day_idx = int(entry["day"])
                except (TypeError, ValueError):
                    continue
                slot_time = str(entry.get("time") or default_time)
                slot_duration = int(entry.get("duration") or default_duration)
                slots.append((day_idx, slot_time, slot_duration))
        if not slots:
            fallback_day = int(card.proposed_day) if card.proposed_day else base_date.weekday()
            slots = [(fallback_day, default_time, default_duration)]

        await self._generate_recurring_lessons(
            teacher_profile_id=teacher_profile_id,
            student_id=card.student_id,
            student_name=student_name,
            slots=slots,
            count=count,
            instrument=card.instrument,
            lesson_type=lesson_type,
            subscription_id=card.subscription_id,
            base_date=base_date,
            lesson_source=LessonSource.subscription_generated,
        )

    async def _generate_recurring_lessons(
        self,
        *,
        teacher_profile_id: str,
        student_id: str,
        student_name: str,
        slots: list[tuple[int, str, int]],
        count: int,
        instrument: str | None,
        lesson_type: str,
        subscription_id: str | None = None,
        base_date: Any = None,
        lesson_source: Any = None,
    ) -> list[Any]:
        """#301: Generate `count` recurring lessons across weekly `slots` (주N회).

        Shared by subscription-card confirmation and standalone regular-lesson
        registration. Each slot is (weekday 0=Mon, "HH:MM", duration_minutes).
        Occurrences cycle slot-by-slot, week by week (round-robin). Occurrences
        that conflict with an existing teacher booking are skipped. Returns the
        created LessonBooking rows (callers may ignore).
        """
        import datetime as dt
        from datetime import timedelta

        from app.models.lesson import Lesson, LessonSource
        from app.models.schedule import LessonBooking

        if not slots or count <= 0:
            return []
        if base_date is None:
            base_date = dt.date.today()
        if lesson_source is None:
            lesson_source = LessonSource.subscription_generated

        # Generate `count` NON-conflicting occurrences, cycling slots across weeks
        # (0=Mon). When the teacher already has a booking at a candidate slot we
        # push that occurrence to the next week's slot instead of dropping it, so
        # the student always gets the `count` lessons they paid for (#897 follow-up).
        # ponytail: cap weeks so a permanently-blocked slot can't loop forever;
        # `count` weeks covers the no-conflict span, +52 gives headroom for conflicts.
        occurrences: list[tuple[dt.date, str, int]] = []
        week = 0
        max_weeks = count + 52
        while len(occurrences) < count and week < max_weeks:
            for slot_day, slot_time, slot_duration in slots:
                if len(occurrences) >= count:
                    break
                days_ahead = slot_day - base_date.weekday()
                if days_ahead <= 0:
                    days_ahead += 7
                scheduled_date = base_date + timedelta(days=days_ahead, weeks=week)
                conflict = await self._check_time_conflict(
                    teacher_id=teacher_profile_id,
                    scheduled_date=scheduled_date,
                    scheduled_time=slot_time,
                    duration=slot_duration,
                )
                if conflict:
                    continue  # push to next week's slot — don't drop the lesson
                occurrences.append((scheduled_date, slot_time, slot_duration))
            week += 1

        created: list[Any] = []
        for i, (scheduled_date, scheduled_time, duration) in enumerate(occurrences):
            booking = LessonBooking(
                teacher_id=teacher_profile_id,
                student_id=student_id,
                lesson_type=lesson_type,
                scheduled_date=scheduled_date,
                scheduled_time=scheduled_time,
                duration=duration,
                instrument=instrument,
                subscription_id=subscription_id,
                status="confirmed",
            )
            self.db.add(booking)
            created.append(booking)

            lesson = Lesson(
                teacher_id=teacher_profile_id,
                student_id=student_id,
                student_name=student_name,
                instrument=instrument or "",
                date=scheduled_date,
                start_time=scheduled_time,
                duration=duration,
                status="scheduled",
                subscription_id=subscription_id,
                session_number=i + 1,
                lesson_source=lesson_source,
            )
            self.db.add(lesson)

        # #301: safety net — push-forward normally fills all `count`. If conflicts
        # persist past the week cap we still under-deliver; surface it loudly.
        skipped = count - len(created)
        if skipped > 0:
            logger.warning(
                "#301 recurring lessons: only %d/%d occurrence(s) placed; %d unfilled after "
                "%d weeks of booking conflicts (teacher=%s student=%s subscription=%s)",
                len(created),
                count,
                skipped,
                max_weeks,
                teacher_profile_id,
                student_id,
                subscription_id,
            )

        return created

    async def create_standalone_regular_lessons(self, data: Any, current_user: Any) -> tuple[list[Any], int]:
        """#301: Create recurring multi-slot lessons from a standalone regular-lesson
        registration (register_regular_lesson_screen → POST /bookings with
        ``fixed_time_slots``). Returns (created LessonBooking rows, requested count) so
        callers can surface partial loss (requested - created = skipped conflicts).

        Source of N concurrent weekly slots: the teacher's register-regular-lesson
        screen. Each slot is {day_of_week, start_time, duration_minutes}.
        """
        import datetime as dt

        from app.models.lesson import LessonSource
        from app.models.student import Student
        from app.models.subscription import Subscription

        teacher_profile_id = await self._resolve_teacher_id_for_actor(data.teacher_id)
        student_id = data.student_id or current_user.id

        student_name = data.student_name or student_id
        student = await self.db.get(Student, student_id)
        if student is not None:
            student_name = student.name

        # Normalize FE slots {day_of_week, start_time, duration_minutes} → (day, time, duration).
        slots: list[tuple[int, str, int]] = []
        for entry in data.fixed_time_slots or []:
            if not isinstance(entry, dict):
                continue
            day = entry.get("day_of_week", entry.get("day"))
            if day is None:
                continue
            try:
                day_idx = int(day)
            except (TypeError, ValueError):
                continue
            slot_time = str(entry.get("start_time") or entry.get("time") or "14:00")
            slot_duration = int(entry.get("duration_minutes") or entry.get("duration") or data.duration or 60)
            slots.append((day_idx, slot_time, slot_duration))
        if not slots:
            raise ValueError("fixed_time_slots is required for a recurring registration")

        # count: subscription drives total_lessons; standalone falls back to one month.
        # ponytail: lessons_per_week × 4 horizon; if a subscription is linked, use its
        # total_lessons. Longer horizons can be parameterized later.
        count = len(slots) * 4
        if data.subscription_id:
            sub = await self.db.get(Subscription, data.subscription_id)
            if sub is not None and sub.total_lessons:
                count = sub.total_lessons

        base_date = data.scheduled_date if isinstance(data.scheduled_date, dt.date) else dt.date.today()
        lesson_source = LessonSource.subscription_generated if data.subscription_id else LessonSource.manual

        created = await self._generate_recurring_lessons(
            teacher_profile_id=teacher_profile_id,
            student_id=student_id,
            student_name=student_name,
            slots=slots,
            count=count,
            instrument=data.instrument,
            lesson_type=data.lesson_type or "regular",
            subscription_id=data.subscription_id,
            base_date=base_date,
            lesson_source=lesson_source,
        )
        await self.db.flush()
        for booking in created:
            await self.db.refresh(booking)
        return created, count

    async def _check_time_conflict(
        self,
        teacher_id: str,
        scheduled_date: Any,
        scheduled_time: str,
        duration: int,
    ) -> bool:
        """Check if teacher has an existing booking at this date/time."""
        from app.models.lesson import Lesson
        from app.models.schedule import LessonBooking

        teacher_ids = await self._resolve_teacher_id_scope(teacher_id)

        existing = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.teacher_id.in_(teacher_ids),
                LessonBooking.scheduled_date == scheduled_date,
                LessonBooking.status.not_in(["cancelled", "expired"]),
            )
        )

        new_start = self._time_to_minutes(scheduled_time)
        new_end = new_start + duration

        for booking in existing.all():
            existing_start = self._time_to_minutes(booking.scheduled_time)
            existing_end = existing_start + (booking.duration or 60)
            if new_start < existing_end and new_end > existing_start:
                return True

        existing_lessons = await self.db.scalars(
            select(Lesson).where(
                Lesson.teacher_id.in_(teacher_ids),
                Lesson.date == scheduled_date,
            )
        )

        for lesson in existing_lessons.all():
            if self._is_cancelled_lesson_status(lesson.status):
                continue
            existing_start = self._time_to_minutes(lesson.start_time)
            existing_end = existing_start + (lesson.duration or 60)
            if new_start < existing_end and new_end > existing_start:
                return True

        return False

    async def _resolve_teacher_id_scope(self, teacher_id: str) -> list[str]:
        """Return both user and profile IDs for a teacher identifier."""
        from app.models.teacher import Teacher

        teacher_ids = [teacher_id]
        teacher = await self.db.get(Teacher, teacher_id)
        if teacher is not None:
            if teacher.user_id not in teacher_ids:
                teacher_ids.append(teacher.user_id)
            return teacher_ids

        profile_id = await self.db.scalar(select(Teacher.id).where(Teacher.user_id == teacher_id))
        if profile_id is not None and profile_id not in teacher_ids:
            teacher_ids.append(profile_id)
        return teacher_ids

    @staticmethod
    def _is_cancelled_lesson_status(status: Any) -> bool:
        from app.models.lesson import LessonStatus

        if isinstance(status, LessonStatus):
            return status in {
                LessonStatus.cancelled,
                LessonStatus.cancelledByStudentAdvance,
                LessonStatus.cancelledByStudentLate,
                LessonStatus.cancelledByTeacher,
                LessonStatus.cancelledMutual,
            }
        return str(status).endswith("cancelled")

    @staticmethod
    def _time_to_minutes(time_str: str) -> int:
        """Convert 'HH:MM' to minutes since midnight."""
        parts = time_str.split(":")
        return int(parts[0]) * 60 + int(parts[1])

    async def _get_card_for_user(self, card_id: str, current_user: Any) -> Any:
        from app.models.policy import ScheduleConfirmationCard

        card = await self.db.get(ScheduleConfirmationCard, card_id)
        if card is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Schedule confirmation card not found",
            )
        if not await self._can_access(card, current_user):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Forbidden",
            )
        return card

    async def _can_access(self, card: Any, current_user: Any) -> bool:
        role = actor_type(current_user)
        if role == "teacher":
            result: bool = card.teacher_id in await self._teacher_identifiers(current_user)
            return result
        if role == "student":
            result2: bool = card.student_id in await self._student_identifiers(current_user)
            return result2
        if role == "parent":
            result3: bool = card.student_id in await self._parent_child_student_ids(current_user)
            return result3
        return False

    async def _apply_access_filter(self, query: Any, current_user: Any) -> Any:
        from app.models.policy import ScheduleConfirmationCard

        role = actor_type(current_user)
        if role == "teacher":
            teacher_ids = await self._teacher_identifiers(current_user)
            return query.where(ScheduleConfirmationCard.teacher_id.in_(teacher_ids))
        if role == "student":
            return query.where(ScheduleConfirmationCard.student_id.in_(await self._student_identifiers(current_user)))
        if role == "parent":
            return query.where(
                ScheduleConfirmationCard.student_id.in_(await self._parent_child_student_ids(current_user))
            )
        return query.where(False)

    async def _student_identifiers(self, user: Any) -> list[str]:
        """Return user id plus linked Student profile ids for student actors."""
        from app.models.student import Student

        identifiers = [user.id]
        result = await self.db.scalars(select(Student.id).where(Student.user_id == user.id))
        for student_id in result.all():
            if student_id not in identifiers:
                identifiers.append(student_id)
        return identifiers

    async def _teacher_identifiers(self, user: Any) -> list[str]:
        """Return user id plus linked Teacher profile id for teacher actors."""
        from app.models.teacher import Teacher

        identifiers = [user.id]
        result = await self.db.scalars(select(Teacher.id).where(Teacher.user_id == user.id))
        for teacher_id in result.all():
            if teacher_id not in identifiers:
                identifiers.append(teacher_id)
        return identifiers

    async def _parent_child_student_ids(self, user: Any) -> list[str]:
        """Return active child Student ids for a parent user."""
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == user.id))
        if parent_id is None:
            return []

        result = await self.db.scalars(
            select(ParentChildRelation.student_id).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        return list(result.all())

    async def _resolve_teacher_id_for_actor(self, actor_id: str) -> str:
        """Normalize actor id to teacher profile ID when possible."""
        from app.models.teacher import Teacher

        if await self.db.scalar(select(Teacher.id).where(Teacher.id == actor_id)):
            return actor_id

        user_teacher_id = await self.db.scalar(select(Teacher.id).where(Teacher.user_id == actor_id))
        return user_teacher_id or actor_id
