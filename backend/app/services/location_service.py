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

    async def get_by_class_id(self, class_id: str, current_user: Any | None = None) -> list[LocationResponse]:
        """List all locations for a lesson class."""
        from app.models.lesson import LessonLocation

        if current_user is not None:
            await self._assert_class_locations_owner(class_id, current_user)

        result = await self.db.scalars(
            select(LessonLocation).where(
                LessonLocation.lesson_class_id == class_id,
                LessonLocation.is_active.is_(True),
            )
        )
        return [LocationResponse.model_validate(loc) for loc in result.all()]

    async def get_by_owner_id(self, owner_id: str, current_user: Any | None = None) -> list[LocationResponse]:
        """List all locations owned by a teacher."""
        from app.models.lesson import LessonLocation

        if current_user is not None:
            self._assert_owner_id(owner_id, current_user)

        result = await self.db.scalars(
            select(LessonLocation).where(
                LessonLocation.owner_id == owner_id,
                LessonLocation.is_active.is_(True),
            )
        )
        return [LocationResponse.model_validate(loc) for loc in result.all()]

    async def get_by_id(self, location_id: str, current_user: Any | None = None) -> LocationResponse:
        """Return a single location by ID."""
        location = await self._get_owned_location(location_id, current_user)
        return LocationResponse.model_validate(location)

    async def create(self, data: LocationCreate, owner_id: str) -> LocationResponse:
        """Create a new lesson location."""
        from app.models.lesson import LessonLocation

        if data.lesson_class_id:
            await self._assert_lesson_class_owner(data.lesson_class_id, owner_id)

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
        location = await self._get_owned_location(location_id, current_user)

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(location, key, value)

        await self.db.flush()
        await self.db.refresh(location)
        return LocationResponse.model_validate(location)

    async def set_default(self, location_id: str, class_id: str, current_user: Any | None = None) -> None:
        """Set a location as default for a class, unsetting others."""
        location = await self._get_owned_location(location_id, current_user)

        default_class_id = class_id or location.lesson_class_id
        if default_class_id and current_user is not None:
            await self._assert_lesson_class_owner(default_class_id, current_user.id)
        await self._unset_other_defaults(default_class_id, exclude_id=location_id, current_user=current_user)
        location.is_default = True
        await self.db.flush()

    async def deactivate(self, location_id: str, current_user: Any | None = None) -> None:
        """Soft-delete a location."""
        location = await self._get_owned_location(location_id, current_user)
        location.is_active = False
        await self.db.flush()

    async def reactivate(self, location_id: str, current_user: Any | None = None) -> None:
        """Reactivate a soft-deleted location."""
        location = await self._get_owned_location(location_id, current_user)
        location.is_active = True
        await self.db.flush()

    async def _unset_other_defaults(
        self,
        class_id: str | None,
        exclude_id: str | None,
        current_user: Any | None = None,
    ) -> None:
        """Unset is_default for all other locations in the class."""
        from app.models.lesson import LessonLocation

        if not class_id:
            return
        if current_user is not None:
            await self._assert_class_locations_owner(class_id, current_user)

        query = select(LessonLocation).where(
            LessonLocation.lesson_class_id == class_id,
            LessonLocation.is_default.is_(True),
        )
        if exclude_id:
            query = query.where(LessonLocation.id != exclude_id)

        result = await self.db.scalars(query)
        for loc in result.all():
            loc.is_default = False

    async def _get_owned_location(self, location_id: str, current_user: Any | None) -> Any:
        from app.models.lesson import LessonLocation

        location = await self.db.get(LessonLocation, location_id)
        if location is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")
        if current_user is not None:
            self._assert_owner_id(location.owner_id, current_user)
        return location

    async def _assert_class_locations_owner(self, class_id: str, current_user: Any) -> None:
        from app.models.lesson import LessonLocation

        await self._assert_lesson_class_owner(class_id, current_user.id)
        result = await self.db.scalars(
            select(LessonLocation.owner_id).where(LessonLocation.lesson_class_id == class_id).limit(1)
        )
        owner_id = result.first()
        if owner_id is not None:
            self._assert_owner_id(owner_id, current_user)

    async def _assert_lesson_class_owner(self, class_id: str, owner_user_id: str) -> None:
        from app.models.lesson import LessonClass
        from app.services.teacher_id_resolver import resolve_teacher_id

        teacher_id = await resolve_teacher_id(self.db, owner_user_id)
        class_teacher_id = await self.db.scalar(select(LessonClass.teacher_id).where(LessonClass.id == class_id))
        if class_teacher_id is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson class not found")
        if class_teacher_id != teacher_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot manage another teacher's lesson class locations",
            )

    def _assert_owner_id(self, owner_id: str | None, current_user: Any) -> None:
        if owner_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot manage another teacher's location",
            )
