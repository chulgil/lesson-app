"""Academy domain models — AC-M1 그룹 A 핵심 도메인.

Spec: docs/specs/web/academy/README.md (마일스톤 AC-M1)
- Academy: 학원 기본 정보 (1 학원 = 1 행)
- AcademyMember: 학원 소속 (학원장/강사). 기존 User 도메인 재사용.
- AcademyStudent: 학원 학생 (lesson-app User 와 선택적 연결)
- AcademyInvite: 강사 초대 토큰

Policy:
- AcademyMember.user_id 는 기존 users 테이블 FK (필수). 별도 조직 계정 시스템 도입 안 함.
- AcademyStudent.student_user_id, parent_user_id 는 nullable (학원만 등록한 학생 / 학부모 미가입 케이스).
- access_revoked_at: 강사 퇴직 시 NULL → datetime. 자기 자신 노트 접근 차단.
- AcademyInvite.token 은 hashing 권장 (서비스 레이어에서 hash + verify).

Glossary: .harness/knowledge/glossary.md §학원(Academy) 도메인.
"""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815


class AcademyMemberRole(str, enum.Enum):
    """학원 멤버 역할. spec: academy_master.md §3.2."""

    owner = "owner"
    teacher = "teacher"


class AcademyStudentStatus(str, enum.Enum):
    """학원 학생 라이프사이클. spec: academy_master.md §3.2.

    waiting: 등록 대기 (강사 매칭 전)
    matched: 강사 매칭됨, 첫 수업 전
    active: 정규 수업 진행 중
    paused: 일시 중단 (휴학, 일시 부재)
    alumni: 퇴원 / 졸업
    """

    waiting = "waiting"
    matched = "matched"
    active = "active"
    paused = "paused"
    alumni = "alumni"


class AcademyInviteState(str, enum.Enum):
    """강사 초대 상태. spec: academy_master.md §2.2 + temporary_delegation_spec."""

    pending = "pending"
    accepted = "accepted"
    declined = "declined"
    expired = "expired"
    revoked = "revoked"


class Academy(UUIDMixin, TimestampMixin, Base):
    """학원 1개 = 1 행. SoR for academy basic info."""

    __tablename__ = "academies"

    slug: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    owner_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    # Optional contact / business info.
    business_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    address: Mapped[str | None] = mapped_column(String(500), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Timezone / locale (UI 기본값 + 외부 API 호출 기준).
    timezone: Mapped[str] = mapped_column(String(50), nullable=False, default="Asia/Seoul")
    locale: Mapped[str] = mapped_column(String(10), nullable=False, default="ko")

    __table_args__ = (
        Index("idx_academies_owner", "owner_user_id"),
        Index("idx_academies_slug", "slug"),
    )


class AcademyMember(UUIDMixin, TimestampMixin, Base):
    """학원 소속 (학원장 또는 강사). 1 user × 1 academy × 1 role = 1 행.

    한 user 가 같은 academy 에서 owner + teacher 겸직하면 행 2개.
    """

    __tablename__ = "academy_members"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    role: Mapped[AcademyMemberRole] = mapped_column(
        Enum(AcademyMemberRole, native_enum=True),
        nullable=False,
    )
    # 공개 페이지 (academy.lessonaza.app/{slug}) 노출 동의.
    # 기본 false — 강사 본인이 명시 동의 토글 (public_page_spec).
    public_page_consent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    # 수습 강사 onboarding 기한. academy_schedule_authority §5.
    # 기간 중 학생 매칭 제한 / activity 추가 표식.
    onboarding_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # 퇴직 처리 시각. NULL 이면 활성, datetime 있으면 권한 차단.
    # teacher_offboarding_spec §8.1.
    access_revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # 매니저 영구 위임 패턴 (temporary_delegation_spec §8).
    # "trusted_substitute" 인 경우 학원장 위임 시 비밀번호 1회만.
    delegate_role: Mapped[str] = mapped_column(String(30), nullable=False, default="none")
    delegate_role_granted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        # 한 user 가 같은 학원 같은 role 로 2번 등록 차단.
        Index("uk_academy_members_acad_user_role", "academy_id", "user_id", "role", unique=True),
        Index("idx_academy_members_user", "user_id"),
        Index("idx_academy_members_academy_role", "academy_id", "role"),
    )


class AcademyStudent(UUIDMixin, TimestampMixin, Base):
    """학원 학생. lesson-app User 와 선택적 연결 (학원만 등록 가능).

    SoR: 학원이 등록한 학생 정보. lesson-app 가입 시 student_user_id 연결.
    학부모 가입 시 parent_user_id 연결.
    """

    __tablename__ = "academy_students"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    # lesson-app User 와 연결. NULL = 학원만 등록 (학생 본인 미가입).
    student_user_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    # 학부모 User 와 연결. NULL = 학부모 미가입.
    parent_user_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    # 매칭 강사. waiting 상태에서는 NULL.
    teacher_member_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("academy_members.id", ondelete="SET NULL"),
        nullable=True,
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
    status: Mapped[AcademyStudentStatus] = mapped_column(
        Enum(AcademyStudentStatus, native_enum=True),
        nullable=False,
        default=AcademyStudentStatus.waiting,
    )
    registered_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    matched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status_changed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # 학원장이 학생 등록 시 입력하는 사전 정보 (학년·연락처 등).
    intake_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    # 입금자 매칭 보조 메모 코드 (payment_matching_spec §3.5).
    deposit_code: Mapped[str | None] = mapped_column(String(30), nullable=True)

    __table_args__ = (
        Index("idx_academy_students_academy_status", "academy_id", "status"),
        Index("idx_academy_students_teacher", "teacher_member_id"),
        Index("idx_academy_students_student_user", "student_user_id"),
        Index("idx_academy_students_parent_user", "parent_user_id"),
    )


class AcademyInvite(UUIDMixin, TimestampMixin, Base):
    """강사 초대 토큰. spec: academy_master.md §2.2.

    학원장이 강사를 초대. token 은 서비스 레이어에서 hash 처리 (raw 저장 X).
    """

    __tablename__ = "academy_invites"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    invited_by_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    # Hashed token. 원문은 발급 시 1회만 학원장에게 노출.
    token_hash: Mapped[str] = mapped_column(String(128), nullable=False, unique=True)
    # 초대 받는 사람의 역할 ["owner"] | ["teacher"] | ["owner", "teacher"] (겸직).
    roles: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    # 선택적 타깃 (사전 통보된 강사). 없으면 누구나 토큰 보유 시 수락 가능.
    target_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    target_phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    state: Mapped[AcademyInviteState] = mapped_column(
        Enum(AcademyInviteState, native_enum=True),
        nullable=False,
        default=AcademyInviteState.pending,
    )
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    declined_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # 수락한 멤버 (state=accepted 시 채워짐).
    accepted_member_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("academy_members.id", ondelete="SET NULL"),
        nullable=True,
    )
    # 학원장 메모 (선택).
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Issue #632 — 거절 사유 (declined 상태일 때 사용자가 입력).
    declined_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_academy_invites_academy_state", "academy_id", "state"),
        Index("idx_academy_invites_expires", "expires_at"),
    )


__all__ = [
    "Academy",
    "AcademyInvite",
    "AcademyInviteState",
    "AcademyMember",
    "AcademyMemberRole",
    "AcademyStudent",
    "AcademyStudentStatus",
]
