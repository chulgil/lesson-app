"""Teacher availability endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.availability import (
    TeacherAvailabilityCreate,
    TeacherAvailabilityResponse,
    TeacherAvailabilityUpdate,
    TimeSlotCreate,
    TimeSlotResponse,
)
from app.services.availability_service import AvailabilityService
from app.services.teacher_id_resolver import resolve_teacher_id

router = APIRouter()


@router.get(
    "/",
    response_model=list[TeacherAvailabilityResponse],
    status_code=status.HTTP_200_OK,
    summary="List teacher availability",
)
async def list_availability(
    teacher_id: Annotated[str, Query(description="Teacher ID")],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[TeacherAvailabilityResponse]:
    service = AvailabilityService(db)
    return await service.get_by_teacher(teacher_id)


@router.post(
    "/",
    response_model=TeacherAvailabilityResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create or update teacher availability for a day",
)
async def create_availability(
    body: TeacherAvailabilityCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherAvailabilityResponse:
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = AvailabilityService(db)
    return await service.create_or_update(teacher_id, body)


@router.put(
    "/{availability_id}",
    response_model=TeacherAvailabilityResponse,
    status_code=status.HTTP_200_OK,
    summary="Update teacher availability",
)
async def update_availability(
    availability_id: str,
    body: TeacherAvailabilityUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherAvailabilityResponse:
    service = AvailabilityService(db)
    return await service.update(availability_id, body, current_user)


@router.delete(
    "/{availability_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete teacher availability",
)
async def delete_availability(
    availability_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    service = AvailabilityService(db)
    await service.delete(availability_id, current_user)


@router.post(
    "/{availability_id}/slots",
    response_model=TimeSlotResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add a time slot to availability",
)
async def add_time_slot(
    availability_id: str,
    body: TimeSlotCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TimeSlotResponse:
    service = AvailabilityService(db)
    return await service.add_time_slot(availability_id, body, current_user)


@router.delete(
    "/slots/{slot_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove a time slot",
)
async def remove_time_slot(
    slot_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    service = AvailabilityService(db)
    await service.remove_time_slot(slot_id, current_user)
