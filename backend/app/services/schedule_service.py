"""Schedule service – availability, bookings, exceptions."""

from __future__ import annotations

import datetime as _dt
from datetime import UTC, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.schedule import (
    AvailabilityCreate,
    AvailabilityResponse,
    BookingChangeRequest,
    BookingCreate,
    BookingResponse,
    BookingUpdate,
    MakeupBookingCreate,
    ScheduleExceptionCreate,
    ScheduleExceptionResponse,
    ScheduleExceptionUpdate,
    SlotsResponse,
    WeeklyScheduleResponse,
)


def _parse_time_to_minutes(t: str) -> int:
    """Parse "HH:MM" to total minutes since midnight."""
    parts = t.split(":")
    return int(parts[0]) * 60 + int(parts[1])


def _slot_overlaps_blocked(slot_start: int, slot_end: int, blocked: list[tuple[int, int]]) -> bool:
    """Return True if the slot [slot_start, slot_end) overlaps any blocked range."""
    for b_start, b_end in blocked:
        if slot_start < b_end and slot_end > b_start:
            return True
    return False


class ScheduleService:
    """Handle teacher availability, booking lifecycle, and schedule exceptions."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Availability
    # ------------------------------------------------------------------

    async def get_availability(self, current_user: Any) -> AvailabilityResponse:
        """Return the teacher's weekly availability."""
        return await self.get_availability_by_teacher_id(current_user.id)

    async def get_availability_by_teacher_id(self, teacher_id: str) -> AvailabilityResponse:
        """Return weekly availability for a target teacher id or profile id."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
        from app.models.schedule_ext import ScheduleException
        from app.schemas.schedule import DayAvailability, TimeSlotSchema

        teacher_id_scope = await self._resolve_teacher_id_scope(teacher_id)
        teacher_user_id = await self._resolve_teacher_user_id(teacher_id)
        availability_rows = await self.db.scalars(
            select(TeacherAvailability)
            .where(TeacherAvailability.teacher_id.in_(teacher_id_scope))
            .order_by(TeacherAvailability.day_of_week)
        )
        day_list = []
        weekly_schedules = []
        avails = availability_rows.all()
        avail_ids = [a.id for a in avails]

        for avail in avails:
            slots_rows = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
            )
            time_slots = []
            for slot in slots_rows.all():
                time_slots.append(TimeSlotSchema(start_time=slot.start_time, end_time=slot.end_time))
                weekly_schedules.append(
                    {
                        "id": f"{avail.day_of_week}-{slot.start_time}-{slot.end_time}",
                        "day_of_week": avail.day_of_week,
                        "start_time": slot.start_time,
                        "end_time": slot.end_time,
                        "is_active": True,
                    }
                )
            day_list.append(DayAvailability(day_of_week=avail.day_of_week, time_slots=time_slots))

        exception_filter = [ScheduleException.teacher_id.in_(teacher_id_scope)]
        if avail_ids:
            exception_filter.append(ScheduleException.teacher_availability_id.in_(avail_ids))
        exception_rows = await self.db.scalars(select(ScheduleException).where(or_(*exception_filter)))
        exceptions = [
            {
                "id": exc.id,
                "teacher_id": exc.teacher_id,
                "teacher_availability_id": exc.teacher_availability_id,
                "type": exc.type.value,
                "start_date": exc.start_date,
                "end_date": exc.end_date,
                "start_time": exc.start_time,
                "end_time": exc.end_time,
                "reason": exc.reason,
                "created_at": exc.created_at,
            }
            for exc in exception_rows.all()
        ]

        created_at = avails[0].created_at if avails else _dt.datetime.now(UTC)

        return AvailabilityResponse(
            id=f"availability-{teacher_user_id}",
            teacher_id=teacher_user_id,
            availabilities=day_list,
            weekly_schedules=weekly_schedules,
            exceptions=exceptions,
            created_at=created_at,
        )

    async def set_availability(self, data: AvailabilityCreate, current_user: Any) -> AvailabilityResponse:
        """Replace the teacher's weekly availability."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        # Delete existing time slots first (child records)
        existing = await self.db.scalars(
            select(TeacherAvailability).where(TeacherAvailability.teacher_id == current_user.id)
        )
        for a in existing.all():
            child_slots = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == a.id)
            )
            for cs in child_slots.all():
                await self.db.delete(cs)
            await self.db.delete(a)
        await self.db.flush()

        # Create new
        for day in data.availabilities:
            avail = TeacherAvailability(
                teacher_id=current_user.id,
                day_of_week=day.day_of_week,
            )
            self.db.add(avail)
            await self.db.flush()

            for slot in day.time_slots:
                ts = AvailabilityTimeSlot(
                    availability_id=avail.id,
                    start_time=slot.start_time,
                    end_time=slot.end_time,
                )
                self.db.add(ts)

        await self.db.flush()
        return await self.get_availability(current_user)

    async def clear_availability(self, current_user: Any) -> None:
        """Remove all weekly availability rows for the current teacher."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        existing = await self.db.scalars(
            select(TeacherAvailability).where(TeacherAvailability.teacher_id == current_user.id)
        )
        for availability in existing.all():
            child_slots = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == availability.id)
            )
            for slot in child_slots.all():
                await self.db.delete(slot)
            await self.db.delete(availability)
        await self.db.flush()

    async def get_weekly_schedule(self, current_user: Any, *, week_start: str | None = None) -> WeeklyScheduleResponse:
        """Return the merged weekly schedule (availability + bookings)."""
        from datetime import date as date_type
        from datetime import timedelta

        from app.models.lesson import Lesson, LessonStatus
        from app.models.schedule import AvailabilityTimeSlot, LessonBooking, TeacherAvailability
        from app.models.schedule_ext import ScheduleException

        ws = date_type.fromisoformat(week_start) if week_start else date_type.today()
        # Align to Monday
        ws = ws - timedelta(days=ws.weekday())
        week_end = ws + timedelta(days=6)
        teacher_id_scope = await self._resolve_teacher_id_scope(current_user.id)

        # Load availability
        avail_rows = await self.db.scalars(
            select(TeacherAvailability).where(TeacherAvailability.teacher_id.in_(teacher_id_scope))
        )
        avail_by_day: dict[int, list[dict]] = {}
        avail_ids: list[str] = []
        for avail in avail_rows.all():
            avail_ids.append(avail.id)
            slots_rows = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
            )
            avail_by_day[avail.day_of_week] = [
                {"start_time": s.start_time, "end_time": s.end_time, "type": "available"} for s in slots_rows.all()
            ]

        # Load schedule exceptions (holiday/vacation) for this week.
        exception_scope = [
            ScheduleException.teacher_id.in_(teacher_id_scope),
        ]
        if avail_ids:
            exception_scope.append(ScheduleException.teacher_availability_id.in_(avail_ids))

        exceptions_by_date: dict[str, list[dict]] = {}
        exception_rows = await self.db.scalars(
            select(ScheduleException).where(
                or_(*exception_scope),
                ScheduleException.start_date <= week_end,
                ScheduleException.end_date >= ws,
                ScheduleException.type.in_(["holiday", "vacation"]),
            )
        )
        for exc in exception_rows.all():
            # For each affected date in the requested window, append exception block.
            current_day = max(ws, exc.start_date)
            end_day = min(week_end, exc.end_date)
            if current_day > end_day:
                continue
            while current_day <= end_day:
                date_str = current_day.isoformat()
                start_time = exc.start_time or "00:00"
                end_time = exc.end_time or "23:59"
                exceptions_by_date.setdefault(date_str, []).append(
                    {
                        "type": "exception",
                        "exception_type": str(exc.type.value),
                        "status": "unavailable",
                        "start_time": start_time,
                        "end_time": end_time,
                        "reason": exc.reason,
                        "exception_id": exc.id,
                    }
                )
                current_day += timedelta(days=1)

        # Load bookings for this week
        bookings = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.teacher_id.in_(teacher_id_scope),
                LessonBooking.scheduled_date >= ws,
                LessonBooking.scheduled_date <= week_end,
            )
        )
        bookings_by_date: dict[str, list[dict]] = {}
        for b in bookings.all():
            date_str = b.scheduled_date.isoformat()
            bookings_by_date.setdefault(date_str, []).append(
                {
                    "start_time": b.scheduled_time,
                    "duration": b.duration,
                    "status": b.status.value if hasattr(b.status, "value") else b.status,
                    "type": "booking",
                    "booking_id": b.id,
                }
            )

        # Load lesson records for this week
        lessons = await self.db.scalars(
            select(Lesson).where(
                Lesson.teacher_id.in_(teacher_id_scope),
                Lesson.date >= ws,
                Lesson.date <= week_end,
                Lesson.status.not_in(
                    [
                        LessonStatus.cancelled,
                        LessonStatus.cancelledByStudentAdvance,
                        LessonStatus.cancelledByStudentLate,
                        LessonStatus.cancelledByTeacher,
                        LessonStatus.cancelledMutual,
                    ]
                ),
            )
        )
        lessons_by_date: dict[str, list[dict]] = {}
        for lesson in lessons.all():
            date_str = lesson.date.isoformat()
            # Skip exact duplicates when booking already exists at same slot.
            if any(
                existing.get("start_time") == lesson.start_time and existing.get("duration") == lesson.duration
                for existing in bookings_by_date.get(date_str, [])
            ):
                continue
            lessons_by_date.setdefault(date_str, []).append(
                {
                    "start_time": lesson.start_time,
                    "duration": lesson.duration,
                    "status": lesson.status.value if hasattr(lesson.status, "value") else lesson.status,
                    "student_id": lesson.student_id,
                    "lesson_id": lesson.id,
                    "subscription_id": lesson.subscription_id,
                    "session_number": lesson.session_number,
                    "lesson_source": (
                        lesson.lesson_source.value if hasattr(lesson.lesson_source, "value") else lesson.lesson_source
                    ),
                    "type": "lesson",
                }
            )

        # Build days dict
        days: dict[str, list] = {}
        for i in range(7):
            current_date = ws + timedelta(days=i)
            date_str = current_date.isoformat()
            events = []
            if i in avail_by_day:
                events.extend(avail_by_day[i])
            if date_str in bookings_by_date:
                events.extend(bookings_by_date[date_str])
            if date_str in lessons_by_date:
                events.extend(lessons_by_date[date_str])
            if date_str in exceptions_by_date:
                events.extend(exceptions_by_date[date_str])
            if events:
                days[date_str] = events

        return WeeklyScheduleResponse(week_start=ws, days=days)

    async def _resolve_teacher_user_id(self, teacher_id: str) -> str:
        """Resolve Teacher.id or User.id to the correct User.id for queries."""
        from app.models.teacher import Teacher

        # If teacher_id is a Teacher.id, resolve to user_id
        teacher = await self.db.get(Teacher, teacher_id)
        if teacher:
            return teacher.user_id
        # Otherwise assume it's already a User.id
        return teacher_id

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

    async def get_frontend_time_slots(self, *, teacher_id: str) -> list[dict[str, Any]]:
        """Return weekly availability as RemoteBookingRepository TimeSlot JSON."""
        availability = await self.get_availability_by_teacher_id(teacher_id)
        slots: list[dict[str, Any]] = []
        for schedule in availability.weekly_schedules:
            day_of_week = int(schedule["day_of_week"])
            slots.append(
                {
                    "id": schedule["id"],
                    "day_of_week": day_of_week + 1,
                    "start_time": schedule["start_time"],
                    "end_time": schedule["end_time"],
                    "is_active": schedule.get("is_active", True),
                }
            )
        return slots

    async def get_available_slots(self, *, teacher_id: str, date: str, duration: int = 60) -> SlotsResponse:
        """Compute available booking slots for a date."""
        from datetime import date as date_type

        from app.models.lesson import Lesson, LessonStatus
        from app.models.schedule import AvailabilityTimeSlot, LessonBooking, TeacherAvailability
        from app.models.schedule_ext import ExceptionType, ScheduleException
        from app.schemas.schedule import SlotStatus

        d = date_type.fromisoformat(date)
        day_of_week = d.weekday()  # 0=Monday

        # Resolve teacher_id (could be Teacher.id or User.id)
        user_id = await self._resolve_teacher_user_id(teacher_id)
        teacher_id_scope = await self._resolve_teacher_id_scope(teacher_id)

        # Find availability for this day
        availability_rows = await self.db.scalars(
            select(TeacherAvailability).where(
                TeacherAvailability.teacher_id.in_(teacher_id_scope),
                TeacherAvailability.day_of_week == day_of_week,
            )
        )
        availability_list = availability_rows.all()
        availability_ids = [a.id for a in availability_list]
        if not availability_ids:
            return SlotsResponse(date=d, slots=[])

        # #380: TeacherAvailability.vacation_mode 가 활성이고 현재 날짜가 범위 내면
        # 전체 슬롯 차단. ScheduleException(type=vacation)과 독립적으로 동작.
        from app.services.availability_service import AvailabilityService

        vacation_mode_blocked = any(AvailabilityService.is_slot_in_vacation(d, av) for av in availability_list)

        # Get time slots
        time_slots = await self.db.scalars(
            select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id.in_(availability_ids))
        )

        # Get existing bookings for this date
        bookings = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.teacher_id.in_(teacher_id_scope),
                LessonBooking.scheduled_date == d,
                LessonBooking.status.in_(["pending", "confirmed"]),
            )
        )
        booked_times = {b.scheduled_time for b in bookings.all()}

        # Get existing lessons for this date
        lessons = await self.db.scalars(
            select(Lesson).where(
                Lesson.teacher_id.in_(teacher_id_scope),
                Lesson.date == d,
                Lesson.status.not_in(
                    [
                        LessonStatus.cancelled,
                        LessonStatus.cancelledByStudentAdvance,
                        LessonStatus.cancelledByStudentLate,
                        LessonStatus.cancelledByTeacher,
                        LessonStatus.cancelledMutual,
                    ]
                ),
            )
        )
        booked_times.update(lesson.start_time for lesson in lessons.all())

        # Get schedule exceptions (holiday/vacation) covering this date (#236)
        exceptions = await self.db.scalars(
            select(ScheduleException).where(
                or_(
                    ScheduleException.teacher_id.in_(teacher_id_scope),
                    ScheduleException.teacher_availability_id.in_(availability_ids),
                ),
                ScheduleException.type.in_([ExceptionType.holiday, ExceptionType.vacation]),
                ScheduleException.start_date <= d,
                ScheduleException.end_date >= d,
            )
        )
        exception_list = exceptions.all()

        # Determine if this is a whole-day exception or collect partial ranges
        whole_day_blocked = False
        blocked_ranges: list[tuple[int, int]] = []
        for exc in exception_list:
            if exc.start_time is None:
                whole_day_blocked = True
                break
            assert exc.start_time is not None  # checked above
            exc_start = _parse_time_to_minutes(exc.start_time)
            exc_end = _parse_time_to_minutes(exc.end_time or exc.start_time)
            blocked_ranges.append((exc_start, exc_end))

        # Generate slots from availability
        slots: list[SlotStatus] = []
        for ts in time_slots.all():
            # Parse start/end times
            start_parts = ts.start_time.split(":")
            end_parts = ts.end_time.split(":")
            start_minutes = int(start_parts[0]) * 60 + int(start_parts[1])
            end_minutes = int(end_parts[0]) * 60 + int(end_parts[1])

            # Generate slots at 30-minute intervals
            current = start_minutes
            while current + duration <= end_minutes:
                slot_time = f"{current // 60:02d}:{current % 60:02d}"
                slot_end_minutes = current + duration
                slot_end_time = f"{slot_end_minutes // 60:02d}:{slot_end_minutes % 60:02d}"

                if vacation_mode_blocked or whole_day_blocked:
                    slot_status = "unavailable"
                elif _slot_overlaps_blocked(current, slot_end_minutes, blocked_ranges):
                    slot_status = "unavailable"
                elif slot_time in booked_times:
                    slot_status = "booked"
                else:
                    slot_status = "available"

                slots.append(
                    SlotStatus(
                        id=f"{user_id}-{d.isoformat()}-{slot_time}",
                        teacher_id=user_id,
                        date=d,
                        start_time=slot_time,
                        end_time=slot_end_time,
                        duration_minutes=duration,
                        status=slot_status,
                    )
                )
                current += 30  # 30-minute interval

        return SlotsResponse(date=d, slots=slots)

    async def get_available_slots_range(
        self,
        *,
        teacher_id: str,
        date_from: str,
        date_to: str | None = None,
        duration: int = 60,
        limit: int | None = None,
        available_only: bool = False,
    ) -> dict[str, Any]:
        """Return slots and dates for frontend range queries."""
        from datetime import date as date_type

        start = date_type.fromisoformat(date_from)
        end = date_type.fromisoformat(date_to) if date_to else start + timedelta(days=27)
        if end < start:
            end = start

        dates: list[str] = []
        slots: list[dict[str, Any]] = []
        current = start
        while current <= end:
            day_slots = await self.get_available_slots(
                teacher_id=teacher_id,
                date=current.isoformat(),
                duration=duration,
            )
            serialized_slots = [slot.model_dump(mode="json") for slot in day_slots.slots]
            if available_only:
                date_has_slots = any(slot["status"] == "available" for slot in serialized_slots)
            else:
                date_has_slots = bool(serialized_slots)
            if date_has_slots:
                dates.append(current.isoformat())
            slots.extend(serialized_slots)
            if limit is not None and len(dates) >= limit:
                break
            current += timedelta(days=1)

        return {"dates": dates, "slots": slots}

    # ------------------------------------------------------------------
    # Schedule exceptions
    # ------------------------------------------------------------------

    async def create_exception(self, data: ScheduleExceptionCreate, current_user: Any) -> ScheduleExceptionResponse:
        """Add a schedule exception."""
        from app.models.schedule_ext import ScheduleException

        self._validate_exception_dates_and_time(
            data.start_date,
            data.end_date,
            data.start_time,
            data.end_time,
        )

        exception = ScheduleException(
            teacher_id=current_user.id,
            teacher_availability_id=None,
            type=data.type,
            start_date=data.start_date,
            end_date=data.end_date,
            start_time=data.start_time,
            end_time=data.end_time,
            reason=data.reason,
        )
        self.db.add(exception)
        await self.db.flush()
        await self.db.refresh(exception)
        return ScheduleExceptionResponse.model_validate(exception)

    async def update_exception(
        self, exception_id: str, data: ScheduleExceptionUpdate, current_user: Any
    ) -> ScheduleExceptionResponse:
        """Update a schedule exception."""
        from app.models.schedule_ext import ScheduleException

        exception = await self.db.get(ScheduleException, exception_id)
        if exception is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exception not found")
        await self._assert_exception_owner(exception, current_user)

        update_data = data.model_dump(exclude_unset=True)
        updated_start_date = update_data.get("start_date", exception.start_date)
        updated_end_date = update_data.get("end_date", exception.end_date)
        updated_start_time = update_data.get("start_time", exception.start_time)
        updated_end_time = update_data.get("end_time", exception.end_time)
        self._validate_exception_dates_and_time(
            updated_start_date,
            updated_end_date,
            updated_start_time,
            updated_end_time,
        )

        for key, value in update_data.items():
            setattr(exception, key, value)
        await self.db.flush()
        await self.db.refresh(exception)
        return ScheduleExceptionResponse.model_validate(exception)

    @staticmethod
    def _validate_exception_dates_and_time(
        start_date: Any,
        end_date: Any,
        start_time: str | None,
        end_time: str | None,
    ) -> None:
        if start_date and end_date and start_date > end_date:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="start_date must be <= end_date",
            )
        if (start_time is None) != (end_time is None):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="start_time and end_time must be both provided",
            )
        if start_time is not None and end_time is not None:
            start_minutes = _parse_time_to_minutes(start_time)
            end_minutes = _parse_time_to_minutes(end_time)
            if start_minutes >= end_minutes:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="end_time must be after start_time",
                )

    async def delete_exception(self, exception_id: str, current_user: Any) -> None:
        """Delete a schedule exception."""
        from app.models.schedule_ext import ScheduleException

        exception = await self.db.get(ScheduleException, exception_id)
        if exception is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exception not found")
        await self._assert_exception_owner(exception, current_user)
        await self.db.delete(exception)
        await self.db.flush()

    async def _assert_exception_owner(self, exception: Any, current_user: Any | None) -> None:
        if current_user is None:
            return

        if getattr(exception, "teacher_id", None) is not None:
            current_teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
            if exception.teacher_id not in current_teacher_ids:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Forbidden",
                )
            return

        from app.models.schedule import TeacherAvailability

        availability = await self.db.get(TeacherAvailability, exception.teacher_availability_id)
        if availability is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exception availability not found",
            )
        current_teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        if availability.teacher_id not in current_teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _resolve_student_id_scope(self, user_id: str) -> list[str]:
        """Return user/student-profile IDs for a student identifier.

        spec parent_system.md — caller 가 parent 인 경우 자녀의 student_id 도 포함해
        booking/practice 조회가 가능하도록 scope 확장. (IDOR guard 유지 — parent 가
        자기 자녀가 아닌 학생의 데이터는 읽지 못함.)
        """
        from app.models.student import Student

        student_ids = [user_id]
        profile_id = await self.db.scalar(select(Student.id).where(Student.user_id == user_id))
        if profile_id is not None and profile_id not in student_ids:
            student_ids.append(profile_id)

        # parent → 자녀 student_id 들 union.
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == user_id))
        if parent_id is not None:
            child_rows = await self.db.scalars(
                select(ParentChildRelation.student_id)
                .where(ParentChildRelation.parent_id == parent_id)
                .where(ParentChildRelation.status == ParentChildRelationStatus.active)
            )
            for sid in child_rows.all():
                if sid and sid not in student_ids:
                    student_ids.append(sid)
        return student_ids

    async def _assert_booking_owner(self, booking: Any, current_user: Any | None) -> None:
        if current_user is None:
            return

        current_teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        if getattr(booking, "teacher_id", None) in current_teacher_ids:
            return

        current_student_ids = await self._resolve_student_id_scope(current_user.id)
        if getattr(booking, "student_id", None) in current_student_ids:
            return

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    # ------------------------------------------------------------------
    # Bookings
    # ------------------------------------------------------------------

    async def get_all_bookings(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        teacher_id: str | None = None,
        student_id: str | None = None,
        status: str | None = None,
        date_from: str | None = None,
        date_to: str | None = None,
    ) -> PaginatedResponse[BookingResponse]:
        """List bookings with filters."""
        from app.models.schedule import LessonBooking

        # IDOR guard (#460): scope results to the caller. An explicit teacher_id/
        # student_id filter only applies when it belongs to the caller; otherwise
        # fall back to the caller's own teacher/student scope so a non-owner can
        # never read other users' bookings.
        query = select(LessonBooking)
        if user is not None:
            caller_teacher_ids = await self._resolve_teacher_id_scope(user.id)
            caller_student_ids = await self._resolve_student_id_scope(user.id)

            teacher_match = teacher_id in caller_teacher_ids if teacher_id else False
            student_match = student_id in caller_student_ids if student_id else False

            if teacher_match:
                query = query.where(LessonBooking.teacher_id == teacher_id)
                teacher_id = None
            if student_match:
                query = query.where(LessonBooking.student_id == student_id)
                student_id = None
            if not teacher_match and not student_match:
                query = query.where(
                    or_(
                        LessonBooking.teacher_id.in_(caller_teacher_ids),
                        LessonBooking.student_id.in_(caller_student_ids),
                    )
                )
                teacher_id = None
                student_id = None

        if teacher_id:
            query = query.where(LessonBooking.teacher_id == teacher_id)
        if student_id:
            query = query.where(LessonBooking.student_id == student_id)
        if status:
            query = query.where(LessonBooking.status == status)
        if date_from:
            query = query.where(LessonBooking.scheduled_date >= date_from)
        if date_to:
            query = query.where(LessonBooking.scheduled_date <= date_to)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [await self._to_booking_response(b) for b in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def _check_booking_overlap(
        self,
        teacher_id: str,
        scheduled_date: Any,
        scheduled_time: str,
        duration: int,
    ) -> None:
        """Raise 409 if the slot overlaps with existing bookings (#237)."""
        from datetime import datetime, timedelta

        from app.models.schedule import LessonBooking

        new_start = datetime.strptime(scheduled_time, "%H:%M")
        new_end = new_start + timedelta(minutes=duration)

        existing = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.teacher_id == teacher_id,
                LessonBooking.scheduled_date == scheduled_date,
                LessonBooking.status.in_(["pending", "confirmed"]),
            )
        )

        for booking in existing.all():
            ex_start = datetime.strptime(booking.scheduled_time, "%H:%M")
            ex_end = ex_start + timedelta(minutes=booking.duration)
            if new_start < ex_end and new_end > ex_start:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="해당 시간에 이미 예약이 있습니다",
                )

    async def create_booking(self, data: BookingCreate, current_user: Any) -> BookingResponse:
        """Create a new booking request."""
        from app.models.schedule import LessonBooking

        assert data.teacher_id is not None  # normalized by BookingCreate

        # #301: standalone 주N회 등록 — N개 동시 주간 슬롯을 recurring 레슨으로 분배 생성.
        if data.fixed_time_slots:
            from app.services.schedule_confirmation_service import ScheduleConfirmationService

            created, requested = await ScheduleConfirmationService(self.db).create_standalone_regular_lessons(
                data, current_user
            )
            if not created:
                raise ValueError("선택한 시간이 모두 기존 일정과 충돌합니다")
            response = await self._to_booking_response(created[0])
            # 충돌로 건너뛴 회차 수를 응답에 실어 FE 가 교사에게 안내하게 한다.
            response.recurring_skipped_count = requested - len(created)
            return response

        await self._check_booking_overlap(
            teacher_id=data.teacher_id,
            scheduled_date=data.scheduled_date,
            scheduled_time=data.scheduled_time or "",
            duration=data.duration,
        )

        booking = LessonBooking(
            teacher_id=data.teacher_id,
            student_id=data.student_id or current_user.id,
            lesson_type=data.lesson_type,
            scheduled_date=data.scheduled_date,
            scheduled_time=data.scheduled_time,
            duration=data.duration,
            instrument=data.instrument,
            subscription_id=data.subscription_id,
            notes=data.notes,
            status="pending",
        )
        self.db.add(booking)
        await self.db.flush()
        await self.db.refresh(booking)

        # spec makeup_credit_spec.md §8.1 — useCredit=true 면 보강 크레딧 소비.
        if data.use_credit:
            await self._consume_makeup_credit_for_booking(
                booking_id=booking.id,
                student_id=booking.student_id,
                credit_id=data.credit_id,
            )

        return await self._to_booking_response(booking)

    async def create_slot_booking(self, data: BookingCreate, current_user: Any) -> dict[str, Any]:
        """Create a booking from a frontend availability slot payload."""
        booking = await self.create_booking(data, current_user)
        return {
            "id": booking.id,
            "teacher_id": booking.teacher_id,
            "date": booking.scheduled_date,
            "start_time": booking.scheduled_time,
            "end_time": booking.end_time,
            "duration_minutes": booking.duration,
            "status": "booked",
            "booked_by_student_id": booking.student_id,
            "booked_by_student_name": data.student_name,
            "lesson_id": None,
            "is_recommended": False,
        }

    async def _to_booking_response(self, booking: Any) -> BookingResponse:
        """spec — BookingResponse 의 teacher_name / student_name 을 join 으로 채움.

        FE 가 빈 칸으로 떨어지지 않도록 단일 진입점에서 enrich.
        """
        from app.models.user import User

        response = BookingResponse.model_validate(booking)
        # teacher.id 가 User.id 인 케이스가 일반적 (resolve_teacher_id 결과 == Teacher.id !=
        # User.id 인 코드도 있으나 LessonBooking.teacher_id 는 Teacher.id 또는 User.id 양쪽
        # 사용 — 두 경로 모두 시도해서 가장 먼저 찾은 이름 채움).
        if booking.teacher_id:
            from app.models.teacher import Teacher

            teacher_row = await self.db.scalar(select(Teacher).where(Teacher.id == booking.teacher_id))
            target_user_id = teacher_row.user_id if teacher_row is not None else booking.teacher_id
            teacher_user = await self.db.scalar(select(User).where(User.id == target_user_id))
            if teacher_user is not None and teacher_user.name:
                response.teacher_name = teacher_user.name
        if booking.student_id:
            student_user = await self.db.scalar(select(User).where(User.id == booking.student_id))
            if student_user is not None and student_user.name:
                response.student_name = student_user.name
        return response

    async def _consume_reschedule_credit_or_raise(self, booking: Any, actor: Any) -> None:
        """spec subscription_edit_spec.md §2.1 / §7.1 — booking 변경 시 sub 변경권 차감.

        booking.subscription_id 가 없으면 (정규권 외 booking) 무차감. 잔여 없으면 422.
        차감 성공 시 SubscriptionUsage(type='reschedule') 적립 + 알림 발송.
        """
        if not booking.subscription_id:
            return
        from app.models.subscription import Subscription, SubscriptionUsage

        sub = await self.db.scalar(
            select(Subscription).where(Subscription.id == booking.subscription_id).with_for_update()
        )
        if sub is None:
            return
        effective = (sub.total_reschedule_allowance or 0) + (sub.bonus_reschedule_count or 0)
        used = sub.used_reschedule_count or 0
        remaining = effective - used
        if remaining <= 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="No remaining reschedule credits",
            )
        usage = SubscriptionUsage(subscription_id=sub.id, type="reschedule")
        self.db.add(usage)
        sub.used_reschedule_count = used + 1
        await self.db.flush()
        await self._notify_booking_change(booking, actor, remaining_after=remaining - 1)

    async def _notify_booking_change(self, booking: Any, actor: Any, *, remaining_after: int) -> None:
        """spec notification_master.md — booking 변경 시 상대편 + 본인 알림.

        actor 가 학생이면 선생님(쪽 user_id), actor 가 선생님이면 학생에게 알림.
        teacher_id 가 Teacher.id 인 경우 user_id 로 resolve.
        """
        from app.models.teacher import Teacher
        from app.services.notification_service import NotificationService

        teacher_user_id = booking.teacher_id
        teacher_row = await self.db.scalar(select(Teacher).where(Teacher.id == booking.teacher_id))
        if teacher_row is not None:
            teacher_user_id = teacher_row.user_id
        student_user_id = booking.student_id

        actor_role = getattr(getattr(actor, "role", None), "value", None) or "student"
        recipient_id = teacher_user_id if actor_role == "student" else student_user_id
        if not recipient_id:
            return
        notif = NotificationService(self.db)
        await notif.create_and_send(
            user_id=recipient_id,
            notification_type="scheduleChangeRequested",
            title="레슨 일정 변경 요청",
            body=f"{booking.scheduled_date} {booking.scheduled_time} 로 변경 요청되었습니다.",
            data={
                "booking_id": booking.id,
                "remaining_reschedule": remaining_after,
            },
        )

    async def _consume_makeup_credit_for_booking(
        self,
        *,
        booking_id: str,
        student_id: str,
        credit_id: str | None,
    ) -> None:
        """spec makeup_credit_spec.md §5.3 — use_credit=true 시 보강 크레딧 1건 소비.

        credit_id 명시 시 그것을, 미명시 시 가장 임박한 active 크레딧을 자동 선택.
        없으면 422 (사용 가능한 크레딧 없음).
        """
        from sqlalchemy import select as _select

        from app.models.makeup_credit import MakeupCredit
        from app.services.makeup_credit_service import MakeupCreditService

        target_id = credit_id
        if target_id is None:
            now = _dt.datetime.now(UTC)
            credit_row = await self.db.scalar(
                _select(MakeupCredit)
                .where(MakeupCredit.student_id == student_id)
                .where(MakeupCredit.used_at.is_(None))
                .where(MakeupCredit.expires_at > now)
                .order_by(MakeupCredit.expires_at.asc())
            )
            if credit_row is None:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="No active makeup credit available",
                )
            target_id = credit_row.id

        service = MakeupCreditService(self.db)
        try:
            await service.use_credit(credit_id=target_id, lesson_id=booking_id)
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=str(exc),
            ) from exc

    async def get_booking_by_id(self, booking_id: str, current_user: Any) -> BookingResponse:
        """Return a single booking."""
        from app.models.schedule import LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        await self._assert_booking_owner(booking, current_user)
        return await self._to_booking_response(booking)

    async def update_booking(self, booking_id: str, data: BookingUpdate, current_user: Any) -> BookingResponse:
        """Update a booking.

        FE 가 PUT /bookings/{id} 로 date/time 만 바꾸는 경우 — 정책 적용 누락 방지를 위해
        change_booking 흐름 (status=changeRequested) 으로 위임. 변경권 차감/알림 자체는
        별도 PR 범위 (BookingChangeRequest 통합 시 wiring).
        """
        from app.models.schedule import BookingStatus, LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        await self._assert_booking_owner(booking, current_user)

        update_data = data.model_dump(exclude_unset=True)
        update_data.pop("lesson_date", None)
        update_data.pop("start_time", None)

        # FE 호환 — 실제 date 또는 time 이 바뀌면 변경 의도. status=changeRequested 일관 처리.
        date_changed = "scheduled_date" in update_data and update_data["scheduled_date"] != booking.scheduled_date
        time_changed = "scheduled_time" in update_data and update_data["scheduled_time"] != booking.scheduled_time
        is_change_intent = (date_changed or time_changed) and "status" not in update_data

        # 변경 의도라면 차감 검증 먼저 (잔여 0 이면 422 — 실제 mutate 전 차단).
        if is_change_intent:
            await self._consume_reschedule_credit_or_raise(booking, current_user)

        for key, value in update_data.items():
            if key == "status" and value is not None:
                setattr(booking, key, BookingStatus(value))
            elif value is not None:
                setattr(booking, key, value)
        if is_change_intent:
            booking.status = BookingStatus.changeRequested
        await self.db.flush()
        await self.db.refresh(booking)
        return await self._to_booking_response(booking)

    async def delete_booking(self, booking_id: str, current_user: Any) -> None:
        """Delete a booking."""
        from app.models.schedule import LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        await self._assert_booking_owner(booking, current_user)
        await self.db.delete(booking)
        await self.db.flush()

    async def approve_booking(
        self,
        booking_id: str,
        current_user: Any,
        *,
        selected_option_id: str | None = None,
        target_status: str | None = None,
    ) -> BookingResponse:
        """Approve a pending booking.

        FE 호환 — body 의 status='completed' 면 BookingStatus.completed,
        그 외엔 confirmed. selected_option_id 가 있으면 notes 에 기록 (trial 옵션).
        """
        from app.models.schedule import BookingStatus, LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        await self._assert_booking_owner(booking, current_user)
        if target_status == "completed":
            booking.status = BookingStatus.completed
        else:
            booking.status = BookingStatus.confirmed
        if selected_option_id:
            prefix = f"[selected_option_id: {selected_option_id}]"
            booking.notes = f"{prefix}\n{booking.notes}" if booking.notes else prefix
        await self.db.flush()
        await self.db.refresh(booking)
        return await self._to_booking_response(booking)

    async def reject_booking(self, booking_id: str, reason: str | None, current_user: Any) -> BookingResponse:
        """Reject a pending booking — Plan B (#238): rejected 제거, cancelled + decline_reason 사유."""
        from app.models.schedule import BookingStatus, LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        await self._assert_booking_owner(booking, current_user)
        booking.status = BookingStatus.cancelled
        booking.notes = reason
        await self.db.flush()
        await self.db.refresh(booking)
        return await self._to_booking_response(booking)

    async def cancel_booking(self, booking_id: str, reason: str | None, current_user: Any) -> BookingResponse:
        """Cancel a booking."""
        from app.models.schedule import BookingStatus, LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        await self._assert_booking_owner(booking, current_user)
        booking.status = BookingStatus.cancelled
        booking.notes = reason
        await self.db.flush()
        await self.db.refresh(booking)
        return await self._to_booking_response(booking)

    async def change_booking(self, booking_id: str, data: BookingChangeRequest, current_user: Any) -> BookingResponse:
        """Request a change to booking date/time.

        spec subscription_edit_spec.md §2.1 / §7.1 — 변경권 차감 + 잔여 0 시 422.
        notification_master.md — 상대편에 scheduleChangeRequested 알림.
        """
        from app.models.schedule import BookingStatus, LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        await self._assert_booking_owner(booking, current_user)
        actually_changes = data.new_date != booking.scheduled_date or data.new_time != booking.scheduled_time
        if actually_changes:
            await self._consume_reschedule_credit_or_raise(booking, current_user)
        booking.scheduled_date = data.new_date
        booking.scheduled_time = data.new_time
        booking.status = BookingStatus.changeRequested
        booking.notes = data.reason
        await self.db.flush()
        await self.db.refresh(booking)
        return await self._to_booking_response(booking)

    async def get_makeup_bookings(self, current_user: Any) -> list[BookingResponse]:
        """Return makeup lesson bookings."""
        from app.models.schedule import LessonBooking

        result = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.lesson_type == "makeup",
                LessonBooking.teacher_id == current_user.id,
            )
        )
        return [await self._to_booking_response(b) for b in result.all()]

    async def create_makeup_booking(self, data: MakeupBookingCreate, current_user: Any) -> BookingResponse:
        """Create a makeup lesson booking."""
        from app.models.schedule import LessonBooking

        await self._check_booking_overlap(
            teacher_id=current_user.id,
            scheduled_date=data.scheduled_date,
            scheduled_time=data.scheduled_time,
            duration=data.duration,
        )

        booking = LessonBooking(
            teacher_id=current_user.id,
            student_id=data.student_id,
            lesson_type="makeup",
            scheduled_date=data.scheduled_date,
            scheduled_time=data.scheduled_time,
            status="confirmed",
            notes=data.reason,
        )
        self.db.add(booking)
        await self.db.flush()
        await self.db.refresh(booking)
        return await self._to_booking_response(booking)
