"""Lesson location endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.common import SuccessResponse
from app.schemas.location import LocationCreate, LocationResponse, LocationUpdate
from app.services.location_service import LocationService

router = APIRouter()


@router.get(
    "",
    response_model=list[LocationResponse],
    status_code=status.HTTP_200_OK,
    summary="List locations for a class or owner",
)
async def list_locations(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    class_id: str | None = None,
    owner_id: str | None = None,
) -> list[LocationResponse]:
    """List locations filtered by class_id or owner_id.

    If neither is provided, returns all locations owned by the current user.
    """
    service = LocationService(db)
    if class_id:
        return await service.get_by_class_id(class_id)
    if owner_id:
        return await service.get_by_owner_id(owner_id)
    return await service.get_by_owner_id(current_user.id)


@router.post(
    "",
    response_model=LocationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new location",
)
async def create_location(
    body: LocationCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LocationResponse:
    """Create a new lesson location."""
    service = LocationService(db)
    return await service.create(body, owner_id=current_user.id)


@router.get(
    "/{location_id}",
    response_model=LocationResponse,
    status_code=status.HTTP_200_OK,
    summary="Get location detail",
)
async def get_location(
    location_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LocationResponse:
    """Return a single location by ID."""
    service = LocationService(db)
    return await service.get_by_id(location_id)


@router.put(
    "/{location_id}",
    response_model=LocationResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a location",
)
async def update_location(
    location_id: str,
    body: LocationUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LocationResponse:
    """Update location fields."""
    service = LocationService(db)
    return await service.update(location_id, body, current_user)


@router.patch(
    "/{location_id}/default",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Set location as default for its class",
)
async def set_default_location(
    location_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    class_id: str | None = None,
) -> SuccessResponse:
    """Set a location as default for a class."""
    service = LocationService(db)
    await service.set_default(location_id, class_id or "")
    return SuccessResponse(message="Default location updated")


@router.patch(
    "/{location_id}/deactivate",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Deactivate a location (soft delete)",
)
async def deactivate_location(
    location_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SuccessResponse:
    """Soft-delete a location."""
    service = LocationService(db)
    await service.deactivate(location_id)
    return SuccessResponse(message="Location deactivated")


@router.patch(
    "/{location_id}/reactivate",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Reactivate a location",
)
async def reactivate_location(
    location_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SuccessResponse:
    """Reactivate a previously deactivated location."""
    service = LocationService(db)
    await service.reactivate(location_id)
    return SuccessResponse(message="Location reactivated")
