"""Public landing data service for Ghost-rendered web pages."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.schemas.public_landing import (
    PublicInviteLandingResponse,
    PublicLessonSummaryContent,
    PublicLessonSummaryLesson,
    PublicLessonSummaryTeacher,
    PublicShareMeta,
    PublicStudentSummaryIdentity,
    PublicStudentSummaryResponse,
    PublicTeacherSummary,
)
from app.services.lesson_summary_share_service import LessonSummaryShareService


class PublicLandingService:
    """Build public, read-only payloads for Ghost web pages."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_invite_landing(self, invite_code: str) -> PublicInviteLandingResponse:
        """Return minimal invite landing data for a public invite code."""
        from app.models.invite import Invite, InviteStatus
        from app.models.teacher import Teacher
        from app.models.user import User

        code = invite_code.upper()
        invite = await self.db.scalar(select(Invite).where(Invite.invite_code == code))
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")

        expires_at = self._ensure_aware(invite.expires_at)
        if (
            invite.status != InviteStatus.active
            or expires_at <= datetime.now(UTC)
            or (invite.max_uses is not None and invite.use_count >= invite.max_uses)
        ):
            raise HTTPException(status_code=status.HTTP_410_GONE, detail="Invite is no longer available")

        teacher_user = await self.db.get(User, invite.creator_id)
        teacher_profile = await self.db.scalar(select(Teacher).where(Teacher.user_id == invite.creator_id))
        teacher_name = teacher_user.name if teacher_user is not None else invite.creator_name
        instrument = self._first_instrument(teacher_profile.instruments if teacher_profile is not None else None)
        web_url = f"{settings.PUBLIC_WEB_BASE_URL.rstrip('/')}/invite/{code}"
        app_deep_link = f"lessonapp://invite/{code}"

        title_name = teacher_name or "선생님"
        description_subject = f"{instrument} 레슨" if instrument else "레슨"

        return PublicInviteLandingResponse(
            code=code,
            status=invite.status.value,
            teacher=PublicTeacherSummary(
                id=invite.creator_id,
                name=teacher_name,
                instrument=instrument,
                profile_image_url=teacher_user.profile_image_url if teacher_user is not None else None,
            ),
            share=PublicShareMeta(
                title=f"{title_name} 선생님의 레슨앱 초대",
                description=f"{description_subject} 기록과 숙제를 함께 확인해요",
                url=web_url,
                app_deep_link=app_deep_link,
            ),
            expires_at=expires_at,
        )

    async def get_student_summary(self, raw_token: str) -> PublicStudentSummaryResponse:
        """Return read-only lesson summary data for a valid public token."""
        from app.models.lesson import Lesson
        from app.models.lesson_summary_share_token import LessonSummaryShareToken
        from app.models.student import Student
        from app.models.user import User

        token_hash = LessonSummaryShareService.hash_token(raw_token)
        share_token = await self.db.scalar(
            select(LessonSummaryShareToken).where(LessonSummaryShareToken.token_hash == token_hash)
        )
        if share_token is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Summary token not found")

        expires_at = self._ensure_aware(share_token.expires_at)
        if share_token.revoked_at is not None or expires_at <= datetime.now(UTC):
            raise HTTPException(status_code=status.HTTP_410_GONE, detail="Summary token is no longer available")

        lesson = await self.db.get(Lesson, share_token.lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        teacher_user = await self.db.get(User, share_token.teacher_id)
        student = await self.db.get(Student, share_token.student_id) if share_token.student_id else None

        share_token.access_count += 1
        share_token.last_accessed_at = datetime.now(UTC)
        await self.db.flush()

        web_url = f"{settings.PUBLIC_WEB_BASE_URL.rstrip('/')}/student/{raw_token}/summary"
        instrument = lesson.instrument or (student.instrument if student is not None else None)
        title = lesson.feedback or lesson.practice_tips or "레슨 정리"
        teacher_name = teacher_user.name if teacher_user is not None else lesson.teacher_name
        teacher_profile_image = teacher_user.profile_image_url if teacher_user is not None else None

        return PublicStudentSummaryResponse(
            lesson=PublicLessonSummaryLesson(
                id=lesson.id,
                date=lesson.date,
                start_time=lesson.start_time,
                duration_minutes=lesson.duration,
                session_number=lesson.session_number,
                status=lesson.status.value if hasattr(lesson.status, "value") else str(lesson.status),
            ),
            teacher=PublicLessonSummaryTeacher(
                name=teacher_name,
                instrument=instrument,
                profile_image_url=teacher_profile_image,
            ),
            student=PublicStudentSummaryIdentity(
                name=student.name if student is not None else lesson.student_name,
            ),
            summary=PublicLessonSummaryContent(
                title=title,
                lesson_note=lesson.feedback,
                homework=lesson.practice_tips,
                next_lesson_at=None,
            ),
            share=PublicShareMeta(
                title=f"오늘 {instrument or '레슨'} 레슨 정리",
                description=f"{teacher_name or '선생님'} 선생님이 보낸 레슨 요약",
                url=web_url,
                app_deep_link=f"lessonapp://student/summary/{raw_token}",
            ),
        )

    @staticmethod
    def _ensure_aware(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value

    @staticmethod
    def _first_instrument(value: Any) -> str | None:
        if isinstance(value, list):
            for item in value:
                if isinstance(item, str) and item.strip():
                    return item.strip()
                if isinstance(item, dict):
                    name = item.get("name") or item.get("instrument")
                    if isinstance(name, str) and name.strip():
                        return name.strip()
        if isinstance(value, dict):
            name = value.get("name") or value.get("instrument")
            if isinstance(name, str) and name.strip():
                return name.strip()
        return None
