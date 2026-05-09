"""Schedule confirmation card service."""

from __future__ import annotations

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
        from datetime import timedelta

        from app.models.lesson import Lesson, LessonSource
        from app.models.schedule import LessonBooking
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

        base_date = dt.date.today()
        proposed_day = int(card.proposed_day) if card.proposed_day else base_date.weekday()

        # Find next occurrence of proposed_day (0=Mon)
        days_ahead = proposed_day - base_date.weekday()
        if days_ahead <= 0:
            days_ahead += 7
        first_date = base_date + timedelta(days=days_ahead)

        for i in range(count):
            scheduled_date = first_date + timedelta(weeks=i)
            scheduled_time = card.proposed_time or "14:00"
            duration = card.proposed_duration or 60

            # Skip this date if teacher already has a booking at this time
            conflict = await self._check_time_conflict(
                teacher_id=teacher_profile_id,
                scheduled_date=scheduled_date,
                scheduled_time=scheduled_time,
                duration=duration,
            )
            if conflict:
                continue

            booking = LessonBooking(
                teacher_id=teacher_profile_id,
                student_id=card.student_id,
                lesson_type=lesson_type,
                scheduled_date=scheduled_date,
                scheduled_time=scheduled_time,
                duration=duration,
                instrument=card.instrument,
                subscription_id=card.subscription_id,
                status="confirmed",
            )
            self.db.add(booking)

            lesson = Lesson(
                teacher_id=teacher_profile_id,
                student_id=card.student_id,
                student_name=student_name,
                instrument=card.instrument or "",
                date=scheduled_date,
                start_time=scheduled_time,
                duration=duration,
                status="scheduled",
                subscription_id=card.subscription_id,
                session_number=i + 1,
                lesson_source=LessonSource.subscription_generated,
            )
            self.db.add(lesson)

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
        role = self._actor_type(current_user)
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

        role = self._actor_type(current_user)
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

    def _actor_type(self, user: Any) -> str:
        role = getattr(user, "role", None)
        return getattr(role, "value", role) or ""

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
