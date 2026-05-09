"""App version, news, and roadmap models for trust-building (R6)."""

from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class AppVersion(Base, UUIDMixin, TimestampMixin):
    """Tracks the latest and minimum required app versions per platform."""

    __tablename__ = "app_versions"

    platform: Mapped[str] = mapped_column(
        String(20), nullable=False, default="ios"
    )
    latest_version: Mapped[str] = mapped_column(String(20), nullable=False)
    min_version: Mapped[str] = mapped_column(String(20), nullable=False)
    release_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    published_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )


class AppNews(Base, UUIDMixin, TimestampMixin):
    """Change log entries shown in the 'What's New' screen."""

    __tablename__ = "app_news"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    link: Mapped[str | None] = mapped_column(String(500), nullable=True)
    published_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class AppRoadmap(Base, UUIDMixin, TimestampMixin):
    """Development roadmap items shown in the roadmap screen."""

    __tablename__ = "app_roadmap"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="planned"
    )
    display_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
