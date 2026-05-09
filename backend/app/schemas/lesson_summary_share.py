"""Lesson summary share API schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class LessonSummaryShareCreate(BaseModel):
    """Create a public read-only lesson summary share token."""

    expires_in_hours: int = Field(default=24, ge=1, le=168)


class LessonSummaryShareResponse(BaseModel):
    """Created lesson summary share token response."""

    token: str
    url: str
    app_deep_link: str
    expires_at: datetime
    share_text: str
