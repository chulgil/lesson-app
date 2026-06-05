"""Academy governance models — AC-M1 그룹 B 권한 계층.

Spec:
- ContextSwitchLog: docs/specs/web/academy/context_toggle_spec.md §3.3
- AcademyDelegation + AcademyDelegationAction: docs/specs/web/academy/temporary_delegation_spec.md §3
- AcademyActivityLog: docs/specs/web/academy/academy_schedule_authority_spec.md §2.4

책임:
- 학원장 ↔ 강사 모드 전환 audit (감사 영구 보존)
- 학원장 임시 권한 위임 + 모든 액션 audit
- 강사 활동 timeline (NFR-A-5 사후 가시성)

원칙:
- 모든 audit 행은 영구 보존 (분쟁 시 운영자 어드민 조회)
- 위임은 시간 제한 (영구 권한 부여 금지)
- actor_name 직접 저장 (강사 이름 변경 후에도 audit 보존)
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
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815


class AcademyContext(str, enum.Enum):
    """학원 컨텍스트 (context_toggle_spec §3.1)."""

    academy_owner = "academy_owner"
    teacher = "teacher"


class ContextSwitchTrigger(str, enum.Enum):
    """전환 트리거 (context_toggle_spec §3.3)."""

    user = "user"  # 학원장이 명시적 토글
    session_resume = "session_resume"  # 4h 만료 후 직전 컨텍스트 복원


class DelegationReason(str, enum.Enum):
    """위임 사유 (temporary_delegation_spec §3)."""

    trip = "trip"
    sick = "sick"
    vacation = "vacation"
    event = "event"
    other = "other"


class DelegationState(str, enum.Enum):
    """위임 상태 (temporary_delegation_spec §3)."""

    scheduled = "scheduled"  # 예약됨, 미시작
    active = "active"
    expired = "expired"
    revoked = "revoked"
    auto_ended = "auto_ended"


class DelegationRevokeReason(str, enum.Enum):
    """위임 종료 사유 (temporary_delegation_spec §6.1)."""

    owner_returned = "owner_returned"  # 학원장 콘솔 로그인 자동 감지
    owner_manual = "owner_manual"
    expired = "expired"
    delegatee_declined = "delegatee_declined"


class ContextSwitchLog(UUIDMixin, Base):
    """학원장 ↔ 강사 모드 전환 감사.

    영구 보존 — 학원 운영 분쟁 증거 + 노트 일시 접근 (R-AO-23) 사전 검증.
    """

    __tablename__ = "context_switch_logs"

    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    from_context: Mapped[AcademyContext] = mapped_column(
        Enum(AcademyContext, native_enum=True),
        nullable=False,
    )
    to_context: Mapped[AcademyContext] = mapped_column(
        Enum(AcademyContext, native_enum=True),
        nullable=False,
    )
    switched_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    ip: Mapped[str | None] = mapped_column(String(45), nullable=True)  # IPv4 or IPv6
    user_agent: Mapped[str | None] = mapped_column(String(500), nullable=True)
    triggered_by: Mapped[ContextSwitchTrigger] = mapped_column(
        Enum(ContextSwitchTrigger, native_enum=True),
        nullable=False,
        default=ContextSwitchTrigger.user,
    )

    __table_args__ = (
        Index("idx_context_switch_user_time", "user_id", "switched_at"),
        Index("idx_context_switch_academy_time", "academy_id", "switched_at"),
    )


class AcademyDelegation(UUIDMixin, TimestampMixin, Base):
    """학원장 → 위임받는 자 임시 권한.

    한 학원당 동시 1개 활성 위임만 (state in scheduled/active).
    """

    __tablename__ = "academy_delegations"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    delegator_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    delegatee_member_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_members.id", ondelete="RESTRICT"),
        nullable=False,
    )
    # 위임 권한 항목 (temporary_delegation_spec §2.1).
    # 예: ["billing.collect", "inbox.reply", "dashboard.view_only"]
    permissions: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ends_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    reason: Mapped[DelegationReason] = mapped_column(
        Enum(DelegationReason, native_enum=True),
        nullable=False,
    )
    reason_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    state: Mapped[DelegationState] = mapped_column(
        Enum(DelegationState, native_enum=True),
        nullable=False,
        default=DelegationState.scheduled,
    )
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    revoked_by_user_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    revoked_reason: Mapped[DelegationRevokeReason | None] = mapped_column(
        Enum(DelegationRevokeReason, native_enum=True),
        nullable=True,
    )
    # 학원장 비밀번호 재인증 여부 (temporary_delegation_spec §4.2).
    requires_password_at_start: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    notification_template_id: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        default="delegation_v1",
    )

    __table_args__ = (
        Index("idx_delegation_academy_state", "academy_id", "state"),
        Index("idx_delegation_delegatee", "delegatee_member_id"),
        Index("idx_delegation_ends_at", "ends_at"),  # 만료 cron 효율
    )


class AcademyDelegationAction(UUIDMixin, Base):
    """위임 활성 기간 동안 delegatee 가 수행한 액션 로그 (audit).

    임시 위임 종료 후 학원장이 검토 — owner_reviewed_at 마킹.
    영구 보존.
    """

    __tablename__ = "academy_delegation_actions"

    delegation_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_delegations.id", ondelete="CASCADE"),
        nullable=False,
    )
    performed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    performed_by_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    # 사용된 권한 항목 (예: "billing.collect").
    permission_used: Mapped[str] = mapped_column(String(50), nullable=False)
    # 호출된 endpoint (예: "POST /billing/payments").
    endpoint: Mapped[str] = mapped_column(String(200), nullable=False)
    target_resource_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    # 요청 핵심 정보 (PII 제외, JSON dict).
    request_summary: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    response_status: Mapped[int] = mapped_column(Integer, nullable=False)
    # 학원장 사후 검토 시각 (temporary_delegation_spec §7.1).
    owner_reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    owner_dispute_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_deleg_action_delegation_time", "delegation_id", "performed_at"),
        Index("idx_deleg_action_review_pending", "delegation_id", "owner_reviewed_at"),
    )


class AcademyActivityLog(UUIDMixin, Base):
    """강사 활동 timeline (academy_schedule_authority §2.4).

    학원장이 사후 가시성으로 강사 액션을 확인 (3차 무조건 위임 모델).
    actor_name 직접 저장 — 강사 이름 변경/퇴직 후에도 audit 보존.

    action_type 은 자유 문자열 (enum 아님). UI 가 알려진 값을 매핑:
    - lesson_created / lesson_completed / lesson_cancelled
    - subscription_issued / subscription_extended
    - student_enrolled / student_matched / student_paused
    - payment_confirmed
    - schedule_changed
    - note_added
    - lesson_request_accepted
    - makeup_recorded
    - vacation_registered
    - announcement_sent
    - 그 외는 UI 가 unknown 처리
    """

    __tablename__ = "academy_activity_logs"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    actor_member_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_members.id", ondelete="RESTRICT"),
        nullable=False,
    )
    # 강사 이름 스냅샷 (변경/퇴직 후에도 audit 보존).
    actor_name: Mapped[str] = mapped_column(String(100), nullable=False)
    action_type: Mapped[str] = mapped_column(String(50), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    # 타깃 리소스 (선택). 예: lesson_id, subscription_id 등.
    target_resource_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    target_resource_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    # 추가 메타데이터 (예: 변경 전/후 값).
    metadata_json: Mapped[dict | None] = mapped_column("metadata", JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        Index("idx_activity_log_academy_time", "academy_id", "created_at"),
        Index("idx_activity_log_actor_time", "actor_member_id", "created_at"),
        Index("idx_activity_log_action_type", "academy_id", "action_type", "created_at"),
    )


class ContextAccessDenialLog(UUIDMixin, Base):
    """권한 매트릭스 차단 audit (context_toggle_spec §6.3, §9).

    1년 보존. 컨텍스트 모드 위반 시 기록. 응답 detail.audit_id 가 본 행의 id.

    구조:
    - user_id (필수): 차단당한 user
    - active_context: 차단 시점의 JWT 페이로드 active_context (None 가능)
    - academy_id: 학원 관련 호출이면 채움 (None 가능)
    - denial_code: FORBIDDEN_TEACHER_SCOPE / FORBIDDEN_ACADEMY_OWNER_SCOPE / FORBIDDEN_NOT_YOUR_STUDENT
    - endpoint_path / http_method: 차단된 라우트
    - target_resource_id: 차단된 자원 id (학생 id 등)
    - denied_at: 차단 시각
    """

    __tablename__ = "context_access_denial_logs"

    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    active_context: Mapped[str | None] = mapped_column(String(20), nullable=True)
    academy_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=True,
    )
    denial_code: Mapped[str] = mapped_column(String(50), nullable=False)
    endpoint_path: Mapped[str] = mapped_column(String(200), nullable=False)
    http_method: Mapped[str] = mapped_column(String(10), nullable=False)
    target_resource_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    denied_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        Index("idx_context_denial_user_time", "user_id", "denied_at"),
        Index("idx_context_denial_academy_time", "academy_id", "denied_at"),
        Index("idx_context_denial_code_time", "denial_code", "denied_at"),
    )


__all__ = [
    "AcademyActivityLog",
    "AcademyContext",
    "AcademyDelegation",
    "AcademyDelegationAction",
    "ContextAccessDenialLog",
    "ContextSwitchLog",
    "ContextSwitchTrigger",
    "DelegationReason",
    "DelegationRevokeReason",
    "DelegationState",
]
