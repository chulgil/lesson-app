"""Booking endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.schedule import (  # noqa: F401  BookingApproveRequest 는 string annotation 으로 사용.
    BookingApproveRequest,
    BookingCancelRequest,
    BookingChangeRequest,
    BookingCreate,
    BookingRejectRequest,
    BookingResponse,
    BookingUpdate,
    MakeupBookingCreate,
    SlotStatus,
)
from app.services.schedule_service import ScheduleService

router = APIRouter()


@router.get(
    "",
    response_model=PaginatedResponse[BookingResponse],
    status_code=status.HTTP_200_OK,
    summary="List bookings",
)
async def list_bookings(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    teacher_id: str | None = None,
    student_id: str | None = None,
    booking_status: Annotated[str | None, Query(alias="status")] = None,
    date_from: str | None = None,
    date_to: str | None = None,
) -> PaginatedResponse[BookingResponse]:
    """List bookings with optional filters."""
    service = ScheduleService(db)
    return await service.get_all_bookings(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        teacher_id=teacher_id,
        student_id=student_id,
        status=booking_status,
        date_from=date_from,
        date_to=date_to,
    )


@router.post(
    "",
    response_model=BookingResponse | SlotStatus,
    status_code=status.HTTP_201_CREATED,
    summary="Request a booking",
)
async def create_booking(
    body: BookingCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> BookingResponse | SlotStatus:
    """Create a new booking request."""
    service = ScheduleService(db)
    if body.slot_id:
        return await service.create_slot_booking(body, current_user)
    return await service.create_booking(body, current_user)


@router.get(
    "/makeup",
    response_model=list[BookingResponse],
    status_code=status.HTTP_200_OK,
    summary="List makeup lessons",
)
async def list_makeup_bookings(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[BookingResponse]:
    """Return all makeup lesson bookings."""
    service = ScheduleService(db)
    return await service.get_makeup_bookings(current_user)


@router.post(
    "/makeup",
    response_model=BookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create makeup lesson",
)
async def create_makeup_booking(
    body: MakeupBookingCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> BookingResponse:
    """Create a makeup lesson booking."""
    service = ScheduleService(db)
    return await service.create_makeup_booking(body, current_user)


@router.get(
    "/{booking_id}",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get booking detail",
)
async def get_booking(
    booking_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> BookingResponse:
    """Return a single booking."""
    service = ScheduleService(db)
    return await service.get_booking_by_id(booking_id, current_user)


@router.put(
    "/{booking_id}",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Update booking",
)
async def update_booking(
    booking_id: str,
    body: BookingUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> BookingResponse:
    """Update a booking."""
    service = ScheduleService(db)
    return await service.update_booking(booking_id, body, current_user)


@router.delete(
    "/{booking_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete booking",
)
async def delete_booking(
    booking_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a booking."""
    service = ScheduleService(db)
    await service.delete_booking(booking_id, current_user)


@router.patch(
    "/{booking_id}/approve",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Approve booking (teacher only)",
)
async def approve_booking(
    booking_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    body: BookingApproveRequest | None = None,
) -> BookingResponse:
    """Approve a pending booking.

    FE 호환 — body 에 status='completed' 또는 selected_option_id 옵션.
    body 가 없으면 기존 동작 (confirmed).
    """
    service = ScheduleService(db)
    return await service.approve_booking(
        booking_id,
        current_user,
        selected_option_id=body.selected_option_id if body else None,
        target_status=body.status if body else None,
    )


@router.patch(
    "/{booking_id}/reject",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Reject booking (teacher only)",
)
async def reject_booking(
    booking_id: str,
    body: BookingRejectRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> BookingResponse:
    """Reject a pending booking."""
    service = ScheduleService(db)
    return await service.reject_booking(booking_id, body.reason, current_user)


@router.patch(
    "/{booking_id}/cancel",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel booking",
)
async def cancel_booking(
    booking_id: str,
    body: BookingCancelRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> BookingResponse:
    """Cancel a booking (either party)."""
    service = ScheduleService(db)
    return await service.cancel_booking(booking_id, body.reason, current_user)


@router.post(
    "/{booking_id}/change-request",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Request date/time change",
)
async def change_request(
    booking_id: str,
    body: BookingChangeRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> BookingResponse:
    """Request a change to booking date/time."""
    service = ScheduleService(db)
    return await service.change_booking(booking_id, body, current_user)
