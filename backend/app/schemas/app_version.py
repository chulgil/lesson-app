"""Schemas for app version, news, and roadmap API contracts."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class VersionResponse(BaseModel):
    """Version metadata for a platform."""

    latest_version: str
    min_version: str
    release_notes: str | None = None


class NewsItemResponse(BaseModel):
    """App news item."""

    id: str
    title: str
    summary: str
    published_at: datetime
    link: str | None = None


class RoadmapItemResponse(BaseModel):
    """Roadmap item."""

    id: str
    title: str
    summary: str
    status: str
    target_date: str | None = None


class AppVersionResponse(BaseModel):
    """App trust-building payload."""

    version: VersionResponse
    news: list[NewsItemResponse]
    roadmap: list[RoadmapItemResponse]
