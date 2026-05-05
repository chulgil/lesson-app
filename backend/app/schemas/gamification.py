"""Gamification schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, computed_field


class PointHistoryResponse(BaseModel):
    """Single point history entry."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    points: int
    type: str
    description: str
    earned_at: _dt.datetime


class BadgeResponse(BaseModel):
    """Badge earned by a student."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    badge_name: str
    badge_description: str
    badge_icon: str
    rarity: str
    earned_at: _dt.datetime

    @computed_field
    @property
    def name(self) -> str:
        """Frontend PracticeBadge name."""
        return self.badge_name

    @computed_field
    @property
    def description(self) -> str:
        """Frontend PracticeBadge description."""
        return self.badge_description

    @computed_field
    @property
    def icon(self) -> str:
        """Frontend PracticeBadge icon."""
        return self.badge_icon

    @computed_field
    @property
    def is_earned(self) -> bool:
        """Earned badge entries are always earned."""
        return True


class StudentGamificationResponse(BaseModel):
    """Aggregated gamification data for a student."""

    student_id: str
    total_points: int
    level: int
    level_title: str
    points_to_next_level: int
    current_level_min_points: int
    next_level_min_points: int
    earned_badges: list[BadgeResponse] = []
    recent_history: list[PointHistoryResponse] = []


class AwardPointsRequest(BaseModel):
    """Award points to a student."""

    student_id: str
    points: int
    type: str  # practiceComplete, streakBonus, etc.
    description: str


class BadgeAwardItem(BaseModel):
    """Frontend practice badge payload."""

    id: str | None = None
    name: str
    description: str
    icon: str
    rarity: str
    earned_at: _dt.datetime | None = None
    is_earned: bool = True


class AwardBadgesRequest(BaseModel):
    """Award multiple badges to a student."""

    badges: list[BadgeAwardItem]
