"""Onboarding quest progress models."""

from datetime import datetime

from sqlalchemy import JSON, DateTime, Index, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class UserOnboardingProgress(UUIDMixin, TimestampMixin, Base):
    """Per-user onboarding v2 progress state."""

    __tablename__ = "user_onboarding_progress"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    current_phase: Mapped[str] = mapped_column(String(40), nullable=False, default="quickStart")
    profile_completeness: Mapped[int] = mapped_column(default=0, nullable=False)
    walkthrough_skipped: Mapped[bool] = mapped_column(default=False, nullable=False)
    coach_marks_seen: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    coach_marks_dismissed: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("uk_user_onboarding_progress_user", "user_id", unique=True),
    )


class UserOnboardingQuestProgress(UUIDMixin, Base):
    """Per-user quest completion state."""

    __tablename__ = "user_onboarding_quest_progress"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    quest_id: Mapped[str] = mapped_column(String(100), nullable=False)
    status: Mapped[str] = mapped_column(String(40), nullable=False, default="completed")
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_user_onboarding_quest_user_quest", "user_id", "quest_id", unique=True),
        Index("idx_user_onboarding_quest_user", "user_id"),
    )
