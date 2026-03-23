"""Lesson location service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.location import LocationCreate, LocationResponse, LocationUpdate


class LocationService:
    """Handle lesson location CRUD."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_class_id(self, class_id: str) -> list[LocationResponse]:
        """List all locations for a lesson class."""
        from app.models.lesson import LessonLocation

        result = await self.db.scalars(
            select(LessonLocation).where(
                LessonLocation.lesson_class_id == class_id,
                LessonLocation.is_active.is_(True),
            )
        )
        return [LocationResponse.model_validate(loc) for loc in result.all()]

    async def get_by_owner_id(self, owner_id: str) -> list[LocationResponse]:
        """List all locations owned by a teacher."""
        from app.models.lesson import LessonLocation

        result = await self.db.scalars(
            select(LessonLocation).where(
                LessonLocation.owner_id == owner_id,
                LessonLocation.is_active.is_(True),
            )
        )
        return [LocationResponse.model_validate(loc) for loc in result.all()]

    async def get_by_id(self, location_id: str) -> LocationResponse:
        """Return a single location by ID."""
        from app.models.lesson import LessonLocation

        location = await self.db.get(LessonLocation, location_id)
        if location is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")
        return LocationResponse.model_validate(location)

    async def create(self, data: LocationCreate, owner_id: str) -> LocationResponse:
        """Create a new lesson location."""
        from app.models.lesson import LessonLocation

        location = LessonLocation(
            owner_id=owner_id,
            **data.model_dump(),
        )
        self.db.add(location)

        # If this is set as default, unset other defaults in the same class
        if data.is_default and data.lesson_class_id:
            await self._unset_other_defaults(data.lesson_class_id, exclude_id=None)

        await self.db.flush()
        await self.db.refresh(location)
        return LocationResponse.model_validate(location)

    async def update(self, location_id: str, data: LocationUpdate, current_user: Any) -> LocationResponse:
        """Update a location."""
        from app.models.lesson import LessonLocation

        location = await self.db.get(LessonLocation, location_id)
        if location is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(location, key, value)

        await self.db.flush()
        await self.db.refresh(location)
        return LocationResponse.model_validate(location)

    async def set_default(self, location_id: str, class_id: str) -> None:
        """Set a location as default for a class, unsetting others."""
        from app.models.lesson import LessonLocation

        location = await self.db.get(LessonLocation, location_id)
        if location is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")

        await self._unset_other_defaults(class_id, exclude_id=location_id)
        location.is_default = True
        await self.db.flush()

    async def deactivate(self, location_id: str) -> None:
        """Soft-delete a location."""
        from app.models.lesson import LessonLocation

        location = await self.db.get(LessonLocation, location_id)
        if location is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")
        location.is_active = False
        await self.db.flush()

    async def reactivate(self, location_id: str) -> None:
        """Reactivate a soft-deleted location."""
        from app.models.lesson import LessonLocation

        location = await self.db.get(LessonLocation, location_id)
        if location is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")
        location.is_active = True
        await self.db.flush()

    async def _unset_other_defaults(self, class_id: str, exclude_id: str | None) -> None:
        """Unset is_default for all other locations in the class."""
        from app.models.lesson import LessonLocation

        query = select(LessonLocation).where(
            LessonLocation.lesson_class_id == class_id,
            LessonLocation.is_default.is_(True),
        )
        if exclude_id:
            query = query.where(LessonLocation.id != exclude_id)

        result = await self.db.scalars(query)
        for loc in result.all():
            loc.is_default = False
