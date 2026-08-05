"""Group class schedule and booking endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.schedule_ext import (
    AttendanceMarkRequest,
    BatchAttendanceRequest,
    GroupBookingActionRequest,
    GroupClassBookingCreate,
    GroupClassBookingResponse,
    GroupClassCreate,
    GroupClassResponse,
    GroupClassScheduleCreate,
    GroupClassScheduleResponse,
    GroupClassUpdate,
    NoShowRecordCreate,
    NoShowRecordResponse,
)
from app.services.schedule_ext_service import ScheduleExtService

router = APIRouter()


# ---------------------------------------------------------------------------
# Group Class definitions
#
# `/groups/classes` — 리터럴 경로가 `/{group_class_id}/schedules` 보다 먼저
# 매칭되도록 파일 앞쪽에 선언한다.
# ---------------------------------------------------------------------------


@router.post(
    "/classes",
    response_model=GroupClassResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a group class",
)
async def create_group_class(
    body: GroupClassCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GroupClassResponse:
    service = ScheduleExtService(db)
    return await service.create_group_class(body.model_dump(), current_user)


@router.get(
    "/classes",
    response_model=PaginatedResponse[GroupClassResponse],
    status_code=status.HTTP_200_OK,
    summary="List group classes",
)
async def list_group_classes(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    teacher_id: str | None = None,
    include_inactive: str | None = None,
) -> PaginatedResponse[GroupClassResponse]:
    service = ScheduleExtService(db)
    return await service.list_group_classes(
        teacher_id=teacher_id,
        include_inactive=include_inactive == "true",
        current_user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.get(
    "/classes/{group_class_id}",
    response_model=GroupClassResponse,
    status_code=status.HTTP_200_OK,
    summary="Get a group class by ID",
)
async def get_group_class(
    group_class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> GroupClassResponse:
    service = ScheduleExtService(db)
    return await service.get_group_class(group_class_id)


@router.patch(
    "/classes/{group_class_id}",
    response_model=GroupClassResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a group class",
)
async def update_group_class(
    group_class_id: str,
    body: GroupClassUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GroupClassResponse:
    service = ScheduleExtService(db)
    return await service.update_group_class(
        group_class_id,
        body.model_dump(exclude_unset=True),
        current_user,
    )


@router.delete(
    "/classes/{group_class_id}",
    response_model=GroupClassResponse,
    status_code=status.HTTP_200_OK,
    summary="Deactivate a group class",
)
async def deactivate_group_class(
    group_class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GroupClassResponse:
    service = ScheduleExtService(db)
    return await service.deactivate_group_class(group_class_id, current_user)


# ---------------------------------------------------------------------------
# Group Class Schedules
# ---------------------------------------------------------------------------


@router.get(
    "/{group_class_id}/schedules",
    response_model=PaginatedResponse[GroupClassScheduleResponse],
    status_code=status.HTTP_200_OK,
    summary="List schedules for a group class",
)
async def list_group_schedules(
    group_class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[GroupClassScheduleResponse]:
    service = ScheduleExtService(db)
    return await service.get_group_schedules(
        group_class_id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        current_user=current_user,
    )


@router.post(
    "/schedules",
    response_model=GroupClassScheduleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create group class schedule",
)
async def create_group_schedule(
    body: GroupClassScheduleCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GroupClassScheduleResponse:
    service = ScheduleExtService(db)
    result: GroupClassScheduleResponse = await service.create_group_schedule(body.model_dump(), current_user)
    return result


@router.patch(
    "/schedules/{schedule_id}/cancel",
    response_model=GroupClassScheduleResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel a group class schedule",
)
async def cancel_group_schedule(
    schedule_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    reason: str | None = None,
) -> GroupClassScheduleResponse:
    service = ScheduleExtService(db)
    result: GroupClassScheduleResponse = await service.cancel_group_schedule(schedule_id, reason, current_user)
    return result


# ---------------------------------------------------------------------------
# Group Class Bookings
# ---------------------------------------------------------------------------


@router.get(
    "/bookings",
    response_model=PaginatedResponse[GroupClassBookingResponse],
    status_code=status.HTTP_200_OK,
    summary="List group bookings with filters",
)
async def list_group_bookings(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    schedule_id: str | None = None,
    student_id: str | None = None,
    booking_status: str | None = Query(None, alias="status"),
    active: str | None = None,
    upcoming: str | None = None,
) -> PaginatedResponse[GroupClassBookingResponse]:
    service = ScheduleExtService(db)
    bookings = await service.list_bookings(
        current_user=current_user,
        schedule_id=schedule_id,
        student_id=student_id,
        status=booking_status,
        active=active == "true" if active else None,
        upcoming=upcoming == "true" if upcoming else None,
    )
    items = [GroupClassBookingResponse.model_validate(booking) for booking in bookings]
    return PaginatedResponse.create(
        items=items,
        total=len(items),
        page=pagination["page"],
        size=pagination["size"],
    )


@router.get(
    "/bookings/{booking_id}",
    response_model=GroupClassBookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get a group booking by ID",
)
async def get_group_booking(
    booking_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> GroupClassBookingResponse:
    service = ScheduleExtService(db)
    result: GroupClassBookingResponse = await service.get_booking_by_id(booking_id, current_user)
    return result


@router.post(
    "/bookings",
    response_model=GroupClassBookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Book a group class session",
)
async def create_group_booking(
    body: GroupClassBookingCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> GroupClassBookingResponse:
    service = ScheduleExtService(db)
    result: GroupClassBookingResponse = await service.create_group_booking(body.model_dump(), current_user)
    return result


@router.patch(
    "/bookings/{booking_id}/cancel",
    response_model=GroupClassBookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel a group booking",
)
async def cancel_group_booking(
    booking_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    reason: str | None = None,
) -> GroupClassBookingResponse:
    service = ScheduleExtService(db)
    result: GroupClassBookingResponse = await service.cancel_group_booking(booking_id, reason, current_user)
    return result


@router.patch(
    "/bookings/{booking_id}/attendance",
    response_model=GroupClassBookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark attendance",
)
async def mark_attendance(
    booking_id: str,
    body: AttendanceMarkRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GroupClassBookingResponse:
    service = ScheduleExtService(db)
    result: GroupClassBookingResponse = await service.mark_attendance(booking_id, body.attended, current_user)
    return result


@router.get(
    "/schedules/{schedule_id}/bookings",
    response_model=list[GroupClassBookingResponse],
    status_code=status.HTTP_200_OK,
    summary="List bookings for a schedule",
)
async def list_schedule_bookings(
    schedule_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[GroupClassBookingResponse]:
    service = ScheduleExtService(db)
    return await service.get_bookings_for_schedule(schedule_id, current_user)


@router.post(
    "/bookings/promote",
    response_model=GroupClassBookingResponse | None,
    status_code=status.HTTP_200_OK,
    summary="Promote next waitlisted booking",
)
async def promote_from_waitlist(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    body: GroupBookingActionRequest | None = None,
    schedule_id: str | None = Query(None),
) -> GroupClassBookingResponse | None:
    service = ScheduleExtService(db)
    target_schedule_id = body.schedule_id if body is not None else schedule_id
    return await service.promote_from_waitlist_public(target_schedule_id or "", current_user)


@router.post(
    "/bookings/auto-cancel-waitlist",
    response_model=list[GroupClassBookingResponse],
    status_code=status.HTTP_200_OK,
    summary="Auto-cancel expired waitlist entries",
)
async def auto_cancel_waitlist(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    body: GroupBookingActionRequest | None = None,
    schedule_id: str | None = Query(None),
) -> list[GroupClassBookingResponse]:
    service = ScheduleExtService(db)
    target_schedule_id = body.schedule_id if body is not None else schedule_id
    return await service.auto_cancel_waitlist(target_schedule_id or "", current_user)


@router.post(
    "/bookings/batch-attendance",
    response_model=list[GroupClassBookingResponse],
    status_code=status.HTTP_200_OK,
    summary="Mark attendance for multiple bookings",
)
async def batch_attendance(
    body: BatchAttendanceRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> list[GroupClassBookingResponse]:
    service = ScheduleExtService(db)
    return await service.batch_mark_attendance(body.bookings, current_user)


@router.patch(
    "/bookings/{booking_id}/deduct",
    response_model=GroupClassBookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Deduct subscription credit for a booking",
)
async def deduct_subscription(
    booking_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GroupClassBookingResponse:
    service = ScheduleExtService(db)
    result: GroupClassBookingResponse = await service.deduct_subscription(booking_id, current_user)
    return result


# ---------------------------------------------------------------------------
# No-Show Records
# ---------------------------------------------------------------------------


@router.post(
    "/no-shows",
    response_model=NoShowRecordResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record a no-show",
)
async def create_no_show(
    body: NoShowRecordCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> NoShowRecordResponse:
    service = ScheduleExtService(db)
    result: NoShowRecordResponse = await service.create_no_show_record(body.model_dump(), current_user)
    return result


@router.get(
    "/no-shows",
    response_model=PaginatedResponse[NoShowRecordResponse],
    status_code=status.HTTP_200_OK,
    summary="List no-show records",
)
async def list_no_shows(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[NoShowRecordResponse]:
    service = ScheduleExtService(db)
    return await service.get_no_show_records(
        current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )
