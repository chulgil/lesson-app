"""Academy announcement service — AC-M3.

Spec: docs/specs/web/academy/announcements_spec.md §2-§3.

책임:
- 학원장 공지 draft 생성 (status=draft, 발송 흐름은 별도)
- 학원 멤버용 공지 목록/단건 조회
- audience targeting / 카톡 발송 / 예약 cron 은 후속 작업

권한:
- create: 학원장만 (assert_owner)
- list/get: 학원 멤버 (list_academies_for_user 로 확인)
"""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academy_announcement import (
    AcademyAnnouncement,
)
from app.models.academy_announcement import (
    AcademyAnnouncementAudience as ModelAudience,
)
from app.models.academy_announcement import (
    AcademyAnnouncementStatus as ModelStatus,
)
from app.schemas.academy_announcement import AcademyAnnouncementCreate


class AcademyAnnouncementService:
    """학원 공지 CRUD. 발송 흐름은 후속."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_draft(
        self,
        *,
        academy_id: str,
        by_user_id: str,
        body: AcademyAnnouncementCreate,
    ) -> AcademyAnnouncement:
        """학원장이 공지 draft 생성. status=draft 로 시작 — 발송은 별도 endpoint."""
        from app.services.academy_service import AcademyService

        await AcademyService(self.db).assert_owner(academy_id, by_user_id)

        # audience=teacher_students 일 때는 audience_filter.teacher_member_id 필수.
        if body.audience == "teacher_students":
            if not body.audience_filter or "teacher_member_id" not in body.audience_filter:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="audience=teacher_students requires audience_filter.teacher_member_id",
                )

        announcement = AcademyAnnouncement(
            academy_id=academy_id,
            author_user_id=by_user_id,
            title=body.title,
            body_markdown=body.body_markdown,
            audience=ModelAudience(body.audience.value),
            audience_filter=body.audience_filter,
            channels=[c.value for c in body.channels],
            kakao_template_id=body.kakao_template_id,
            scheduled_at=body.scheduled_at,
            status=ModelStatus.draft,
        )
        self.db.add(announcement)
        await self.db.flush()
        return announcement

    async def list_for_academy(
        self,
        *,
        academy_id: str,
        by_user_id: str,
    ) -> tuple[list[AcademyAnnouncement], int]:
        """학원 멤버 (owner/teacher) 가 본 학원 공지 전체 조회. 최신순."""
        from app.services.academy_service import AcademyService

        my_academies = await AcademyService(self.db).list_academies_for_user(by_user_id)
        if not any(a.id == academy_id for a in my_academies):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a member",
            )

        stmt = select(AcademyAnnouncement).where(AcademyAnnouncement.academy_id == academy_id)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyAnnouncement.created_at.desc()))
        return list(result.all()), total

    async def get_announcement(
        self,
        *,
        announcement_id: str,
        by_user_id: str,
    ) -> AcademyAnnouncement:
        """단건 조회. 학원 멤버만 — 다른 학원 공지 접근 차단."""
        from app.services.academy_service import AcademyService

        announcement = await self.db.get(AcademyAnnouncement, announcement_id)
        if announcement is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Announcement not found",
            )
        my_academies = await AcademyService(self.db).list_academies_for_user(by_user_id)
        if not any(a.id == announcement.academy_id for a in my_academies):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a member",
            )
        return announcement
