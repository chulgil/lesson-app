"""Tests for GET /api/v1/app/version endpoint (R6 trust-building)."""

from datetime import UTC, datetime

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_version import AppNews, AppRoadmap, AppVersion


@pytest.mark.asyncio
async def test_app_version_returns_empty_defaults(client: AsyncClient) -> None:
    """No seed data → returns default version 1.0.0."""
    response = await client.get("/api/v1/app/version")
    assert response.status_code == 200

    data = response.json()
    assert data["version"]["latest_version"] == "1.0.0"
    assert data["version"]["min_version"] == "1.0.0"
    assert data["news"] == []
    assert data["roadmap"] == []


@pytest.mark.asyncio
async def test_app_version_returns_seeded_data(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """With seed data → returns version, news, roadmap."""
    db_session.add(
        AppVersion(
            id="test-ver-001",
            platform="ios",
            latest_version="1.2.0",
            min_version="1.0.0",
            release_notes="Test release",
            published_at=datetime(2026, 5, 10, tzinfo=UTC),
        )
    )
    db_session.add(
        AppNews(
            id="test-news-001",
            title="Test News",
            summary="Test summary",
            published_at=datetime(2026, 5, 10, tzinfo=UTC),
            is_active=True,
        )
    )
    db_session.add(
        AppRoadmap(
            id="test-roadmap-001",
            title="Test Feature",
            summary="Test roadmap summary",
            status="planned",
            display_order=1,
            is_active=True,
        )
    )
    await db_session.commit()

    response = await client.get("/api/v1/app/version")
    assert response.status_code == 200

    data = response.json()
    assert data["version"]["latest_version"] == "1.2.0"
    assert data["version"]["min_version"] == "1.0.0"
    assert data["version"]["release_notes"] == "Test release"
    assert len(data["news"]) == 1
    assert data["news"][0]["title"] == "Test News"
    assert len(data["roadmap"]) == 1
    assert data["roadmap"][0]["title"] == "Test Feature"
    assert data["roadmap"][0]["status"] == "planned"


@pytest.mark.asyncio
async def test_app_version_filters_inactive_news(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """Inactive news items should not appear in response."""
    db_session.add(
        AppNews(
            id="test-news-active",
            title="Active News",
            summary="Visible",
            published_at=datetime(2026, 5, 10, tzinfo=UTC),
            is_active=True,
        )
    )
    db_session.add(
        AppNews(
            id="test-news-inactive",
            title="Inactive News",
            summary="Hidden",
            published_at=datetime(2026, 5, 9, tzinfo=UTC),
            is_active=False,
        )
    )
    await db_session.commit()

    response = await client.get("/api/v1/app/version")
    data = response.json()
    assert len(data["news"]) == 1
    assert data["news"][0]["title"] == "Active News"


@pytest.mark.asyncio
async def test_app_version_platform_header(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """X-App-Platform header filters by platform."""
    db_session.add(
        AppVersion(
            id="test-ver-ios",
            platform="ios",
            latest_version="2.0.0",
            min_version="1.5.0",
            published_at=datetime(2026, 5, 10, tzinfo=UTC),
        )
    )
    db_session.add(
        AppVersion(
            id="test-ver-android",
            platform="android",
            latest_version="1.8.0",
            min_version="1.0.0",
            published_at=datetime(2026, 5, 10, tzinfo=UTC),
        )
    )
    await db_session.commit()

    # Default (ios)
    resp_ios = await client.get("/api/v1/app/version")
    assert resp_ios.json()["version"]["latest_version"] == "2.0.0"

    # Explicit android
    resp_android = await client.get(
        "/api/v1/app/version", headers={"X-App-Platform": "android"}
    )
    assert resp_android.json()["version"]["latest_version"] == "1.8.0"
