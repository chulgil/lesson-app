"""Public landing data service for Ghost-rendered web pages."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.schemas.public_landing import (
    PublicInviteLandingResponse,
    PublicShareMeta,
    PublicTeacherSummary,
)


class PublicLandingService:
    """Build public, read-only payloads for Ghost web pages."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_invite_landing(self, invite_code: str) -> PublicInviteLandingResponse:
        """Return minimal invite landing data for a public invite code."""
        from app.models.invite import Invite, InviteStatus
        from app.models.teacher import Teacher
        from app.models.user import User

        code = invite_code.upper()
        invite = await self.db.scalar(select(Invite).where(Invite.invite_code == code))
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")

        expires_at = self._ensure_aware(invite.expires_at)
        if (
            invite.status != InviteStatus.active
            or expires_at <= datetime.now(UTC)
            or (invite.max_uses is not None and invite.use_count >= invite.max_uses)
        ):
            raise HTTPException(status_code=status.HTTP_410_GONE, detail="Invite is no longer available")

        teacher_user = await self.db.get(User, invite.creator_id)
        teacher_profile = await self.db.scalar(select(Teacher).where(Teacher.user_id == invite.creator_id))
        teacher_name = teacher_user.name if teacher_user is not None else invite.creator_name
        instrument = self._first_instrument(teacher_profile.instruments if teacher_profile is not None else None)
        web_url = f"{settings.PUBLIC_WEB_BASE_URL.rstrip('/')}/invite/{code}"
        app_deep_link = f"lessonapp://invite/{code}"

        title_name = teacher_name or "선생님"
        description_subject = f"{instrument} 레슨" if instrument else "레슨"

        return PublicInviteLandingResponse(
            code=code,
            status=invite.status.value,
            teacher=PublicTeacherSummary(
                id=invite.creator_id,
                name=teacher_name,
                instrument=instrument,
                profile_image_url=teacher_user.profile_image_url if teacher_user is not None else None,
            ),
            share=PublicShareMeta(
                title=f"{title_name} 선생님의 레슨앱 초대",
                description=f"{description_subject} 기록과 숙제를 함께 확인해요",
                url=web_url,
                app_deep_link=app_deep_link,
            ),
            expires_at=expires_at,
        )

    @staticmethod
    def _ensure_aware(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value

    @staticmethod
    def _first_instrument(value: Any) -> str | None:
        if isinstance(value, list):
            for item in value:
                if isinstance(item, str) and item.strip():
                    return item.strip()
                if isinstance(item, dict):
                    name = item.get("name") or item.get("instrument")
                    if isinstance(name, str) and name.strip():
                        return name.strip()
        if isinstance(value, dict):
            name = value.get("name") or value.get("instrument")
            if isinstance(name, str) and name.strip():
                return name.strip()
        return None
