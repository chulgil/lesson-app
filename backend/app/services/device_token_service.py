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

        같은 token row 가 이미 다른 user 소유면 owner 무단 이전을 허용하지 않는다 —
        악성 user 가 victim 의 push 토큰을 자기 user_id 로 hijack 하면 victim 푸시 알림이
        attacker 디바이스로 전달되는 spoofing 발생. 대신 기존 row 를 삭제 (device 가
        새 사용자에게 로그인된 정상 시나리오) 후 새 row 를 만든다.
        """
        existing = await self.db.scalar(select(DeviceToken).where(DeviceToken.token == data.token))

        if existing:
            if existing.user_id == user_id:
                existing.platform = DevicePlatform(data.platform)
                await self.db.flush()
                return DeviceTokenResponse.model_validate(existing)
            # device 가 다른 user 에게 로그인된 경우 → 기존 row 삭제 후 신규 row 생성.
            # 같은 token 으로 두 user 가 동시에 push 받지 않게 보장.
            await self.db.delete(existing)
            await self.db.flush()

        device_token = DeviceToken(
            user_id=user_id,
            token=data.token,
            platform=DevicePlatform(data.platform),
        )
        self.db.add(device_token)
        await self.db.flush()
        return DeviceTokenResponse.model_validate(device_token)

    async def unregister(self, token: str, user_id: str) -> None:
        """Remove a device token (e.g., on logout).

        반드시 caller 본인의 token 만 삭제 — token 문자열만 알면 임의 사용자가 타인 push 를
        무력화하는 것을 방지.
        """
        await self.db.execute(
            delete(DeviceToken).where(DeviceToken.token == token).where(DeviceToken.user_id == user_id)
        )
        await self.db.flush()

    async def get_tokens_for_user(self, user_id: str) -> list[str]:
        """Get all FCM tokens for a user (for multi-device push)."""
        result = await self.db.scalars(select(DeviceToken.token).where(DeviceToken.user_id == user_id))
        return list(result.all())
