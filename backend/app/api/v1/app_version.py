"""Public app version, news, and roadmap endpoint (R6 trust-building)."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Header, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.app_version import AppNews, AppRoadmap, AppVersion

router = APIRouter()


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


@router.get(
    "",
    response_model=AppVersionResponse,
    status_code=status.HTTP_200_OK,
)
async def get_app_version(
    db: Annotated[AsyncSession, Depends(get_db)],
    x_app_platform: Annotated[str | None, Header()] = "ios",
) -> AppVersionResponse:
    """Return latest/min version, news, and roadmap. No auth required."""
    platform = (x_app_platform or "ios").lower()

    # Fetch the latest version entry for this platform
    version_result = await db.execute(
        select(AppVersion)
        .where(AppVersion.platform == platform)
        .order_by(AppVersion.published_at.desc())
        .limit(1)
    )
    version_row = version_result.scalar_one_or_none()

    version = VersionResponse(
        latest_version=version_row.latest_version if version_row else "1.0.0",
        min_version=version_row.min_version if version_row else "1.0.0",
        release_notes=version_row.release_notes if version_row else None,
    )

    # Fetch active news, most recent first
    news_result = await db.execute(
        select(AppNews)
        .where(AppNews.is_active.is_(True))
        .order_by(AppNews.published_at.desc())
        .limit(20)
    )
    news_rows = news_result.scalars().all()
    news = [
        NewsItemResponse(
            id=row.id,
            title=row.title,
            summary=row.summary,
            published_at=row.published_at,
            link=row.link,
        )
        for row in news_rows
    ]

    # Fetch active roadmap items, ordered by display_order
    roadmap_result = await db.execute(
        select(AppRoadmap)
        .where(AppRoadmap.is_active.is_(True))
        .order_by(AppRoadmap.display_order)
    )
    roadmap_rows = roadmap_result.scalars().all()
    roadmap = [
        RoadmapItemResponse(
            id=row.id,
            title=row.title,
            summary=row.summary,
            status=row.status,
            target_date=row.target_date.isoformat() if row.target_date else None,
        )
        for row in roadmap_rows
    ]

    return AppVersionResponse(version=version, news=news, roadmap=roadmap)
