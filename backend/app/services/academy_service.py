"""Academy service — AC-M1 그룹 A.

Spec: docs/specs/web/academy/README.md (AC-M1) + docs/specs/academy/academy_master.md §4.

책임:
- Academy CRUD (학원 자체)
- AcademyMember 조회/공개 동의 토글/access_revoked
- AcademyStudent CRUD
- AcademyInvite 발급 (token hash) / 조회 / 수락 / 거절 / 회수

Notes:
- raw token 은 발급 시 1회만 반환. DB 는 sha256 hash 저장.
- 라우터는 본 서비스로 위임 (architecture contract: API → service → DB).
"""

from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academy import (
    Academy,
    AcademyInvite,
    AcademyInviteState,
    AcademyMember,
    AcademyMemberRole,
    AcademyStudent,
    AcademyStudentStatus,
)
from app.models.user import User
from app.schemas.academy import (
    AcademyCreate,
    AcademyInviteCreate,
    AcademyInvitePreview,
    AcademyStudentCreate,
    AcademyStudentUpdate,
    AcademyUpdate,
)


def _utcnow() -> datetime:
    return datetime.now(UTC)


def _ensure_aware(dt: datetime) -> datetime:
    """SQLite 에서 가져온 naive datetime 을 UTC aware 로. PG 는 이미 aware."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _generate_token() -> str:
    """URL-safe 32-byte token. 충분히 unguessable."""
    return secrets.token_urlsafe(32)


def _mask_owner_name(name: str | None) -> str:
    """공개 preview 용 학원장 이름 마스킹 (성씨만)."""
    if not name:
        return "(이름 없음)"
    return name[0] + ("*" * max(len(name) - 1, 1))


class AcademyService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Academy
    # ------------------------------------------------------------------

    async def create_academy(self, *, owner_user_id: str, body: AcademyCreate) -> Academy:
        existing_slug = await self.db.scalar(select(Academy.id).where(Academy.slug == body.slug))
        if existing_slug is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"slug already taken: {body.slug}",
            )
        academy = Academy(
            slug=body.slug,
            name=body.name,
            owner_user_id=owner_user_id,
            business_number=body.business_number,
            phone=body.phone,
            address=body.address,
            description=body.description,
            timezone=body.timezone,
            locale=body.locale,
        )
        self.db.add(academy)
        await self.db.flush()
        # 학원장은 자동으로 owner 멤버.
        owner_member = AcademyMember(
            academy_id=academy.id,
            user_id=owner_user_id,
            role=AcademyMemberRole.owner,
            public_page_consent=False,
        )
        self.db.add(owner_member)
        # UX 1탭 onboarding — 옵션 시 본인을 teacher 도 함께 등록.
        if body.also_register_as_teacher:
            teacher_member = AcademyMember(
                academy_id=academy.id,
                user_id=owner_user_id,
                role=AcademyMemberRole.teacher,
                public_page_consent=False,
            )
            self.db.add(teacher_member)
        await self.db.flush()
        return academy

    async def get_academy(self, academy_id: str) -> Academy:
        academy = await self.db.get(Academy, academy_id)
        if academy is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academy not found")
        return academy

    async def get_academy_by_slug(self, slug: str) -> Academy:
        academy = await self.db.scalar(select(Academy).where(Academy.slug == slug))
        if academy is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academy not found")
        return academy

    async def update_academy(self, *, academy_id: str, body: AcademyUpdate) -> Academy:
        academy = await self.get_academy(academy_id)
        for field, value in body.model_dump(exclude_unset=True).items():
            setattr(academy, field, value)
        await self.db.flush()
        return academy

    async def list_academies_for_user(self, user_id: str) -> list[Academy]:
        """사용자가 활성 멤버로 속한 모든 학원."""
        stmt = (
            select(Academy)
            .join(AcademyMember, AcademyMember.academy_id == Academy.id)
            .where(AcademyMember.user_id == user_id)
            .where(AcademyMember.access_revoked_at.is_(None))
            .distinct()
            .order_by(Academy.name)
        )
        result = await self.db.scalars(stmt)
        return list(result.all())

    async def assert_owner(self, academy_id: str, user_id: str) -> None:
        """학원장 권한 확인. 본인이 학원장이 아니면 403."""
        member_id = await self.db.scalar(
            select(AcademyMember.id)
            .where(AcademyMember.academy_id == academy_id)
            .where(AcademyMember.user_id == user_id)
            .where(AcademyMember.role == AcademyMemberRole.owner)
            .where(AcademyMember.access_revoked_at.is_(None))
        )
        if member_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Owner access required for this academy",
            )

    # ------------------------------------------------------------------
    # AcademyMember
    # ------------------------------------------------------------------

    async def list_members(
        self,
        *,
        academy_id: str,
        role: AcademyMemberRole | None = None,
        include_revoked: bool = False,
    ) -> tuple[list[AcademyMember], int]:
        stmt = select(AcademyMember).where(AcademyMember.academy_id == academy_id)
        if role is not None:
            stmt = stmt.where(AcademyMember.role == role)
        if not include_revoked:
            stmt = stmt.where(AcademyMember.access_revoked_at.is_(None))
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyMember.created_at))
        return list(result.all()), total

    async def get_member(self, member_id: str) -> AcademyMember:
        member = await self.db.get(AcademyMember, member_id)
        if member is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")
        return member

    async def update_consent(self, *, member_id: str, by_user_id: str, public_page_consent: bool) -> AcademyMember:
        member = await self.get_member(member_id)
        if member.user_id != by_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the member themselves can change consent",
            )
        member.public_page_consent = public_page_consent
        await self.db.flush()
        return member

    async def revoke_member_access(self, *, member_id: str, by_user_id: str) -> AcademyMember:
        member = await self.get_member(member_id)
        await self.assert_owner(member.academy_id, by_user_id)
        if member.access_revoked_at is not None:
            return member  # idempotent
        member.access_revoked_at = _utcnow()
        await self.db.flush()
        return member

    # ------------------------------------------------------------------
    # AcademyStudent
    # ------------------------------------------------------------------

    async def create_student(self, *, academy_id: str, by_user_id: str, body: AcademyStudentCreate) -> AcademyStudent:
        await self.assert_owner(academy_id, by_user_id)
        if body.teacher_member_id is not None:
            teacher = await self.db.get(AcademyMember, body.teacher_member_id)
            if teacher is None or teacher.academy_id != academy_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="teacher_member_id not in this academy",
                )
        now = _utcnow()
        status_value = AcademyStudentStatus.matched if body.teacher_member_id else AcademyStudentStatus.waiting
        student = AcademyStudent(
            academy_id=academy_id,
            student_user_id=body.student_user_id,
            parent_user_id=body.parent_user_id,
            teacher_member_id=body.teacher_member_id,
            name=body.name,
            instrument=body.instrument,
            status=status_value,
            registered_at=now,
            matched_at=now if body.teacher_member_id else None,
            status_changed_at=now,
            intake_notes=body.intake_notes,
            deposit_code=body.deposit_code,
        )
        self.db.add(student)
        await self.db.flush()
        return student

    async def list_students(
        self, *, academy_id: str, status_filter: AcademyStudentStatus | None = None
    ) -> tuple[list[AcademyStudent], int]:
        stmt = select(AcademyStudent).where(AcademyStudent.academy_id == academy_id)
        if status_filter is not None:
            stmt = stmt.where(AcademyStudent.status == status_filter)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyStudent.registered_at.desc()))
        return list(result.all()), total

    async def get_student(self, student_id: str) -> AcademyStudent:
        student = await self.db.get(AcademyStudent, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
        return student

    async def update_student(self, *, student_id: str, by_user_id: str, body: AcademyStudentUpdate) -> AcademyStudent:
        student = await self.get_student(student_id)
        await self.assert_owner(student.academy_id, by_user_id)
        updates = body.model_dump(exclude_unset=True)
        if "status" in updates and updates["status"] != student.status:
            student.status_changed_at = _utcnow()
        if "teacher_member_id" in updates and updates["teacher_member_id"] != student.teacher_member_id:
            student.matched_at = _utcnow() if updates["teacher_member_id"] else None
        for field, value in updates.items():
            setattr(student, field, value)
        await self.db.flush()
        return student

    # ------------------------------------------------------------------
    # AcademyInvite
    # ------------------------------------------------------------------

    async def create_invite(
        self, *, academy_id: str, by_user_id: str, body: AcademyInviteCreate
    ) -> tuple[AcademyInvite, str]:
        """초대 발급. 반환: (invite, raw_token). raw_token 은 1회만 노출."""
        await self.assert_owner(academy_id, by_user_id)
        raw_token = _generate_token()
        invite = AcademyInvite(
            academy_id=academy_id,
            invited_by_user_id=by_user_id,
            token_hash=_hash_token(raw_token),
            roles=[r.value for r in body.roles],
            target_email=body.target_email,
            target_phone=body.target_phone,
            expires_at=_utcnow() + timedelta(hours=body.expires_in_hours),
            state=AcademyInviteState.pending,
            note=body.note,
        )
        self.db.add(invite)
        await self.db.flush()
        return invite, raw_token

    async def get_preview_by_token(self, raw_token: str) -> AcademyInvitePreview:
        """공개 endpoint — 인증 X. 만료/사용 토큰도 안내용으로 응답."""
        invite = await self.db.scalar(select(AcademyInvite).where(AcademyInvite.token_hash == _hash_token(raw_token)))
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        academy = await self.db.get(Academy, invite.academy_id)
        if academy is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academy not found")
        inviter = await self.db.get(User, invite.invited_by_user_id)
        inviter_name = _mask_owner_name(inviter.name if inviter else None)
        from app.schemas.academy import AcademyResponse as _AcademyResponse

        return AcademyInvitePreview(
            token=raw_token,
            academy=_AcademyResponse.model_validate(academy),
            owner_name=inviter_name,
            roles=list(invite.roles or []),
            expires_at=invite.expires_at,
            is_expired=_ensure_aware(invite.expires_at) < _utcnow() or invite.state != AcademyInviteState.pending,
        )

    async def accept_invite(self, *, raw_token: str, by_user_id: str, public_page_consent: bool) -> AcademyMember:
        invite = await self._load_active_invite(raw_token)
        # role 별 멤버 생성 (겸직이면 행 2개).
        created_members: list[AcademyMember] = []
        now = _utcnow()
        for role_value in invite.roles or []:
            try:
                role = AcademyMemberRole(role_value)
            except ValueError:
                continue  # 알 수 없는 role 은 무시
            existing = await self.db.scalar(
                select(AcademyMember)
                .where(AcademyMember.academy_id == invite.academy_id)
                .where(AcademyMember.user_id == by_user_id)
                .where(AcademyMember.role == role)
            )
            if existing is not None:
                if existing.access_revoked_at is not None:
                    existing.access_revoked_at = None  # 재합류
                created_members.append(existing)
                continue
            member = AcademyMember(
                academy_id=invite.academy_id,
                user_id=by_user_id,
                role=role,
                public_page_consent=public_page_consent if role == AcademyMemberRole.teacher else False,
            )
            self.db.add(member)
            created_members.append(member)
        await self.db.flush()
        invite.state = AcademyInviteState.accepted
        invite.accepted_at = now
        invite.accepted_member_id = created_members[0].id if created_members else None
        await self.db.flush()
        # 첫 번째 멤버 (보통 teacher) 반환.
        return created_members[0]

    async def decline_invite(self, *, raw_token: str, reason: str | None = None) -> AcademyInvite:
        invite = await self._load_active_invite(raw_token)
        invite.state = AcademyInviteState.declined
        invite.declined_at = _utcnow()
        if reason:
            invite.note = (invite.note or "") + f"\n[declined] {reason}"
        await self.db.flush()
        return invite

    async def revoke_invite(self, *, invite_id: str, by_user_id: str) -> AcademyInvite:
        invite = await self.db.get(AcademyInvite, invite_id)
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        await self.assert_owner(invite.academy_id, by_user_id)
        if invite.state != AcademyInviteState.pending:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Invite is {invite.state.value}, cannot revoke",
            )
        invite.state = AcademyInviteState.revoked
        invite.revoked_at = _utcnow()
        await self.db.flush()
        return invite

    async def list_invites(
        self, *, academy_id: str, state_filter: AcademyInviteState | None = None
    ) -> tuple[list[AcademyInvite], int]:
        stmt = select(AcademyInvite).where(AcademyInvite.academy_id == academy_id)
        if state_filter is not None:
            stmt = stmt.where(AcademyInvite.state == state_filter)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyInvite.created_at.desc()))
        return list(result.all()), total

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    async def _load_active_invite(self, raw_token: str) -> AcademyInvite:
        invite = await self.db.scalar(select(AcademyInvite).where(AcademyInvite.token_hash == _hash_token(raw_token)))
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        now = _utcnow()
        if invite.state == AcademyInviteState.pending and _ensure_aware(invite.expires_at) < now:
            invite.state = AcademyInviteState.expired
            await self.db.flush()
        if invite.state != AcademyInviteState.pending:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Invite is {invite.state.value}",
            )
        return invite


__all__ = ["AcademyService"]
