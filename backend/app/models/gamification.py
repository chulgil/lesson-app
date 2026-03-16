import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class PointType(str, enum.Enum):
    practiceComplete = "practiceComplete"
    streakBonus = "streakBonus"
    lessonAttendance = "lessonAttendance"
    goalAchieved = "goalAchieved"
    badgeEarned = "badgeEarned"


class BadgeRarity(str, enum.Enum):
    common = "common"
    rare = "rare"
    epic = "epic"
    legendary = "legendary"


class GamificationPoint(UUIDMixin, Base):
    """Point history entry for student gamification."""

    __tablename__ = "gamification_points"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    points: Mapped[int] = mapped_column(Integer, nullable=False)
    type: Mapped[PointType] = mapped_column(
        Enum(PointType, native_enum=True),
        nullable=False,
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    earned_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_gam_points_student", "student_id"),
        Index("idx_gam_points_type", "type"),
    )


class GamificationBadge(UUIDMixin, Base):
    """Badge earned by a student."""

    __tablename__ = "gamification_badges"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    badge_name: Mapped[str] = mapped_column(String(100), nullable=False)
    badge_description: Mapped[str] = mapped_column(Text, nullable=False)
    badge_icon: Mapped[str] = mapped_column(String(50), nullable=False)
    rarity: Mapped[BadgeRarity] = mapped_column(
        Enum(BadgeRarity, native_enum=True),
        nullable=False,
    )
    earned_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_badge_student_name", "student_id", "badge_name", unique=True),
    )
