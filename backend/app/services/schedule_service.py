"""Schedule service – availability, bookings, exceptions."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.schedule import (
    AvailabilityCreate,
    AvailabilityResponse,
    BookingChangeRequest,
    BookingCreate,
    BookingResponse,
    MakeupBookingCreate,
    ScheduleExceptionCreate,
    ScheduleExceptionResponse,
    ScheduleExceptionUpdate,
    SlotsResponse,
    WeeklyScheduleResponse,
)


class ScheduleService:
    """Handle teacher availability, booking lifecycle, and schedule exceptions."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Availability
    # ------------------------------------------------------------------

    async def get_availability(self, current_user: Any) -> AvailabilityResponse:
        """Return the teacher's weekly availability."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
        from app.schemas.schedule import DayAvailability, TimeSlotSchema

        avail_rows = await self.db.scalars(
            select(TeacherAvailability).where(TeacherAvailability.teacher_id == current_user.id)
        )
        day_list = []
        for avail in avail_rows.all():
            slots_rows = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
            )
            time_slots = [
                TimeSlotSchema(start_time=s.start_time, end_time=s.end_time)
                for s in slots_rows.all()
            ]
            day_list.append(DayAvailability(day_of_week=avail.day_of_week, time_slots=time_slots))

        return AvailabilityResponse(
            teacher_id=current_user.id,
            availabilities=day_list,
        )

    async def set_availability(
        self, data: AvailabilityCreate, current_user: Any
    ) -> AvailabilityResponse:
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

    async def get_weekly_schedule(
        self, current_user: Any, *, week_start: str | None = None
    ) -> WeeklyScheduleResponse:
        """Return the merged weekly schedule (availability + bookings)."""
        from datetime import date as date_type, timedelta

        from app.models.schedule import AvailabilityTimeSlot, LessonBooking, TeacherAvailability
        from app.schemas.schedule import SlotStatus

        ws = date_type.fromisoformat(week_start) if week_start else date_type.today()
        # Align to Monday
        ws = ws - timedelta(days=ws.weekday())
        week_end = ws + timedelta(days=6)

        # Load availability
        avail_rows = await self.db.scalars(
            select(TeacherAvailability).where(TeacherAvailability.teacher_id == current_user.id)
        )
        avail_by_day: dict[int, list[dict]] = {}
        for avail in avail_rows.all():
            slots_rows = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
            )
            avail_by_day[avail.day_of_week] = [
                {"start_time": s.start_time, "end_time": s.end_time, "type": "available"}
                for s in slots_rows.all()
            ]

        # Load bookings for this week
        bookings = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.teacher_id == current_user.id,
                LessonBooking.scheduled_date >= ws,
                LessonBooking.scheduled_date <= week_end,
            )
        )
        bookings_by_date: dict[str, list[dict]] = {}
        for b in bookings.all():
            date_str = b.scheduled_date.isoformat()
            bookings_by_date.setdefault(date_str, []).append({
                "start_time": b.scheduled_time,
                "duration": b.duration,
                "status": b.status.value if hasattr(b.status, "value") else b.status,
                "type": "booking",
            })

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

    async def get_available_slots(
        self, *, teacher_id: str, date: str, duration: int = 60
    ) -> SlotsResponse:
        """Compute available booking slots for a date."""
        from datetime import date as date_type, timedelta

        from app.models.schedule import AvailabilityTimeSlot, LessonBooking, TeacherAvailability
        from app.schemas.schedule import SlotStatus

        d = date_type.fromisoformat(date)
        day_of_week = d.weekday()  # 0=Monday

        # Resolve teacher_id (could be Teacher.id or User.id)
        user_id = await self._resolve_teacher_user_id(teacher_id)

        # Find availability for this day
        avail = await self.db.scalar(
            select(TeacherAvailability).where(
                TeacherAvailability.teacher_id == user_id,
                TeacherAvailability.day_of_week == day_of_week,
            )
        )
        if not avail:
            return SlotsResponse(date=d, slots=[])

        # Get time slots
        time_slots = await self.db.scalars(
            select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
        )

        # Get existing bookings for this date
        bookings = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.teacher_id == user_id,
                LessonBooking.scheduled_date == d,
                LessonBooking.status.in_(["pending", "approved"]),
            )
        )
        booked_times = {b.scheduled_time for b in bookings.all()}

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

                is_booked = slot_time in booked_times
                slots.append(SlotStatus(
                    start_time=slot_time,
                    end_time=slot_end_time,
                    status="booked" if is_booked else "available",
                ))
                current += 30  # 30-minute interval

        return SlotsResponse(date=d, slots=slots)

    # ------------------------------------------------------------------
    # Schedule exceptions
    # ------------------------------------------------------------------

    async def create_exception(
        self, data: ScheduleExceptionCreate, current_user: Any
    ) -> ScheduleExceptionResponse:
        """Add a schedule exception."""
        from app.models.schedule_ext import ScheduleException

        # Find teacher's first availability to link to (or use empty string)
        from app.models.schedule import TeacherAvailability
        avail = await self.db.scalar(
            select(TeacherAvailability).where(TeacherAvailability.teacher_id == current_user.id)
        )
        avail_id = avail.id if avail else ""

        exception = ScheduleException(
            teacher_availability_id=avail_id,
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

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(exception, key, value)
        await self.db.flush()
        await self.db.refresh(exception)
        return ScheduleExceptionResponse.model_validate(exception)

    async def delete_exception(self, exception_id: str, current_user: Any) -> None:
        """Delete a schedule exception."""
        from app.models.schedule_ext import ScheduleException

        exception = await self.db.get(ScheduleException, exception_id)
        if exception is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exception not found")
        await self.db.delete(exception)
        await self.db.flush()

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

        query = select(LessonBooking)
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
        items = [BookingResponse.model_validate(b) for b in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create_booking(self, data: BookingCreate, current_user: Any) -> BookingResponse:
        """Create a new booking request."""
        from app.models.schedule import LessonBooking

        booking = LessonBooking(
            teacher_id=data.teacher_id,
            student_id=current_user.id,
            lesson_type=data.lesson_type,
            scheduled_date=data.scheduled_date,
            scheduled_time=data.scheduled_time,
            duration=data.duration,
            instrument=data.instrument,
            notes=data.notes,
            status="pending",
        )
        self.db.add(booking)
        await self.db.flush()
        await self.db.refresh(booking)
        return BookingResponse.model_validate(booking)

    async def get_booking_by_id(self, booking_id: str, current_user: Any) -> BookingResponse:
        """Return a single booking."""
        from app.models.schedule import LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        return BookingResponse.model_validate(booking)

    async def approve_booking(self, booking_id: str, current_user: Any) -> BookingResponse:
        """Approve a pending booking."""
        from app.models.schedule import LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        booking.status = "approved"
        await self.db.flush()
        await self.db.refresh(booking)
        return BookingResponse.model_validate(booking)

    async def reject_booking(
        self, booking_id: str, reason: str | None, current_user: Any
    ) -> BookingResponse:
        """Reject a pending booking."""
        from app.models.schedule import LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        booking.status = "rejected"
        booking.reason = reason
        await self.db.flush()
        await self.db.refresh(booking)
        return BookingResponse.model_validate(booking)

    async def cancel_booking(
        self, booking_id: str, reason: str | None, current_user: Any
    ) -> BookingResponse:
        """Cancel a booking."""
        from app.models.schedule import LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        booking.status = "cancelled"
        booking.reason = reason
        await self.db.flush()
        await self.db.refresh(booking)
        return BookingResponse.model_validate(booking)

    async def change_booking(
        self, booking_id: str, data: BookingChangeRequest, current_user: Any
    ) -> BookingResponse:
        """Request a change to booking date/time."""
        from app.models.schedule import LessonBooking

        booking = await self.db.get(LessonBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        booking.scheduled_date = data.new_date
        booking.scheduled_time = data.new_time
        booking.status = "changeRequested"
        booking.reason = data.reason
        await self.db.flush()
        await self.db.refresh(booking)
        return BookingResponse.model_validate(booking)

    async def get_makeup_bookings(self, current_user: Any) -> list[BookingResponse]:
        """Return makeup lesson bookings."""
        from app.models.schedule import LessonBooking

        result = await self.db.scalars(
            select(LessonBooking).where(
                LessonBooking.lesson_type == "makeup",
                LessonBooking.teacher_id == current_user.id,
            )
        )
        return [BookingResponse.model_validate(b) for b in result.all()]

    async def create_makeup_booking(
        self, data: MakeupBookingCreate, current_user: Any
    ) -> BookingResponse:
        """Create a makeup lesson booking."""
        from app.models.schedule import LessonBooking

        booking = LessonBooking(
            teacher_id=current_user.id,
            student_id=data.student_id,
            lesson_type="makeup",
            scheduled_date=data.scheduled_date,
            scheduled_time=data.scheduled_time,
            status="approved",
            notes=data.reason,
        )
        self.db.add(booking)
        await self.db.flush()
        await self.db.refresh(booking)
        return BookingResponse.model_validate(booking)
