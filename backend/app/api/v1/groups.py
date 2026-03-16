"""Group class schedule and booking endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.schedule_ext import (
    AttendanceMarkRequest,
    GroupClassBookingCreate,
    GroupClassBookingResponse,
    GroupClassScheduleCreate,
    GroupClassScheduleResponse,
    NoShowRecordCreate,
    NoShowRecordResponse,
)
from app.services.schedule_ext_service import ScheduleExtService

router = APIRouter()


# ---------------------------------------------------------------------------
# Group Class Schedules
# ---------------------------------------------------------------------------


@router.get(
    "/{group_class_id}/schedules",
    response_model=PaginatedResponse[GroupClassScheduleResponse],
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
    return await service.create_group_schedule(body.model_dump())


@router.patch(
    "/schedules/{schedule_id}/cancel",
    response_model=GroupClassScheduleResponse,
    summary="Cancel a group class schedule",
)
async def cancel_group_schedule(
    schedule_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    reason: str | None = None,
) -> GroupClassScheduleResponse:
    service = ScheduleExtService(db)
    return await service.cancel_group_schedule(schedule_id, reason)


# ---------------------------------------------------------------------------
# Group Class Bookings
# ---------------------------------------------------------------------------


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
    return await service.create_group_booking(body.model_dump())


@router.patch(
    "/bookings/{booking_id}/cancel",
    response_model=GroupClassBookingResponse,
    summary="Cancel a group booking",
)
async def cancel_group_booking(
    booking_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    reason: str | None = None,
) -> GroupClassBookingResponse:
    service = ScheduleExtService(db)
    return await service.cancel_group_booking(booking_id, reason)


@router.patch(
    "/bookings/{booking_id}/attendance",
    response_model=GroupClassBookingResponse,
    summary="Mark attendance",
)
async def mark_attendance(
    booking_id: str,
    body: AttendanceMarkRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GroupClassBookingResponse:
    service = ScheduleExtService(db)
    return await service.mark_attendance(booking_id, body.attended)


@router.get(
    "/schedules/{schedule_id}/bookings",
    response_model=list[GroupClassBookingResponse],
    summary="List bookings for a schedule",
)
async def list_schedule_bookings(
    schedule_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[GroupClassBookingResponse]:
    service = ScheduleExtService(db)
    return await service.get_bookings_for_schedule(schedule_id)


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
    return await service.create_no_show_record(body.model_dump(), current_user.id)


@router.get(
    "/no-shows",
    response_model=PaginatedResponse[NoShowRecordResponse],
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
