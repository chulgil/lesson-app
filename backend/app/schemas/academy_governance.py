"""Academy governance API schemas — AC-M1 그룹 B.

Spec:
- ContextSwitchLog: context_toggle_spec §3.3
- AcademyDelegation: temporary_delegation_spec §4
- AcademyDelegationAction: temporary_delegation_spec §7
- AcademyActivityLog: academy_schedule_authority §4
"""

from __future__ import annotations

import datetime as _dt
import enum

from pydantic import BaseModel, ConfigDict, Field


class AcademyContext(str, enum.Enum):
    academy_owner = "academy_owner"
    teacher = "teacher"


class ContextSwitchTrigger(str, enum.Enum):
    user = "user"
    session_resume = "session_resume"


class DelegationReason(str, enum.Enum):
    trip = "trip"
    sick = "sick"
    vacation = "vacation"
    event = "event"
    other = "other"


class DelegationState(str, enum.Enum):
    scheduled = "scheduled"
    active = "active"
    expired = "expired"
    revoked = "revoked"
    auto_ended = "auto_ended"


class DelegationRevokeReason(str, enum.Enum):
    owner_returned = "owner_returned"
    owner_manual = "owner_manual"
    expired = "expired"
    delegatee_declined = "delegatee_declined"


# ---------------------------------------------------------------------------
# ContextSwitchLog
# ---------------------------------------------------------------------------


class ContextSwitchLogResponse(BaseModel):
    """조회 only — 시스템이 토글 시점에 자동 기록."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    academy_id: str
    from_context: AcademyContext
    to_context: AcademyContext
    switched_at: _dt.datetime
    ip: str | None = None
    user_agent: str | None = None
    triggered_by: ContextSwitchTrigger


class ContextSwitchLogListResponse(BaseModel):
    logs: list[ContextSwitchLogResponse] = []
    total_count: int


class ContextAccessDenialLogResponse(BaseModel):
    """조회 only — 권한 매트릭스 차단 시 시스템이 자동 기록 (§6.3, §9)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    active_context: str | None = None
    academy_id: str | None = None
    denial_code: str
    endpoint_path: str
    http_method: str
    target_resource_id: str | None = None
    denied_at: _dt.datetime


class ContextAccessDenialLogListResponse(BaseModel):
    logs: list[ContextAccessDenialLogResponse] = []
    total_count: int


# ---------------------------------------------------------------------------
# AcademyDelegation
# ---------------------------------------------------------------------------


class AcademyDelegationCreate(BaseModel):
    """학원장이 위임 시작 (UX: 1액션 — 권한 토글 + 명시 동의 1회).

    permissions 항목 (temporary_delegation_spec §2.1):
    - billing.collect / billing.settle / inbox.reply / announcement.send
    - schedule.bulk_change / dashboard.view_only / student.contact

    재인증: 현 시스템이 OAuth 기반이라 비밀번호 직접 검증 미지원.
    명시 confirmation 토글로 대체. 향후 PIN/SMS 도입 시 보강 (Year 2).
    """

    delegatee_member_id: str
    permissions: list[str] = Field(min_length=1)  # 최소 1개 권한
    starts_at: _dt.datetime
    ends_at: _dt.datetime  # 필수 — 영구 위임 금지
    reason: DelegationReason
    reason_note: str | None = None
    # 학원장 명시 동의 — UI 가 "동의합니다" 토글 + 권한 차이 안내 다이얼로그 후 true.
    confirmation: bool = Field(default=False)


class AcademyDelegationRevokeRequest(BaseModel):
    """학원장 수기 종료."""

    note: str | None = None


class AcademyDelegationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    delegator_user_id: str
    delegatee_member_id: str
    permissions: list[str]
    starts_at: _dt.datetime
    ends_at: _dt.datetime
    reason: DelegationReason
    reason_note: str | None = None
    state: DelegationState
    revoked_at: _dt.datetime | None = None
    revoked_by_user_id: str | None = None
    revoked_reason: DelegationRevokeReason | None = None
    requires_password_at_start: bool
    notification_template_id: str
    created_at: _dt.datetime
    updated_at: _dt.datetime


class AcademyDelegationListResponse(BaseModel):
    delegations: list[AcademyDelegationResponse] = []
    total_count: int


# ---------------------------------------------------------------------------
# AcademyDelegationAction
# ---------------------------------------------------------------------------


class AcademyDelegationActionResponse(BaseModel):
    """위임 액션 audit — 시스템이 middleware 에서 자동 기록."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    delegation_id: str
    performed_at: _dt.datetime
    performed_by_user_id: str
    permission_used: str
    endpoint: str
    target_resource_id: str | None = None
    request_summary: dict | None = None
    response_status: int
    owner_reviewed_at: _dt.datetime | None = None
    owner_dispute_note: str | None = None


class AcademyDelegationActionListResponse(BaseModel):
    actions: list[AcademyDelegationActionResponse] = []
    total_count: int
    pending_review_count: int  # 학원장 검토 대기 수


class AcademyDelegationActionReviewRequest(BaseModel):
    """학원장 사후 검토 (UX: 전체 승인 또는 개별 이의 제기).

    bulk_approve=true 면 action_ids 의 모든 행 owner_reviewed_at 마킹.
    bulk_approve=false 면 개별 (action_id, dispute_note) 처리.
    """

    action_ids: list[str] = Field(min_length=1)
    bulk_approve: bool = True
    dispute_note: str | None = None  # bulk_approve=false 시 적용


# ---------------------------------------------------------------------------
# AcademyActivityLog
# ---------------------------------------------------------------------------


class AcademyActivityLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    actor_member_id: str
    actor_name: str
    action_type: str
    description: str
    target_resource_type: str | None = None
    target_resource_id: str | None = None
    metadata_json: dict | None = None
    created_at: _dt.datetime


class AcademyActivityLogListResponse(BaseModel):
    activities: list[AcademyActivityLogResponse] = []
    total_count: int
