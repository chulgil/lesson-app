"""Device token service for FCM push notification delivery."""

from __future__ import annotations

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device_token import DevicePlatform, DeviceToken
from app.schemas.device_token import DeviceTokenCreate, DeviceTokenResponse


class DeviceTokenService:
    """Manage FCM device tokens (register, remove, list)."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def register(self, user_id: str, data: DeviceTokenCreate) -> DeviceTokenResponse:
        """Register or update a device token for a user.

        If the token already exists, update the user_id (device ownership transfer).
        """
        existing = await self.db.scalar(
            select(DeviceToken).where(DeviceToken.token == data.token)
        )

        if existing:
            existing.user_id = user_id
            existing.platform = DevicePlatform(data.platform)
            await self.db.flush()
            return DeviceTokenResponse.model_validate(existing)

        device_token = DeviceToken(
            user_id=user_id,
            token=data.token,
            platform=DevicePlatform(data.platform),
        )
        self.db.add(device_token)
        await self.db.flush()
        return DeviceTokenResponse.model_validate(device_token)

    async def unregister(self, token: str) -> None:
        """Remove a device token (e.g., on logout)."""
        await self.db.execute(
            delete(DeviceToken).where(DeviceToken.token == token)
        )
        await self.db.flush()

    async def get_tokens_for_user(self, user_id: str) -> list[str]:
        """Get all FCM tokens for a user (for multi-device push)."""
        result = await self.db.scalars(
            select(DeviceToken.token).where(DeviceToken.user_id == user_id)
        )
        return list(result.all())
