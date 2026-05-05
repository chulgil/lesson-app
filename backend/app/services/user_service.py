"""User profile service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.user import LocaleUpdate, SupportedLocale, SupportedLocalesResponse, UserUpdate


class UserService:
    """Handle user profile operations."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(self, user_id: str) -> Any:
        """Return a user by ID or raise 404."""
        from app.models.user import User

        user = await self.db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return user

    async def update_profile(self, user_id: str, data: UserUpdate) -> Any:
        """Update mutable profile fields."""
        user = await self.get_by_id(user_id)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(user, key, value)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update_role(self, user_id: str, role: str) -> Any:
        """Set user role (used during onboarding)."""
        user = await self.get_by_id(user_id)
        user.role = role
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update_locale(self, user_id: str, data: LocaleUpdate) -> Any:
        """Update locale / country / timezone / currency."""
        user = await self.get_by_id(user_id)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(user, key, value)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def complete_onboarding(self, user_id: str) -> Any:
        """Mark onboarding as completed."""
        user = await self.get_by_id(user_id)
        user.onboarding_completed = True
        await self.db.flush()
        await self.db.refresh(user)
        return user

    @staticmethod
    def get_supported_locales() -> SupportedLocalesResponse:
        """Return the static list of supported locales."""
        return SupportedLocalesResponse(
            locales=[
                SupportedLocale(
                    locale="ko",
                    language_name="Korean",
                    native_name="\ud55c\uad6d\uc5b4",
                    default_country="KR",
                ),
                SupportedLocale(
                    locale="en",
                    language_name="English",
                    native_name="English",
                    default_country="US",
                ),
                SupportedLocale(
                    locale="ja",
                    language_name="Japanese",
                    native_name="\u65e5\u672c\u8a9e",
                    default_country="JP",
                ),
            ]
        )
