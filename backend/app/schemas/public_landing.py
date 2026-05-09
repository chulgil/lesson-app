"""Public web landing schemas consumed by the Ghost theme."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PublicTeacherSummary(BaseModel):
    """Minimal public teacher identity for invite and summary pages."""

    id: str
    name: str | None = None
    instrument: str | None = None
    profile_image_url: str | None = None


class PublicShareMeta(BaseModel):
    """Share metadata for web URL, app deep link, and Open Graph content."""

    title: str
    description: str
    url: str
    app_deep_link: str


class PublicInviteLandingResponse(BaseModel):
    """Public invite landing response."""

    model_config = ConfigDict(from_attributes=True)

    code: str
    status: str
    teacher: PublicTeacherSummary
    share: PublicShareMeta
    expires_at: datetime
