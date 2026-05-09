"""Seed data for app version, news, and roadmap (R6 trust-building)."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_version import AppNews, AppRoadmap, AppVersion
from scripts.seeds.helpers import upsert

APP_VERSION_ID = "seed-app-version-ios-0001"


async def seed_app_version(db: AsyncSession, *, reset: bool = False) -> None:
    """Seed app version, news items, and roadmap items."""
    if reset:
        await db.execute(delete(AppRoadmap))
        await db.execute(delete(AppNews))
        await db.execute(delete(AppVersion))
        await db.flush()

    # Version
    await upsert(
        db,
        AppVersion,
        AppVersion(
            id=APP_VERSION_ID,
            platform="ios",
            latest_version="1.1.0",
            min_version="1.0.0",
            release_notes="레슨 운영 흐름 안정화 및 연습 일지 개선",
            published_at=datetime(2026, 5, 10, tzinfo=UTC),
        ),
    )

    # News
    await upsert(
        db,
        AppNews,
        AppNews(
            id="seed-news-0001",
            title="레슨 운영 흐름 안정화",
            summary="스케줄 변경 요청과 취소 요청의 상태 표시를 더 명확하게 정리했습니다.",
            published_at=datetime(2026, 5, 7, tzinfo=UTC),
            is_active=True,
        ),
    )
    await upsert(
        db,
        AppNews,
        AppNews(
            id="seed-news-0002",
            title="온보딩과 연습 일지 개선",
            summary="프로필 설정과 연습 일지 공유 흐름의 회귀 테스트를 보강했습니다.",
            published_at=datetime(2026, 5, 7, tzinfo=UTC),
            is_active=True,
        ),
    )

    # Roadmap
    await upsert(
        db,
        AppRoadmap,
        AppRoadmap(
            id="seed-roadmap-0001",
            title="악보 PDF 첨부",
            summary="선생님 홈에서 악보를 PDF로 첨부할 수 있게 합니다.",
            status="planned",
            display_order=1,
            is_active=True,
        ),
    )
    await upsert(
        db,
        AppRoadmap,
        AppRoadmap(
            id="seed-roadmap-0002",
            title="Pro 플랜 출시",
            summary="6명 이상 학생 관리를 위한 유료 플랜을 준비합니다.",
            status="inProgress",
            display_order=2,
            is_active=True,
        ),
    )
    await upsert(
        db,
        AppRoadmap,
        AppRoadmap(
            id="seed-roadmap-0003",
            title="학부모 영상 공유",
            summary="학부모가 레슨 영상을 직접 확인할 수 있게 합니다.",
            status="planned",
            display_order=3,
            is_active=True,
        ),
    )

    await db.commit()
