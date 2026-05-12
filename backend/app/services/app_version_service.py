"""App version, news, and roadmap service."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_version import AppNews, AppRoadmap, AppVersion
from app.schemas.app_version import (
    AppVersionResponse,
    NewsItemResponse,
    RoadmapItemResponse,
    VersionResponse,
)


class AppVersionService:
    """Read app version, news, and roadmap state."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_app_version(self, platform: str | None) -> AppVersionResponse:
        """Return latest/min version, news, and roadmap."""
        normalized_platform = (platform or "ios").lower()

        version_result = await self.db.execute(
            select(AppVersion)
            .where(AppVersion.platform == normalized_platform)
            .order_by(AppVersion.published_at.desc())
            .limit(1)
        )
        version_row = version_result.scalar_one_or_none()

        news_result = await self.db.execute(
            select(AppNews)
            .where(AppNews.is_active.is_(True))
            .order_by(AppNews.published_at.desc())
            .limit(20)
        )
        news_rows = news_result.scalars().all()

        roadmap_result = await self.db.execute(
            select(AppRoadmap)
            .where(AppRoadmap.is_active.is_(True))
            .order_by(AppRoadmap.display_order)
        )
        roadmap_rows = roadmap_result.scalars().all()

        return AppVersionResponse(
            version=VersionResponse(
                latest_version=version_row.latest_version if version_row else "1.0.0",
                min_version=version_row.min_version if version_row else "1.0.0",
                release_notes=version_row.release_notes if version_row else None,
            ),
            news=[
                NewsItemResponse(
                    id=row.id,
                    title=row.title,
                    summary=row.summary,
                    published_at=row.published_at,
                    link=row.link,
                )
                for row in news_rows
            ],
            roadmap=[
                RoadmapItemResponse(
                    id=row.id,
                    title=row.title,
                    summary=row.summary,
                    status=row.status,
                    target_date=row.target_date.isoformat() if row.target_date else None,
                )
                for row in roadmap_rows
            ],
        )
