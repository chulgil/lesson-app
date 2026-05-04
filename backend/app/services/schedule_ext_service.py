"""Extended schedule service (exceptions, group schedules, no-show, changes)."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse


class ScheduleExtService:
    """Handle schedule exceptions, group class schedules/bookings, no-shows, changes."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # -----------------------------------------------------------------------
    # Schedule Exceptions
    # -----------------------------------------------------------------------

    async def get_exceptions(self, teacher_availability_id: str) -> list[Any]:
        from app.models.schedule_ext import ScheduleException

        result = await self.db.scalars(
            select(ScheduleException)
            .where(ScheduleException.teacher_availability_id == teacher_availability_id)
            .order_by(ScheduleException.start_date)
        )
        return list(result.all())

    async def create_exception(self, teacher_availability_id: str, data: dict) -> Any:
        from app.models.schedule_ext import ScheduleException

        exc = ScheduleException(
            teacher_availability_id=teacher_availability_id,
            **data,
        )
        self.db.add(exc)
        await self.db.flush()
        await self.db.refresh(exc)
        return exc

    async def update_exception(self, exception_id: str, data: dict) -> Any:
        from app.models.schedule_ext import ScheduleException

        exc = await self.db.get(ScheduleException, exception_id)
        if exc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exception not found")
        for key, value in data.items():
            if value is not None:
                setattr(exc, key, value)
        await self.db.flush()
        await self.db.refresh(exc)
        return exc

    async def delete_exception(self, exception_id: str) -> None:
        from app.models.schedule_ext import ScheduleException

        exc = await self.db.get(ScheduleException, exception_id)
        if exc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exception not found")
        await self.db.delete(exc)
        await self.db.flush()

    # -----------------------------------------------------------------------
    # Group Class Schedules
    # -----------------------------------------------------------------------

    async def get_group_schedules(
        self, group_class_id: str, *, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        from app.models.schedule_ext import GroupClassSchedule

        query = select(GroupClassSchedule).where(
            GroupClassSchedule.group_class_id == group_class_id
        )
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(GroupClassSchedule.start_time).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def create_group_schedule(self, data: dict) -> Any:
        from app.models.schedule_ext import GroupClassSchedule

        schedule = GroupClassSchedule(**data)
        self.db.add(schedule)
        await self.db.flush()
        await self.db.refresh(schedule)
        return schedule

    async def cancel_group_schedule(self, schedule_id: str, reason: str | None) -> Any:
        from app.models.schedule_ext import GroupClassSchedule, GroupScheduleStatus

        schedule = await self.db.get(GroupClassSchedule, schedule_id)
        if schedule is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Schedule not found")
        schedule.status = GroupScheduleStatus.cancelled
        schedule.cancel_reason = reason
        await self.db.flush()
        await self.db.refresh(schedule)
        return schedule

    # -----------------------------------------------------------------------
    # Group Class Bookings
    # -----------------------------------------------------------------------

    async def create_group_booking(self, data: dict) -> Any:
        from app.models.schedule_ext import GroupClassBooking, GroupClassSchedule, GroupScheduleStatus

        schedule = await self.db.get(GroupClassSchedule, data["schedule_id"])
        if schedule is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Schedule not found")

        if schedule.current_bookings >= schedule.max_capacity:
            if schedule.waitlist_capacity and schedule.waitlist_count < schedule.waitlist_capacity:
                booking = GroupClassBooking(
                    schedule_id=data["schedule_id"],
                    student_id=data["student_id"],
                    subscription_id=data.get("subscription_id"),
                    status="waitlist",
                    waitlist_position=schedule.waitlist_count + 1,
                )
                schedule.waitlist_count += 1
            else:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Class is full")
        else:
            booking = GroupClassBooking(
                schedule_id=data["schedule_id"],
                student_id=data["student_id"],
                subscription_id=data.get("subscription_id"),
                status="confirmed",
            )
            schedule.current_bookings += 1
            if schedule.current_bookings >= schedule.max_capacity:
                schedule.status = GroupScheduleStatus.full

        self.db.add(booking)
        await self.db.flush()
        await self.db.refresh(booking)
        return booking

    async def cancel_group_booking(self, booking_id: str, reason: str | None) -> Any:
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking, GroupClassSchedule, GroupScheduleStatus

        booking = await self.db.get(GroupClassBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")

        was_confirmed = booking.status == "confirmed"
        booking.status = GroupBookingStatus.cancelled
        booking.cancel_reason = reason
        booking.cancelled_at = datetime.now(UTC)

        if was_confirmed:
            schedule = await self.db.get(GroupClassSchedule, booking.schedule_id)
            if schedule:
                schedule.current_bookings = max(0, schedule.current_bookings - 1)
                if schedule.status == "full":
                    schedule.status = GroupScheduleStatus.open
                # Auto-promote from waitlist
                await self._promote_from_waitlist(booking.schedule_id)

        await self.db.flush()
        await self.db.refresh(booking)
        return booking

    async def _promote_from_waitlist(self, schedule_id: str) -> None:
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking, GroupClassSchedule

        waitlist = await self.db.scalars(
            select(GroupClassBooking)
            .where(
                GroupClassBooking.schedule_id == schedule_id,
                GroupClassBooking.status == "waitlist",
            )
            .order_by(GroupClassBooking.waitlist_position)
            .limit(1)
        )
        first = waitlist.first()
        if first:
            first.status = GroupBookingStatus.confirmed
            first.waitlist_position = None
            first.promoted_at = datetime.now(UTC)
            schedule = await self.db.get(GroupClassSchedule, schedule_id)
            if schedule:
                schedule.current_bookings += 1
                schedule.waitlist_count = max(0, schedule.waitlist_count - 1)

    async def mark_attendance(self, booking_id: str, attended: bool) -> Any:
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking

        booking = await self.db.get(GroupClassBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        booking.status = GroupBookingStatus.attended if attended else GroupBookingStatus.noShow
        if attended:
            booking.attended_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(booking)
        return booking

    async def get_bookings_for_schedule(self, schedule_id: str) -> list[Any]:
        from app.models.schedule_ext import GroupClassBooking

        result = await self.db.scalars(
            select(GroupClassBooking)
            .where(GroupClassBooking.schedule_id == schedule_id)
            .order_by(GroupClassBooking.created_at)
        )
        return list(result.all())

    async def list_bookings(
        self,
        *,
        schedule_id: str | None = None,
        student_id: str | None = None,
        status: str | None = None,
        active: bool | None = None,
        upcoming: bool | None = None,
    ) -> list[Any]:
        """List group bookings with flexible filters."""
        from app.models.schedule_ext import GroupClassBooking, GroupClassSchedule

        query = select(GroupClassBooking)
        if schedule_id:
            query = query.where(GroupClassBooking.schedule_id == schedule_id)
        if student_id:
            query = query.where(GroupClassBooking.student_id == student_id)
        if status:
            query = query.where(GroupClassBooking.status == status)
        if active:
            query = query.where(
                GroupClassBooking.status.in_(["confirmed", "attended"])
            )
        if upcoming:
            query = (
                query.join(
                    GroupClassSchedule,
                    GroupClassBooking.schedule_id == GroupClassSchedule.id,
                )
                .where(GroupClassSchedule.start_time > datetime.now(UTC))
                .where(GroupClassBooking.status.in_(["confirmed", "waitlist"]))
            )
        result = await self.db.scalars(query.order_by(GroupClassBooking.created_at))
        return list(result.all())

    async def get_booking_by_id(self, booking_id: str) -> Any:
        """Get a single group booking by ID."""
        from app.models.schedule_ext import GroupClassBooking

        booking = await self.db.get(GroupClassBooking, booking_id)
        if booking is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found"
            )
        return booking

    async def promote_from_waitlist_public(self, schedule_id: str) -> Any | None:
        """Promote next waitlisted booking (public API)."""
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking

        waitlist = await self.db.scalars(
            select(GroupClassBooking)
            .where(
                GroupClassBooking.schedule_id == schedule_id,
                GroupClassBooking.status == "waitlist",
            )
            .order_by(GroupClassBooking.waitlist_position)
            .limit(1)
        )
        first = waitlist.first()
        if first is None:
            return None
        first.status = GroupBookingStatus.confirmed
        first.waitlist_position = None
        first.promoted_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(first)
        return first

    async def auto_cancel_waitlist(self, schedule_id: str) -> list[Any]:
        """Cancel all waitlisted bookings for a schedule."""
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking

        result = await self.db.scalars(
            select(GroupClassBooking).where(
                GroupClassBooking.schedule_id == schedule_id,
                GroupClassBooking.status == "waitlist",
            )
        )
        cancelled = []
        for booking in result.all():
            booking.status = GroupBookingStatus.cancelled
            booking.cancel_reason = "auto_cancel_waitlist"
            booking.cancelled_at = datetime.now(UTC)
            cancelled.append(booking)
        await self.db.flush()
        for b in cancelled:
            await self.db.refresh(b)
        return cancelled

    async def batch_mark_attendance(self, attendance_list: list[dict]) -> list[Any]:
        """Mark attendance for multiple bookings at once."""
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking

        results = []
        for item in attendance_list:
            booking = await self.db.get(GroupClassBooking, item["booking_id"])
            if booking is None:
                continue
            attended = item.get("attended", True)
            booking.status = GroupBookingStatus.attended if attended else GroupBookingStatus.noShow
            if attended:
                booking.attended_at = datetime.now(UTC)
            results.append(booking)
        await self.db.flush()
        for b in results:
            await self.db.refresh(b)
        return results

    async def deduct_subscription(self, booking_id: str) -> Any:
        """Mark a booking's subscription as deducted."""
        from app.models.schedule_ext import GroupClassBooking

        booking = await self.db.get(GroupClassBooking, booking_id)
        if booking is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found"
            )
        booking.subscription_deducted = True
        await self.db.flush()
        await self.db.refresh(booking)
        return booking

    # -----------------------------------------------------------------------
    # No-Show Records
    # -----------------------------------------------------------------------

    async def create_no_show_record(self, data: dict, teacher_id: str) -> Any:
        from app.models.schedule_ext import NoShowRecord

        record = NoShowRecord(teacher_id=teacher_id, **data)
        self.db.add(record)
        await self.db.flush()
        await self.db.refresh(record)
        return record

    async def get_no_show_records(
        self, teacher_id: str, *, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        from app.models.schedule_ext import NoShowRecord

        query = select(NoShowRecord).where(NoShowRecord.teacher_id == teacher_id)
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(NoShowRecord.created_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    # -----------------------------------------------------------------------
    # Lesson Schedule Changes
    # -----------------------------------------------------------------------

    async def create_schedule_change(self, data: dict, teacher_id: str) -> Any:
        from app.models.schedule_ext import LessonScheduleChange

        change = LessonScheduleChange(teacher_id=teacher_id, **data)
        self.db.add(change)
        await self.db.flush()
        await self.db.refresh(change)
        return change

    async def respond_to_schedule_change(
        self, change_id: str, action: str, response_message: str | None
    ) -> Any:
        from app.models.schedule_ext import LessonScheduleChange, ScheduleChangeStatus

        change = await self.db.get(LessonScheduleChange, change_id)
        if change is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Change not found")
        change.status = ScheduleChangeStatus(action)
        change.response_message = response_message
        change.processed_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(change)
        return change

    async def get_pending_changes(
        self, teacher_id: str, *, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        from app.models.schedule_ext import LessonScheduleChange

        query = select(LessonScheduleChange).where(
            LessonScheduleChange.teacher_id == teacher_id,
            LessonScheduleChange.status == "pending",
        )
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(LessonScheduleChange.requested_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)
