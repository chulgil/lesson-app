"""Teacher availability service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.availability import (
    TeacherAvailabilityCreate,
    TeacherAvailabilityResponse,
    TeacherAvailabilityUpdate,
    TimeSlotCreate,
    TimeSlotResponse,
)


def _slot_minutes(value: str) -> int:
    """Parse HH:MM into minutes since midnight."""
    hour_str, minute_str = value.split(":")
    return int(hour_str) * 60 + int(minute_str)


def _slots_overlap(start_a: int, end_a: int, start_b: int, end_b: int) -> bool:
    """Return True when two half-open intervals overlap."""
    return start_a < end_b and end_a > start_b


class AvailabilityService:
    """Handle teacher availability and time slots."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Availability CRUD
    # ------------------------------------------------------------------

    async def get_by_teacher(self, teacher_id: str) -> list[TeacherAvailabilityResponse]:
        """Return all availability records for a teacher, with time slots."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        avail_rows = await self.db.scalars(
            select(TeacherAvailability)
            .where(TeacherAvailability.teacher_id == teacher_id)
            .order_by(TeacherAvailability.day_of_week)
        )
        results: list[TeacherAvailabilityResponse] = []
        for avail in avail_rows.all():
            slot_rows = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
            )
            slots = [TimeSlotResponse.model_validate(s) for s in slot_rows.all()]
            results.append(
                TeacherAvailabilityResponse(
                    id=avail.id,
                    teacher_id=avail.teacher_id,
                    day_of_week=avail.day_of_week,
                    time_slots=slots,
                    vacation_mode=avail.vacation_mode,
                    vacation_start_date=avail.vacation_start_date,
                    vacation_end_date=avail.vacation_end_date,
                    vacation_reason=avail.vacation_reason,
                    created_at=avail.created_at,
                    updated_at=avail.updated_at,
                )
            )
        return results

    async def create_or_update(self, teacher_id: str, data: TeacherAvailabilityCreate) -> TeacherAvailabilityResponse:
        """Create availability for a day, or update if it already exists."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        # Check existing availability for the same day
        existing = await self.db.scalar(
            select(TeacherAvailability).where(
                TeacherAvailability.teacher_id == teacher_id,
                TeacherAvailability.day_of_week == data.day_of_week,
            )
        )

        if existing:
            # Replace time slots
            old_slots = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == existing.id)
            )
            for old_slot in old_slots.all():
                await self.db.delete(old_slot)

            avail = existing
        else:
            avail = TeacherAvailability(
                teacher_id=teacher_id,
                day_of_week=data.day_of_week,
                vacation_mode=data.vacation_mode,
                vacation_start_date=data.vacation_start_date,
                vacation_end_date=data.vacation_end_date,
                vacation_reason=data.vacation_reason,
            )
            self.db.add(avail)
            await self.db.flush()

        # Create new time slots
        new_slots: list[TimeSlotResponse] = []
        for ts in data.time_slots:
            slot = AvailabilityTimeSlot(
                availability_id=avail.id,
                start_time=ts.start_time,
                end_time=ts.end_time,
                is_available=ts.is_available,
            )
            self.db.add(slot)
            await self.db.flush()
            await self.db.refresh(slot)
            new_slots.append(TimeSlotResponse.model_validate(slot))

        await self.db.refresh(avail)
        return TeacherAvailabilityResponse(
            id=avail.id,
            teacher_id=avail.teacher_id,
            day_of_week=avail.day_of_week,
            time_slots=new_slots,
            vacation_mode=avail.vacation_mode,
            vacation_start_date=avail.vacation_start_date,
            vacation_end_date=avail.vacation_end_date,
            vacation_reason=avail.vacation_reason,
            created_at=avail.created_at,
            updated_at=avail.updated_at,
        )

    async def update(
        self,
        availability_id: str,
        data: TeacherAvailabilityUpdate,
        current_user: Any | None = None,
    ) -> TeacherAvailabilityResponse:
        """Update an existing availability record."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        avail = await self.db.get(TeacherAvailability, availability_id)
        if avail is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Availability not found",
            )
        await self._assert_availability_owner(avail, current_user)

        if data.day_of_week is not None:
            avail.day_of_week = data.day_of_week

        # Update vacation mode fields if provided
        if data.vacation_mode is not None:
            avail.vacation_mode = data.vacation_mode
        if data.vacation_start_date is not None:
            avail.vacation_start_date = data.vacation_start_date
        if data.vacation_end_date is not None:
            avail.vacation_end_date = data.vacation_end_date
        if data.vacation_reason is not None:
            avail.vacation_reason = data.vacation_reason

        # Replace time slots if provided
        if data.time_slots is not None:
            self._assert_non_overlapping_slots(data.time_slots)
            old_slots = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == availability_id)
            )
            for old_slot in old_slots.all():
                await self.db.delete(old_slot)

            new_slots: list[TimeSlotResponse] = []
            for ts in data.time_slots:
                slot = AvailabilityTimeSlot(
                    availability_id=availability_id,
                    start_time=ts.start_time,
                    end_time=ts.end_time,
                    is_available=ts.is_available,
                )
                self.db.add(slot)
                await self.db.flush()
                await self.db.refresh(slot)
                new_slots.append(TimeSlotResponse.model_validate(slot))
        else:
            slot_rows = await self.db.scalars(
                select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == availability_id)
            )
            new_slots = [TimeSlotResponse.model_validate(s) for s in slot_rows.all()]

        await self.db.flush()
        await self.db.refresh(avail)
        return TeacherAvailabilityResponse(
            id=avail.id,
            teacher_id=avail.teacher_id,
            day_of_week=avail.day_of_week,
            time_slots=new_slots,
            vacation_mode=avail.vacation_mode,
            vacation_start_date=avail.vacation_start_date,
            vacation_end_date=avail.vacation_end_date,
            vacation_reason=avail.vacation_reason,
            created_at=avail.created_at,
            updated_at=avail.updated_at,
        )

    async def delete(self, availability_id: str, current_user: Any | None = None) -> None:
        """Delete an availability record and its time slots."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        avail = await self.db.get(TeacherAvailability, availability_id)
        if avail is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Availability not found",
            )
        await self._assert_availability_owner(avail, current_user)

        # Delete associated time slots
        old_slots = await self.db.scalars(
            select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == availability_id)
        )
        for slot in old_slots.all():
            await self.db.delete(slot)

        await self.db.delete(avail)
        await self.db.flush()

    # ------------------------------------------------------------------
    # Time Slot CRUD
    # ------------------------------------------------------------------

    async def add_time_slot(
        self,
        availability_id: str,
        data: TimeSlotCreate,
        current_user: Any | None = None,
    ) -> TimeSlotResponse:
        """Add a single time slot to an existing availability record."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        avail = await self.db.get(TeacherAvailability, availability_id)
        if avail is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Availability not found",
            )
        await self._assert_availability_owner(avail, current_user)
        await self._assert_slot_conflicts(availability_id, data.start_time, data.end_time)

        slot = AvailabilityTimeSlot(
            availability_id=availability_id,
            start_time=data.start_time,
            end_time=data.end_time,
            is_available=data.is_available,
        )
        self.db.add(slot)
        await self.db.flush()
        await self.db.refresh(slot)
        return TimeSlotResponse.model_validate(slot)

    async def remove_time_slot(self, slot_id: str, current_user: Any | None = None) -> None:
        """Remove a single time slot by ID."""
        from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability

        slot = await self.db.get(AvailabilityTimeSlot, slot_id)
        if slot is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Time slot not found",
            )
        avail = await self.db.get(TeacherAvailability, slot.availability_id)
        if avail is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Availability not found",
            )
        await self._assert_availability_owner(avail, current_user)
        await self.db.delete(slot)
        await self.db.flush()

    async def _assert_availability_owner(self, availability: Any, current_user: Any | None) -> None:
        if current_user is None:
            return

        from app.services.teacher_id_resolver import try_resolve_teacher_id

        identifiers = [current_user.id]
        teacher_profile_id = await try_resolve_teacher_id(self.db, current_user.id)
        if teacher_profile_id is not None:
            identifiers.append(teacher_profile_id)
        if availability.teacher_id not in identifiers:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _assert_slot_conflicts(
        self,
        availability_id: str,
        start_time: str,
        end_time: str,
    ) -> None:
        """Ensure the candidate slot does not overlap existing slots."""
        from app.models.schedule import AvailabilityTimeSlot

        new_start = _slot_minutes(start_time)
        new_end = _slot_minutes(end_time)
        if new_start >= new_end:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="end_time must be after start_time",
            )

        existing = await self.db.scalars(
            select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == availability_id)
        )
        for slot in existing:
            if _slots_overlap(
                new_start,
                new_end,
                _slot_minutes(slot.start_time),
                _slot_minutes(slot.end_time),
            ):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="time_slots for a day must not overlap",
                )

    @staticmethod
    def _assert_non_overlapping_slots(time_slots: list[TimeSlotCreate]) -> None:
        """Validate a replacement slot list does not contain overlaps."""
        normalized = sorted((_slot_minutes(slot.start_time), _slot_minutes(slot.end_time)) for slot in time_slots)
        for previous, current in zip(normalized, normalized[1:]):
            if previous[1] > current[0]:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="time_slots for a day must not overlap",
                )

    @staticmethod
    def is_slot_in_vacation(slot_date: date, availability: Any) -> bool:
        """Check if a slot date falls within vacation period.

        Args:
            slot_date: The date of the slot (inclusive comparison)
            availability: TeacherAvailability model instance

        Returns:
            True if vacation_mode is active and slot_date is within [start, end] (inclusive)
        """
        if not availability.vacation_mode:
            return False
        if availability.vacation_start_date is None or availability.vacation_end_date is None:
            return False
        return availability.vacation_start_date <= slot_date <= availability.vacation_end_date
