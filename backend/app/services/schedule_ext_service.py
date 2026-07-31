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

    async def create_exception(self, teacher_availability_id: str, data: dict, current_user: Any) -> Any:
        from app.models.schedule import TeacherAvailability
        from app.models.schedule_ext import ScheduleException

        availability = await self.db.get(TeacherAvailability, teacher_availability_id)
        if availability is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Availability not found")
        current_teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        if availability.teacher_id not in current_teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        exc = ScheduleException(
            teacher_availability_id=teacher_availability_id,
            **data,
        )
        self.db.add(exc)
        await self.db.flush()
        await self.db.refresh(exc)
        return exc

    async def update_exception(self, exception_id: str, data: dict, current_user: Any | None = None) -> Any:
        from app.models.schedule_ext import ScheduleException

        exc = await self.db.get(ScheduleException, exception_id)
        if exc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exception not found")
        await self._assert_exception_owner(exc, current_user)
        for key, value in data.items():
            if value is not None:
                setattr(exc, key, value)
        await self.db.flush()
        await self.db.refresh(exc)
        return exc

    async def delete_exception(self, exception_id: str, current_user: Any | None = None) -> None:
        from app.models.schedule_ext import ScheduleException

        exc = await self.db.get(ScheduleException, exception_id)
        if exc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exception not found")
        await self._assert_exception_owner(exc, current_user)
        await self.db.delete(exc)
        await self.db.flush()

    async def _assert_exception_owner(self, exception: Any, current_user: Any | None) -> None:
        if current_user is None:
            return

        if getattr(exception, "teacher_id", None) is not None:
            current_teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
            if exception.teacher_id not in current_teacher_ids:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
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

    # -----------------------------------------------------------------------
    # Group ownership assertions — IDOR 방어용 헬퍼.
    # -----------------------------------------------------------------------

    async def _get_group_class(self, group_class_id: str) -> Any | None:
        """group_class_id → GroupClass row (정원·노쇼정책 SSOT). 없으면 None."""
        from app.models.schedule import GroupClass

        return await self.db.get(GroupClass, group_class_id)

    async def get_group_class_for_schedule(self, schedule_id: str) -> Any | None:
        """schedule → 소속 GroupClass. 정원·마감·노쇼정책 조회의 단일 진입점."""
        from app.models.schedule_ext import GroupClassSchedule

        schedule = await self.db.get(GroupClassSchedule, schedule_id)
        if schedule is None:
            return None
        return await self._get_group_class(schedule.group_class_id)

    async def _assert_group_class_teacher(self, group_class_id: str, current_user: Any) -> Any:
        """GroupClass.teacher_id 가 current_user 의 강사 ID 와 일치하는지 검증. row 반환."""
        group_class = await self._get_group_class(group_class_id)
        if group_class is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group class not found")
        teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        if group_class.teacher_id not in teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not the owning teacher")
        return group_class

    async def _assert_schedule_teacher(self, schedule_id: str, current_user: Any) -> Any:
        """GroupClassSchedule → GroupClass → teacher_id 검증. schedule row 반환."""
        from app.models.schedule_ext import GroupClassSchedule

        schedule = await self.db.get(GroupClassSchedule, schedule_id)
        if schedule is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Schedule not found")
        group_class = await self._get_group_class(schedule.group_class_id)
        teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        if group_class is None or group_class.teacher_id not in teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not the owning teacher")
        return schedule

    async def _assert_booking_actor(self, booking_id: str, current_user: Any) -> Any:
        """booking 의 schedule.group_class.teacher 또는 booking.student_id 본인만 허용.

        - 강사 모드: schedule → group_class → teacher_id 가 current_user 와 일치하면 OK.
        - 학생 모드: booking.student_id 가 current_user.id (또는 매핑된 student.id) 와 일치하면 OK.
        """
        from app.models.schedule_ext import GroupClassBooking, GroupClassSchedule

        booking = await self.db.get(GroupClassBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        # 강사 검증.
        schedule = await self.db.get(GroupClassSchedule, booking.schedule_id)
        if schedule is not None:
            group_class = await self._get_group_class(schedule.group_class_id)
            teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
            if group_class is not None and group_class.teacher_id in teacher_ids:
                return booking
        # 학생 검증 (자기 booking).
        if booking.student_id == current_user.id:
            return booking
        from app.models.student import Student

        student_profile_id = await self.db.scalar(select(Student.id).where(Student.user_id == current_user.id))
        if student_profile_id is not None and booking.student_id == student_profile_id:
            return booking
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized for this booking")

    # -----------------------------------------------------------------------
    # Group Class Schedules
    # -----------------------------------------------------------------------

    async def get_group_schedules(
        self,
        group_class_id: str,
        *,
        page: int,
        size: int,
        offset: int,
        current_user: Any,
    ) -> PaginatedResponse:
        from app.models.schedule_ext import GroupClassSchedule

        await self._assert_group_class_teacher(group_class_id, current_user)
        query = select(GroupClassSchedule).where(GroupClassSchedule.group_class_id == group_class_id)
        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0

        result = await self.db.scalars(query.order_by(GroupClassSchedule.start_time).offset(offset).limit(size))
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def create_group_schedule(self, data: dict, current_user: Any) -> Any:
        from app.models.schedule_ext import GroupClassSchedule

        # body 의 group_class_id 가 본인 클래스인지 검증 — IDOR write 차단.
        group_class_id = data.get("group_class_id")
        if not group_class_id:
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="group_class_id is required")
        group_class = await self._assert_group_class_teacher(group_class_id, current_user)
        # 정원 SSOT = GroupClass. 회차별 예외가 필요할 때만 명시값이 덮어쓴다.
        if data.get("max_capacity") is None:
            data["max_capacity"] = group_class.max_capacity
        if data.get("waitlist_capacity") is None:
            data["waitlist_capacity"] = group_class.waitlist_capacity
        schedule = GroupClassSchedule(**data)
        self.db.add(schedule)
        await self.db.flush()
        await self.db.refresh(schedule)
        return schedule

    async def cancel_group_schedule(self, schedule_id: str, reason: str | None, current_user: Any) -> Any:
        from app.models.schedule_ext import GroupScheduleStatus

        schedule = await self._assert_schedule_teacher(schedule_id, current_user)
        schedule.status = GroupScheduleStatus.cancelled
        schedule.cancel_reason = reason
        await self.db.flush()
        await self.db.refresh(schedule)
        return schedule

    # -----------------------------------------------------------------------
    # Group Class Bookings
    # -----------------------------------------------------------------------

    async def create_group_booking(self, data: dict, current_user: Any) -> Any:
        from app.models.schedule_ext import GroupClassBooking, GroupClassSchedule, GroupScheduleStatus
        from app.models.student import Student

        schedule = await self.db.get(GroupClassSchedule, data["schedule_id"])
        if schedule is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Schedule not found")
        # 호출자가 강사 본인 (해당 클래스 소유자) 이거나 학생 본인이어야 한다.
        group_class = await self._get_group_class(schedule.group_class_id)
        teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        is_owning_teacher = group_class is not None and group_class.teacher_id in teacher_ids
        student_profile_id = await self.db.scalar(select(Student.id).where(Student.user_id == current_user.id))
        is_self_student = (
            data.get("student_id") in {current_user.id, student_profile_id} if data.get("student_id") else False
        )
        if not (is_owning_teacher or is_self_student):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to create this booking")

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

    async def cancel_group_booking(self, booking_id: str, reason: str | None, current_user: Any) -> Any:
        from app.models.schedule_ext import (
            GroupBookingStatus,
            GroupClassSchedule,
            GroupScheduleStatus,
        )

        booking = await self._assert_booking_actor(booking_id, current_user)

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

    async def mark_attendance(self, booking_id: str, attended: bool, current_user: Any) -> Any:
        from app.models.schedule_ext import GroupBookingStatus

        # 출석 마킹은 강사 또는 학생 본인만. _assert_booking_actor 가 두 케이스 다 처리.
        booking = await self._assert_booking_actor(booking_id, current_user)
        booking.status = GroupBookingStatus.attended if attended else GroupBookingStatus.noShow
        if attended:
            booking.attended_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(booking)
        return booking

    async def get_bookings_for_schedule(self, schedule_id: str, current_user: Any) -> list[Any]:
        from app.models.schedule_ext import GroupClassBooking

        # schedule 소유 강사만 — 강사가 자기 클래스 출석부 조회.
        await self._assert_schedule_teacher(schedule_id, current_user)
        result = await self.db.scalars(
            select(GroupClassBooking)
            .where(GroupClassBooking.schedule_id == schedule_id)
            .order_by(GroupClassBooking.created_at)
        )
        return list(result.all())

    async def list_bookings(
        self,
        *,
        current_user: Any,
        schedule_id: str | None = None,
        student_id: str | None = None,
        status: str | None = None,
        active: bool | None = None,
        upcoming: bool | None = None,
    ) -> list[Any]:
        """List group bookings with flexible filters — caller 권한으로 자동 스코프."""
        from app.models.schedule import GroupClass
        from app.models.schedule_ext import GroupClassBooking, GroupClassSchedule
        from app.models.student import Student

        # 호출자 신원 — 강사면 자기 클래스의 booking 만, 학생이면 자기 booking 만.
        teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        student_profile_id = await self.db.scalar(select(Student.id).where(Student.user_id == current_user.id))

        query = (
            select(GroupClassBooking)
            .join(
                GroupClassSchedule,
                GroupClassBooking.schedule_id == GroupClassSchedule.id,
            )
            .join(GroupClass, GroupClassSchedule.group_class_id == GroupClass.id)
        )

        if student_profile_id is not None:
            # 학생 본인 booking 만 — 다른 student_id 필터는 무시 (silently scope 좁힘).
            query = query.where(GroupClassBooking.student_id == student_profile_id)
        else:
            # 강사: 본인 클래스 스코프 + (선택적) student_id 필터.
            query = query.where(GroupClass.teacher_id.in_(teacher_ids))
            if student_id:
                query = query.where(GroupClassBooking.student_id == student_id)

        if schedule_id:
            query = query.where(GroupClassBooking.schedule_id == schedule_id)
        if status:
            query = query.where(GroupClassBooking.status == status)
        if active:
            query = query.where(GroupClassBooking.status.in_(["confirmed", "attended"]))
        if upcoming:
            query = query.where(GroupClassSchedule.start_time > datetime.now(UTC)).where(
                GroupClassBooking.status.in_(["confirmed", "waitlist"])
            )
        result = await self.db.scalars(query.order_by(GroupClassBooking.created_at))
        return list(result.all())

    async def get_booking_by_id(self, booking_id: str, current_user: Any) -> Any:
        """Get a single group booking by ID — owner 만 조회 가능."""
        return await self._assert_booking_actor(booking_id, current_user)

    async def _get_booking_raw(self, booking_id: str) -> Any:
        """Internal: raw get without ownership check (사용 시 caller 가 검증해야 함)."""
        from app.models.schedule_ext import GroupClassBooking

        booking = await self.db.get(GroupClassBooking, booking_id)
        if booking is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        return booking

    async def promote_from_waitlist_public(self, schedule_id: str, current_user: Any) -> Any | None:
        """Promote next waitlisted booking (public API) — schedule 소유 강사만."""
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking

        await self._assert_schedule_teacher(schedule_id, current_user)
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

    async def auto_cancel_waitlist(self, schedule_id: str, current_user: Any) -> list[Any]:
        """Cancel all waitlisted bookings for a schedule — schedule 소유 강사만."""
        from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking

        await self._assert_schedule_teacher(schedule_id, current_user)
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

    async def batch_mark_attendance(self, attendance_list: list[dict], current_user: Any) -> list[Any]:
        """Mark attendance for multiple bookings at once — 각 booking 소유 강사만."""
        from app.models.schedule_ext import GroupBookingStatus

        results = []
        for item in attendance_list:
            # 각 booking 마다 강사 ownership 검증 — cross-tenant 일괄 변경 차단.
            booking = await self._assert_booking_actor(item["booking_id"], current_user)
            attended = item.get("attended", True)
            booking.status = GroupBookingStatus.attended if attended else GroupBookingStatus.noShow
            if attended:
                booking.attended_at = datetime.now(UTC)
            results.append(booking)
        await self.db.flush()
        for b in results:
            await self.db.refresh(b)
        return results

    async def deduct_subscription(self, booking_id: str, current_user: Any) -> Any:
        """Mark a booking's subscription as deducted — booking 소유 강사만."""
        booking = await self._assert_booking_actor(booking_id, current_user)
        booking.subscription_deducted = True
        await self.db.flush()
        await self.db.refresh(booking)
        return booking

    # -----------------------------------------------------------------------
    # No-Show Records
    # -----------------------------------------------------------------------

    async def create_no_show_record(self, data: dict, current_user: Any) -> Any:
        from app.models.schedule_ext import NoShowRecord

        teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        # body 의 teacher_id 는 무시하고 caller 의 강사 ID 를 강제로 사용한다 (IDOR 차단).
        canonical_teacher_id = teacher_ids[0]
        # body 의 student_id 가 본인 학생인지 검증.
        student_id = data.get("student_id")
        if student_id:
            from app.models.student import Student

            student_teacher_id = await self.db.scalar(select(Student.teacher_id).where(Student.id == student_id))
            if student_teacher_id is None or student_teacher_id not in teacher_ids:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your student")
        clean_data = {k: v for k, v in data.items() if k not in {"teacher_id"}}
        record = NoShowRecord(teacher_id=canonical_teacher_id, **clean_data)
        self.db.add(record)
        await self.db.flush()
        await self.db.refresh(record)
        return record

    async def get_no_show_records(self, teacher_id: str, *, page: int, size: int, offset: int) -> PaginatedResponse:
        from app.models.schedule_ext import NoShowRecord

        query = select(NoShowRecord).where(NoShowRecord.teacher_id == teacher_id)
        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0

        result = await self.db.scalars(query.order_by(NoShowRecord.created_at.desc()).offset(offset).limit(size))
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
        self, change_id: str, action: str, response_message: str | None, current_user: Any
    ) -> Any:
        from app.models.schedule_ext import LessonScheduleChange, ScheduleChangeStatus

        change = await self.db.get(LessonScheduleChange, change_id)
        if change is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Change not found")
        current_teacher_ids = await self._resolve_teacher_id_scope(current_user.id)
        if change.teacher_id not in current_teacher_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        change.status = ScheduleChangeStatus(action)
        change.response_message = response_message
        change.processed_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(change)
        return change

    async def get_pending_changes(self, teacher_id: str, *, page: int, size: int, offset: int) -> PaginatedResponse:
        from app.models.schedule_ext import LessonScheduleChange

        query = select(LessonScheduleChange).where(
            LessonScheduleChange.teacher_id == teacher_id,
            LessonScheduleChange.status == "pending",
        )
        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0

        result = await self.db.scalars(
            query.order_by(LessonScheduleChange.requested_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)
