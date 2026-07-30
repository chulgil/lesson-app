"""Service for managing share tokens."""

from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.lesson import Lesson
from app.models.share_token import SHARE_TOKEN_RESOURCE_GROWTH_REPORT, ShareToken
from app.schemas.share import (
    GrowthReportShareResponse,
    LessonSummaryShareResponse,
    PublicGrowthReportChild,
    PublicGrowthReportMetrics,
    PublicGrowthReportResponse,
    PublicLessonSummaryBody,
    PublicLessonSummaryLesson,
    PublicLessonSummaryResponse,
    PublicLessonSummaryStudent,
    PublicLessonSummaryTeacher,
)


class ShareTokenService:
    """Service for issuing and validating share tokens."""

    def __init__(self, session: AsyncSession) -> None:
        """Initialize with async database session."""
        self.session = session

    @staticmethod
    def hash_token(token: str) -> str:
        """Return the stable storage hash for a public share token."""
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    async def issue_lesson_summary_token(
        self,
        *,
        lesson_id: str,
        teacher_id: str,
        student_id: str | None,
        expires_in_hours: int = 24,
    ) -> tuple[str, ShareToken]:
        """Issue a lesson summary token and persist only its hash."""
        token_str = secrets.token_urlsafe(32)
        expires_at = datetime.now(UTC) + timedelta(hours=expires_in_hours)

        token = ShareToken(
            token_hash=self.hash_token(token_str),
            lesson_id=lesson_id,
            teacher_id=teacher_id,
            student_id=student_id,
            expires_at=expires_at,
        )
        self.session.add(token)
        await self.session.flush()
        await self.session.refresh(token)
        return token_str, token

    async def resolve_lesson_summary_token(self, token: str) -> ShareToken | None:
        """Resolve a non-revoked lesson summary token and record access."""
        now = datetime.now(UTC)
        token_record = await self.session.scalar(
            select(ShareToken).where(
                ShareToken.token_hash == self.hash_token(token),
                ShareToken.expires_at >= now,
                ShareToken.revoked_at.is_(None),
            ),
        )
        if token_record is None:
            return None
        token_record.access_count = (token_record.access_count or 0) + 1
        token_record.last_accessed_at = now
        await self.session.flush()
        return token_record

    async def get_expired_or_revoked_by_plain_token(self, token: str) -> ShareToken | None:
        """Return a matching expired/revoked token for 410 handling."""
        return await self.session.scalar(
            select(ShareToken).where(ShareToken.token_hash == self.hash_token(token)),
        )

    async def issue_lesson_summary_share(
        self,
        *,
        lesson_id: str,
        expires_in_hours: int,
        current_user: Any,
    ) -> LessonSummaryShareResponse:
        """Issue a public summary share token for a teacher-owned lesson."""
        lesson = await self.session.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        teacher_profile_id = await self._teacher_profile_id(current_user.id)
        if lesson.teacher_id not in {current_user.id, teacher_profile_id}:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot share another teacher's lesson",
            )

        plain_token, token_record = await self.issue_lesson_summary_token(
            lesson_id=lesson.id,
            teacher_id=current_user.id,
            student_id=lesson.student_id,
            expires_in_hours=expires_in_hours,
        )
        public_url = f"{settings.WWW_BASE_URL.rstrip('/')}/student/{plain_token}/summary"
        app_deep_link = f"lessonapp://student/summary/{plain_token}"
        lesson_date = lesson.date.strftime("%Y년 %-m월 %-d일")
        teacher_name = lesson.teacher_name or "선생님"
        share_text = (
            "오늘 레슨 정리가 도착했어요\n\n"
            f"{lesson_date} · {teacher_name}\n"
            f"{lesson.feedback or lesson.student_note or lesson.instrument}\n\n"
            f"{public_url}"
        )
        return LessonSummaryShareResponse(
            token=plain_token,
            url=public_url,
            app_deep_link=app_deep_link,
            expires_at=token_record.expires_at,
            share_text=share_text,
        )

    async def get_public_lesson_summary(self, token: str) -> PublicLessonSummaryResponse:
        """Return a token-gated public lesson summary."""
        token_record = await self.resolve_lesson_summary_token(token)
        if token_record is None:
            existing = await self.get_expired_or_revoked_by_plain_token(token)
            if existing is not None:
                raise HTTPException(status_code=status.HTTP_410_GONE, detail="Token has expired or been revoked")
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Token not found")

        lesson = await self.session.get(Lesson, token_record.lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        return PublicLessonSummaryResponse(
            lesson=PublicLessonSummaryLesson(
                id=lesson.id,
                date=lesson.date.strftime("%Y-%m-%d"),
                start_time=lesson.start_time,
                duration_minutes=lesson.duration,
                session_number=lesson.session_number,
            ),
            teacher=PublicLessonSummaryTeacher(name=lesson.teacher_name),
            student=PublicLessonSummaryStudent(
                name=lesson.student_name,
                instrument=lesson.instrument,
            ),
            summary=PublicLessonSummaryBody(
                feedback=lesson.feedback,
                student_note=lesson.student_note,
                practice_tips=lesson.practice_tips,
                key_points=lesson.key_points,
            ),
            generated_at=datetime.now(UTC),
        )

    # ------------------------------------------------------------------
    # Issue #1217 — 무가입 자녀 성장 리포트 프리뷰 (read-only, no-auth public)
    # ------------------------------------------------------------------

    async def issue_growth_report_token(
        self,
        *,
        student_id: str,
        teacher_id: str,
        expires_in_hours: int = 24,
    ) -> tuple[str, ShareToken]:
        """Issue a growth-report token (student-scoped) and persist only its hash."""
        token_str = secrets.token_urlsafe(32)
        expires_at = datetime.now(UTC) + timedelta(hours=expires_in_hours)

        token = ShareToken(
            token_hash=self.hash_token(token_str),
            resource_type=SHARE_TOKEN_RESOURCE_GROWTH_REPORT,
            lesson_id=None,
            teacher_id=teacher_id,
            student_id=student_id,
            expires_at=expires_at,
        )
        self.session.add(token)
        await self.session.flush()
        await self.session.refresh(token)
        return token_str, token

    async def resolve_growth_report_token(self, token: str) -> ShareToken | None:
        """Resolve a non-revoked, non-expired growth-report token and record access."""
        now = datetime.now(UTC)
        token_record = await self.session.scalar(
            select(ShareToken).where(
                ShareToken.token_hash == self.hash_token(token),
                ShareToken.resource_type == SHARE_TOKEN_RESOURCE_GROWTH_REPORT,
                ShareToken.expires_at >= now,
                ShareToken.revoked_at.is_(None),
            ),
        )
        if token_record is None:
            return None
        token_record.access_count = (token_record.access_count or 0) + 1
        token_record.last_accessed_at = now
        await self.session.flush()
        return token_record

    async def issue_growth_report_share(
        self,
        *,
        student_id: str,
        expires_in_hours: int,
        current_user: Any,
    ) -> GrowthReportShareResponse:
        """Issue a public growth-report share token for a teacher-owned student."""
        from app.models.student import Student

        student = await self.session.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        teacher_profile_id = await self._teacher_profile_id(current_user.id)
        # Reject unassigned students (teacher_id IS NULL) and never match on a
        # null owner id — otherwise a teacher-role user without a Teacher profile
        # (teacher_profile_id None) could mint a token for any unassigned child.
        owner_ids = {current_user.id}
        if teacher_profile_id is not None:
            owner_ids.add(teacher_profile_id)
        if student.teacher_id is None or student.teacher_id not in owner_ids:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot share another teacher's student report",
            )

        plain_token, token_record = await self.issue_growth_report_token(
            student_id=student.id,
            teacher_id=current_user.id,
            expires_in_hours=expires_in_hours,
        )
        public_url = f"{settings.WWW_BASE_URL.rstrip('/')}/growth-report/{plain_token}"
        app_deep_link = f"lessonapp://growth-report/{plain_token}"
        return GrowthReportShareResponse(
            token=plain_token,
            url=public_url,
            app_deep_link=app_deep_link,
            expires_at=token_record.expires_at,
        )

    async def get_public_growth_report(self, token: str) -> PublicGrowthReportResponse:
        """Return a token-gated, minimal read-only child growth report.

        Data minimality (#1217, minor-safe, no-auth public endpoint): only the
        child's given name + non-sensitive growth metrics are exposed. Contact
        info, address, payment data, and detailed lesson notes are never
        included. Wrong/expired/revoked tokens all resolve to 404 (no info
        leak about whether a token ever existed).
        """
        token_record = await self.resolve_growth_report_token(token)
        if token_record is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Token not found")

        from app.models.student import Student

        student = await self.session.get(Student, token_record.student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Token not found")

        from app.services.streak_service import compute_streak

        streak = (await compute_streak(self.session, student.id)).current

        cutoff_date = (datetime.now(UTC) - timedelta(days=30)).date()
        recent_lesson_count = (
            await self.session.scalar(
                select(func.count()).where(
                    Lesson.student_id == student.id,
                    Lesson.status == "completed",
                    Lesson.date >= cutoff_date,
                ),
            )
            or 0
        )

        progress_summary = f"최근 30일 레슨 {recent_lesson_count}회 · 연속 연습 {streak}일째"

        return PublicGrowthReportResponse(
            child=PublicGrowthReportChild(
                given_name=self._given_name(student.name),
                instrument=student.instrument,
            ),
            metrics=PublicGrowthReportMetrics(
                practice_streak_days=streak,
                recent_lesson_count=recent_lesson_count,
                progress_summary=progress_summary,
            ),
            generated_at=datetime.now(UTC),
        )

    @staticmethod
    def _given_name(full_name: str) -> str:
        """Extract a Korean/Western given name only (mirrors FE NameUtils.givenName).

        Korean: "박지선" -> "지선" (surname stripped). Western: "John Smith" ->
        "John". Used to avoid exposing a child's full legal name on a no-auth
        public endpoint.
        """
        trimmed = (full_name or "").strip()
        if not trimmed:
            return trimmed
        if " " in trimmed:
            return trimmed.split(" ")[0]
        is_cjk = all(("가" <= ch <= "힣") or ("一" <= ch <= "鿿") or ("㐀" <= ch <= "䶿") for ch in trimmed)
        if is_cjk and 2 <= len(trimmed) <= 4:
            return trimmed[1:]
        return trimmed

    async def _teacher_profile_id(self, user_id: str) -> str | None:
        from app.models.teacher import Teacher

        return await self.session.scalar(select(Teacher.id).where(Teacher.user_id == user_id))
