"""Schedule endpoints: availability, weekly view, exceptions."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db
from app.models.user import User
from app.schemas.schedule import (
    AvailabilityCreate,
    AvailabilityResponse,
    ScheduleExceptionCreate,
    ScheduleExceptionResponse,
    ScheduleExceptionUpdate,
    WeeklyScheduleResponse,
)
from app.services.schedule_service import ScheduleService

router = APIRouter()


# ---------------------------------------------------------------------------
# Availability
# ---------------------------------------------------------------------------


@router.get(
    "/availability",
    response_model=AvailabilityResponse,
    status_code=status.HTTP_200_OK,
    summary="Get teacher availability",
)
async def get_availability(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> AvailabilityResponse:
    """Return weekly availability for the current teacher."""
    service = ScheduleService(db)
    return await service.get_availability(current_user)


@router.get(
    "/availability/{teacher_id}",
    response_model=AvailabilityResponse,
    status_code=status.HTTP_200_OK,
    summary="Get public teacher availability",
)
async def get_public_availability(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AvailabilityResponse:
    """Return weekly availability for a target teacher."""
    service = ScheduleService(db)
    return await service.get_availability_by_teacher_id(teacher_id)


@router.put(
    "/availability",
    response_model=AvailabilityResponse,
    status_code=status.HTTP_200_OK,
    summary="Set teacher availability",
)
async def set_availability(
    body: AvailabilityCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> AvailabilityResponse:
    """Replace the teacher's weekly availability."""
    service = ScheduleService(db)
    return await service.set_availability(body, current_user)


@router.delete(
    "/availability",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Clear teacher availability",
)
async def clear_availability(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Remove all weekly availability for the current teacher."""
    service = ScheduleService(db)
    await service.clear_availability(current_user)


# ---------------------------------------------------------------------------
# Weekly schedule & slots
# ---------------------------------------------------------------------------


@router.get(
    "/weekly",
    response_model=WeeklyScheduleResponse,
    status_code=status.HTTP_200_OK,
    summary="Weekly schedule view",
)
async def get_weekly_schedule(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    week_start: str | None = None,
) -> WeeklyScheduleResponse:
    """Return the merged weekly schedule (availability + bookings)."""
    service = ScheduleService(db)
    return await service.get_weekly_schedule(current_user, week_start=week_start)


@router.get(
    "/slots",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Available booking slots",
)
async def get_available_slots(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    date: str | None = None,
    date_from: str | None = None,
    date_to: str | None = None,
    duration: int = 60,
    limit: int | None = None,
    available_only: bool = False,
    student_id: str | None = None,
):
    """Return bookable slots or frontend-compatible availability shapes."""
    del current_user, student_id
    service = ScheduleService(db)
    if date is None and date_from is None:
        return await service.get_frontend_time_slots(teacher_id=teacher_id)
    if date_from is not None:
        return await service.get_available_slots_range(
            teacher_id=teacher_id,
            date_from=date_from,
            date_to=date_to,
            duration=duration,
            limit=limit,
            available_only=available_only,
        )
    return await service.get_available_slots(
        teacher_id=teacher_id,
        date=date,
        duration=duration,
    )


# ---------------------------------------------------------------------------
# Schedule exceptions
# ---------------------------------------------------------------------------


@router.post(
    "/exceptions",
    response_model=ScheduleExceptionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add schedule exception",
    operation_id="create_schedule_exception",
)
async def create_exception(
    body: ScheduleExceptionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> ScheduleExceptionResponse:
    """Add a schedule exception (holiday or extra opening)."""
    service = ScheduleService(db)
    return await service.create_exception(body, current_user)


@router.put(
    "/exceptions/{exception_id}",
    response_model=ScheduleExceptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Update schedule exception",
    operation_id="update_schedule_exception",
)
async def update_exception(
    exception_id: str,
    body: ScheduleExceptionUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> ScheduleExceptionResponse:
    """Update a schedule exception."""
    service = ScheduleService(db)
    return await service.update_exception(exception_id, body, current_user)


@router.delete(
    "/exceptions/{exception_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete schedule exception",
    operation_id="delete_schedule_exception",
)
async def delete_exception(
    exception_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Delete a schedule exception."""
    service = ScheduleService(db)
    await service.delete_exception(exception_id, current_user)
