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

    async def send(
        self,
        *,
        announcement_id: str,
        by_user_id: str,
    ) -> AcademyAnnouncement:
        """공지 발송 — draft 상태에서 audience enumerate → Recipient 행 생성.

        Spec §4 발송 시퀀스 중 BE 단계만 구현. 카톡/푸시 발송은 별도 큐 작업.

        절차:
        1. 학원장 권한 확인 (assert_owner)
        2. status 가 draft 또는 scheduled 일 때만 진행 (이미 sent/cancelled 면 409)
        3. audience enumerate → 대상 user_id + role 수집 (중복 user_id 는 skip)
        4. AcademyAnnouncementRecipient 일괄 INSERT
        5. announcement.target_count / sent_at / status=sent 갱신
        """
        from datetime import UTC, datetime

        from app.models.academy_announcement import (
            AcademyAnnouncementRecipient,
        )
        from app.models.academy_announcement import (
            AcademyAnnouncementRecipientRole as RecipientRole,
        )
        from app.services.academy_service import AcademyService

        announcement = await self.db.get(AcademyAnnouncement, announcement_id)
        if announcement is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Announcement not found",
            )
        await AcademyService(self.db).assert_owner(announcement.academy_id, by_user_id)
        if announcement.status not in (ModelStatus.draft, ModelStatus.scheduled):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Cannot send announcement in status={announcement.status.value}",
            )

        recipients = await self._enumerate_recipients(
            academy_id=announcement.academy_id,
            audience=announcement.audience,
            audience_filter=announcement.audience_filter,
        )

        # UNIQUE (announcement_id, user_id) 충돌 방지 — 같은 user 가 학생+학부모
        # 중복 매칭되면 우선순위 teacher > parent > student 으로 1행만.
        priority = {RecipientRole.teacher: 0, RecipientRole.parent: 1, RecipientRole.student: 2}
        dedup: dict[str, RecipientRole] = {}
        for user_id, role in recipients:
            existing = dedup.get(user_id)
            if existing is None or priority[role] < priority[existing]:
                dedup[user_id] = role

        for user_id, role in dedup.items():
            self.db.add(
                AcademyAnnouncementRecipient(
                    announcement_id=announcement.id,
                    user_id=user_id,
                    role=role,
                )
            )

        announcement.target_count = len(dedup)
        announcement.sent_at = datetime.now(UTC)
        announcement.status = ModelStatus.sent
        await self.db.flush()
        return announcement

    async def _enumerate_recipients(
        self,
        *,
        academy_id: str,
        audience: ModelAudience,
        audience_filter: dict | None,
    ) -> list[tuple[str, AcademyAnnouncementRecipientRole]]:
        """audience 분기별 대상 (user_id, role) 목록. resolve_audience_count 와
        동일 기준 (활성 멤버 + matched/active 학생).
        """
        from app.models.academy import (
            AcademyMember,
            AcademyMemberRole,
            AcademyStudent,
            AcademyStudentStatus,
        )
        from app.models.academy_announcement import (
            AcademyAnnouncementRecipientRole as RecipientRole,
        )

        active_statuses = (AcademyStudentStatus.matched, AcademyStudentStatus.active)
        out: list[tuple[str, RecipientRole]] = []

        include_teachers = audience in (ModelAudience.all, ModelAudience.teachers)
        include_students = audience in (
            ModelAudience.all,
            ModelAudience.students,
            ModelAudience.teacher_students,
        )
        include_parents = audience in (
            ModelAudience.all,
            ModelAudience.parents,
            ModelAudience.teacher_students,
        )

        if include_teachers:
            rows = await self.db.scalars(
                select(AcademyMember.user_id)
                .where(AcademyMember.academy_id == academy_id)
                .where(AcademyMember.role == AcademyMemberRole.teacher)
                .where(AcademyMember.access_revoked_at.is_(None))
            )
            for uid in rows.all():
                out.append((uid, RecipientRole.teacher))

        if include_students or include_parents:
            students_stmt = select(AcademyStudent).where(
                AcademyStudent.academy_id == academy_id,
                AcademyStudent.status.in_(active_statuses),
            )
            if audience == ModelAudience.teacher_students:
                tm_id = (audience_filter or {}).get("teacher_member_id")
                if not tm_id:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="audience=teacher_students requires audience_filter.teacher_member_id",
                    )
                students_stmt = students_stmt.where(AcademyStudent.teacher_member_id == tm_id)
            students = (await self.db.scalars(students_stmt)).all()
            for s in students:
                if include_students and s.student_user_id:
                    out.append((s.student_user_id, RecipientRole.student))
                if include_parents and s.parent_user_id:
                    out.append((s.parent_user_id, RecipientRole.parent))

        return out

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

    # ------------------------------------------------------------------
    # Send flow — §4 발송 시퀀스
    # ------------------------------------------------------------------

    async def send_announcement(
        self,
        *,
        announcement_id: str,
        by_user_id: str,
    ) -> AcademyAnnouncement:
        """draft → sending → sent (synchronous fanout).

        spec §4:
        1. 대상자 enumerate (audience → user_id set)
        2. AcademyAnnouncementRecipient N행 생성 (UNIQUE 보장)
        3. target_count 갱신, status='sent' (inapp 채널 즉시 마킹)

        실제 채널 발송 (kakao + 푸시)은 별도 큐 작업 — 본 메서드는 인앱
        recipient row 생성과 status 전이만 담당.
        """
        from app.models.academy import (
            AcademyMember,
            AcademyMemberRole,
            AcademyStudent,
            AcademyStudentStatus,
        )
        from app.models.academy_announcement import (
            AcademyAnnouncementRecipient,
            AcademyAnnouncementRecipientRole,
        )
        from app.services.academy_service import AcademyService

        announcement = await self.db.scalar(
            select(AcademyAnnouncement).where(AcademyAnnouncement.id == announcement_id)
        )
        if announcement is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Announcement not found")
        await AcademyService(self.db).assert_owner(announcement.academy_id, by_user_id)
        if announcement.status != ModelStatus.draft:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Cannot send announcement in status '{announcement.status.value}'",
            )

        # ---- 대상자 enumerate ----
        active_statuses = (AcademyStudentStatus.matched, AcademyStudentStatus.active)
        recipients: list[tuple[str, AcademyAnnouncementRecipientRole]] = []

        async def _add_teachers() -> None:
            teacher_users = await self.db.scalars(
                select(AcademyMember.user_id)
                .where(AcademyMember.academy_id == announcement.academy_id)
                .where(AcademyMember.role == AcademyMemberRole.teacher)
                .where(AcademyMember.access_revoked_at.is_(None))
            )
            for uid in teacher_users.all():
                recipients.append((uid, AcademyAnnouncementRecipientRole.teacher))

        async def _add_students_and_parents(*, students_only: bool = False, parents_only: bool = False) -> None:
            students_q = select(AcademyStudent).where(
                AcademyStudent.academy_id == announcement.academy_id,
                AcademyStudent.status.in_(active_statuses),
            )
            if announcement.audience == ModelAudience.teacher_students:
                tmid = (announcement.audience_filter or {}).get("teacher_member_id")
                if tmid:
                    students_q = students_q.where(AcademyStudent.teacher_member_id == tmid)
            rows = (await self.db.scalars(students_q)).all()
            for s in rows:
                if not parents_only and s.student_user_id:
                    recipients.append((s.student_user_id, AcademyAnnouncementRecipientRole.student))
                if not students_only and s.parent_user_id:
                    recipients.append((s.parent_user_id, AcademyAnnouncementRecipientRole.parent))

        if announcement.audience == ModelAudience.all:
            await _add_teachers()
            await _add_students_and_parents()
        elif announcement.audience == ModelAudience.teachers:
            await _add_teachers()
        elif announcement.audience == ModelAudience.students:
            await _add_students_and_parents(students_only=True)
        elif announcement.audience == ModelAudience.parents:
            await _add_students_and_parents(parents_only=True)
        elif announcement.audience == ModelAudience.teacher_students:
            await _add_students_and_parents()

        # ---- UNIQUE 보장 — 같은 user 중복 방지 (예: 학부모/학생 동일 user) ----
        seen: set[str] = set()
        deduped: list[tuple[str, AcademyAnnouncementRecipientRole]] = []
        for uid, role in recipients:
            if uid in seen:
                continue
            seen.add(uid)
            deduped.append((uid, role))

        # ---- Recipient N행 + status 전이 ----
        from datetime import UTC, datetime

        sent_at = datetime.now(UTC)
        inapp_enabled = "inapp" in (announcement.channels or [])
        for uid, role in deduped:
            self.db.add(
                AcademyAnnouncementRecipient(
                    announcement_id=announcement.id,
                    user_id=uid,
                    role=role,
                    delivered_at=sent_at if inapp_enabled else None,
                    inapp_delivered=inapp_enabled,
                )
            )

        announcement.status = ModelStatus.sent
        announcement.target_count = len(deduped)
        announcement.delivered_count = len(deduped) if inapp_enabled else 0
        announcement.sent_at = sent_at
        await self.db.commit()
        await self.db.refresh(announcement)
        return announcement

    # ------------------------------------------------------------------
    # Read flow — §6.1 인앱 읽음 표시
    # ------------------------------------------------------------------

    async def mark_read(
        self,
        *,
        announcement_id: str,
        user_id: str,
    ) -> "AcademyAnnouncementRecipient":  # noqa: F821 — string forward ref OK
        """수신자 본인이 공지를 열람한 시점을 기록 + read_count 갱신.

        멱등 — 이미 읽음 마킹된 경우 read_at 갱신 없이 반환.
        본인 행이 없으면 404 (수신 대상이 아님).
        """
        from app.models.academy_announcement import AcademyAnnouncementRecipient
        from datetime import UTC, datetime

        recipient = await self.db.scalar(
            select(AcademyAnnouncementRecipient)
            .where(AcademyAnnouncementRecipient.announcement_id == announcement_id)
            .where(AcademyAnnouncementRecipient.user_id == user_id)
        )
        if recipient is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not a recipient of this announcement")
        if recipient.read_at is not None:
            return recipient

        recipient.read_at = datetime.now(UTC)

        announcement = await self.db.scalar(
            select(AcademyAnnouncement).where(AcademyAnnouncement.id == announcement_id)
        )
        if announcement is not None:
            announcement.read_count = (announcement.read_count or 0) + 1

        await self.db.commit()
        await self.db.refresh(recipient)
        return recipient
