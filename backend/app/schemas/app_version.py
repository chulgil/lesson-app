"""App version, news, and roadmap response schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class VersionResponse(BaseModel):
    latest_version: str
    min_version: str
    release_notes: str | None = None


class NewsItemResponse(BaseModel):
    id: str
    title: str
    summary: str
    published_at: datetime
    link: str | None = None


class RoadmapItemResponse(BaseModel):
    id: str
    title: str
    summary: str
    status: str
    target_date: str | None = None


class AppVersionResponse(BaseModel):
    version: VersionResponse
    news: list[NewsItemResponse]
    roadmap: list[RoadmapItemResponse]
