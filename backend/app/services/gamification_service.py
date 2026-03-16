"""Gamification service (points, badges, levels)."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession


# Level thresholds
LEVEL_THRESHOLDS = [
    (0, "초보 연습생"),
    (100, "열심히 하는 연습생"),
    (300, "꾸준한 연습생"),
    (600, "실력 있는 연습생"),
    (1000, "연습의 달인"),
    (1500, "음악 장인"),
    (2500, "전설의 연습생"),
]


def _compute_level(total_points: int) -> tuple[int, str, int, int, int]:
    """Compute level, title, points_to_next, current_min, next_min."""
    level = 1
    title = LEVEL_THRESHOLDS[0][1]
    current_min = 0
    next_min = LEVEL_THRESHOLDS[1][0] if len(LEVEL_THRESHOLDS) > 1 else total_points

    for i, (threshold, name) in enumerate(LEVEL_THRESHOLDS):
        if total_points >= threshold:
            level = i + 1
            title = name
            current_min = threshold
            next_min = LEVEL_THRESHOLDS[i + 1][0] if i + 1 < len(LEVEL_THRESHOLDS) else threshold + 1000

    return level, title, max(0, next_min - total_points), current_min, next_min


class GamificationService:
    """Handle student gamification (points, badges)."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_student_gamification(self, student_id: str) -> dict[str, Any]:
        """Get aggregated gamification data for a student."""
        from app.models.gamification import GamificationBadge, GamificationPoint

        # Total points
        total = await self.db.scalar(
            select(func.coalesce(func.sum(GamificationPoint.points), 0)).where(
                GamificationPoint.student_id == student_id
            )
        ) or 0

        level, title, to_next, current_min, next_min = _compute_level(total)

        # Recent history (last 20)
        history_result = await self.db.scalars(
            select(GamificationPoint)
            .where(GamificationPoint.student_id == student_id)
            .order_by(GamificationPoint.earned_at.desc())
            .limit(20)
        )
        history = list(history_result.all())

        # Badges
        badges_result = await self.db.scalars(
            select(GamificationBadge)
            .where(GamificationBadge.student_id == student_id)
            .order_by(GamificationBadge.earned_at.desc())
        )
        badges = list(badges_result.all())

        return {
            "student_id": student_id,
            "total_points": total,
            "level": level,
            "level_title": title,
            "points_to_next_level": to_next,
            "current_level_min_points": current_min,
            "next_level_min_points": next_min,
            "earned_badges": badges,
            "recent_history": history,
        }

    async def award_points(
        self,
        *,
        student_id: str,
        points: int,
        point_type: str,
        description: str,
    ) -> Any:
        """Award points to a student."""
        from app.models.gamification import GamificationPoint

        entry = GamificationPoint(
            student_id=student_id,
            points=points,
            type=point_type,
            description=description,
        )
        self.db.add(entry)
        await self.db.flush()
        await self.db.refresh(entry)
        return entry

    async def award_badge(
        self,
        *,
        student_id: str,
        badge_name: str,
        badge_description: str,
        badge_icon: str,
        rarity: str,
    ) -> Any:
        """Award a badge to a student (idempotent)."""
        from app.models.gamification import GamificationBadge

        existing = await self.db.scalar(
            select(GamificationBadge).where(
                GamificationBadge.student_id == student_id,
                GamificationBadge.badge_name == badge_name,
            )
        )
        if existing:
            return existing

        badge = GamificationBadge(
            student_id=student_id,
            badge_name=badge_name,
            badge_description=badge_description,
            badge_icon=badge_icon,
            rarity=rarity,
        )
        self.db.add(badge)
        await self.db.flush()
        await self.db.refresh(badge)
        return badge
