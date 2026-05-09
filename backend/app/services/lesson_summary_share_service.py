"""Lesson summary share-token service."""

from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.schemas.lesson_summary_share import LessonSummaryShareResponse
from app.services.teacher_id_resolver import resolve_teacher_id


class LessonSummaryShareService:
    """Create read-only public tokens for lesson summary sharing."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_share_token(
        self,
        *,
        lesson_id: str,
        current_user: Any,
        expires_in_hours: int = 24,
    ) -> LessonSummaryShareResponse:
        """Create and persist a hashed public share token for a teacher-owned lesson."""
        from app.models.lesson import Lesson
        from app.models.lesson_summary_share_token import LessonSummaryShareToken

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        teacher_profile_id = await resolve_teacher_id(self.db, current_user.id)
        if lesson.teacher_id != teacher_profile_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Lesson access denied")

        token = secrets.token_urlsafe(32)
        expires_at = datetime.now(UTC) + timedelta(hours=expires_in_hours)
        token_row = LessonSummaryShareToken(
            lesson_id=lesson.id,
            teacher_id=current_user.id,
            student_id=lesson.student_id,
            token_hash=self.hash_token(token),
            expires_at=expires_at,
        )
        self.db.add(token_row)
        await self.db.flush()

        web_url = f"{settings.PUBLIC_WEB_BASE_URL.rstrip('/')}/student/{token}/summary"
        app_deep_link = f"lessonapp://student/summary/{token}"
        return LessonSummaryShareResponse(
            token=token,
            url=web_url,
            app_deep_link=app_deep_link,
            expires_at=expires_at,
            share_text=self._build_share_text(lesson=lesson, teacher_name=current_user.name, url=web_url),
        )

    @staticmethod
    def hash_token(token: str) -> str:
        """Return the stable SHA-256 digest stored in the database."""
        return hashlib.sha256(token.encode()).hexdigest()

    @staticmethod
    def _build_share_text(*, lesson: Any, teacher_name: str | None, url: str) -> str:
        date_label = f"{lesson.date.year}년 {lesson.date.month}월 {lesson.date.day}일"
        instrument = lesson.instrument or "레슨"
        instrument_label = f"{instrument} 레슨" if instrument != "레슨" else instrument
        title = lesson.feedback or lesson.practice_tips or "레슨 정리"
        teacher_label = teacher_name or lesson.teacher_name or "선생님"

        return "\n".join(
            [
                f"🎵 오늘 {instrument_label} 정리가 도착했어요",
                "",
                f"📅 {date_label} · {teacher_label} 선생님",
                title,
                "",
                f"👉 {url}",
            ]
        )
