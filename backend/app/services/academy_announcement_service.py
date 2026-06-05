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

    async def resolve_audience_count(
        self,
        *,
        academy_id: str,
        by_user_id: str,
        audience: ModelAudience,
        audience_filter: dict | None = None,
    ) -> dict[str, int | dict[str, int]]:
        """공지 작성 화면 미리보기용 — spec §3.1 "대상 수" 산출.

        Returns: ``{"target_count": N, "by_role": {"teacher": T, "parent": P, "student": S}}``

        분류:
        - all: 활성 강사 멤버 + 학원 학생(active/matched)의 student/parent
        - teachers: 활성 강사 멤버만
        - students: AcademyStudent 의 student_user_id NULL 아닌 활성 학생
        - parents: AcademyStudent 의 parent_user_id NULL 아닌 활성 학생
        - teacher_students: filter[teacher_member_id] 매칭 학생들의 student/parent

        제외: status=alumni / paused, member.access_revoked_at IS NOT NULL.
        """
        from app.models.academy import (
            AcademyMember,
            AcademyMemberRole,
            AcademyStudent,
            AcademyStudentStatus,
        )
        from app.services.academy_service import AcademyService

        await AcademyService(self.db).assert_owner(academy_id, by_user_id)

        # ---- 강사 멤버 활성 카운트 (재사용) ----
        teacher_count = int(
            (
                await self.db.scalar(
                    select(func.count(AcademyMember.id))
                    .where(AcademyMember.academy_id == academy_id)
                    .where(AcademyMember.role == AcademyMemberRole.teacher)
                    .where(AcademyMember.access_revoked_at.is_(None))
                )
            )
            or 0
        )

        # ---- 학원 학생 base 쿼리 (active/matched 만, alumni/paused 제외) ----
        active_statuses = (AcademyStudentStatus.matched, AcademyStudentStatus.active)
        students_base = select(AcademyStudent).where(
            AcademyStudent.academy_id == academy_id,
            AcademyStudent.status.in_(active_statuses),
        )

        # ---- teacher_students 분기는 매칭 강사 필터 추가 ----
        if audience == ModelAudience.teacher_students:
            teacher_member_id = (audience_filter or {}).get("teacher_member_id")
            if not teacher_member_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="audience=teacher_students requires audience_filter.teacher_member_id",
                )
            students_base = students_base.where(AcademyStudent.teacher_member_id == teacher_member_id)

        # 가입한 학생 user 수
        student_user_count = int(
            (
                await self.db.scalar(
                    select(func.count()).select_from(
                        students_base.where(AcademyStudent.student_user_id.is_not(None)).subquery()
                    )
                )
            )
            or 0
        )
        # 가입한 학부모 user 수
        parent_user_count = int(
            (
                await self.db.scalar(
                    select(func.count()).select_from(
                        students_base.where(AcademyStudent.parent_user_id.is_not(None)).subquery()
                    )
                )
            )
            or 0
        )

        teacher_part = 0
        parent_part = 0
        student_part = 0

        if audience == ModelAudience.all:
            teacher_part = teacher_count
            parent_part = parent_user_count
            student_part = student_user_count
        elif audience == ModelAudience.teachers:
            teacher_part = teacher_count
        elif audience == ModelAudience.students:
            student_part = student_user_count
        elif audience == ModelAudience.parents:
            parent_part = parent_user_count
        elif audience == ModelAudience.teacher_students:
            # 특정 강사 학생의 student + parent (강사 본인은 미포함)
            parent_part = parent_user_count
            student_part = student_user_count

        target_count = teacher_part + parent_part + student_part
        return {
            "target_count": target_count,
            "by_role": {
                "teacher": teacher_part,
                "parent": parent_part,
                "student": student_part,
            },
        }
