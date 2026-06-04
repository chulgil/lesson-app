"""Academy API schemas — AC-M1 그룹 A.

Spec: docs/specs/web/academy/README.md (AC-M1)
FE: docs/specs/academy/academy_master.md §4 Repository 계약.
"""

from __future__ import annotations

import datetime as _dt
import enum

from pydantic import BaseModel, ConfigDict, Field


class AcademyMemberRole(str, enum.Enum):
    owner = "owner"
    teacher = "teacher"


class AcademyStudentStatus(str, enum.Enum):
    waiting = "waiting"
    matched = "matched"
    active = "active"
    paused = "paused"
    alumni = "alumni"


class AcademyInviteState(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    declined = "declined"
    expired = "expired"
    revoked = "revoked"


# ---------------------------------------------------------------------------
# Academy
# ---------------------------------------------------------------------------


class AcademyCreate(BaseModel):
    """학원 신규 생성 (학원장이 본인 학원 등록).

    UX 원칙: 학원장이 학원장+겸직강사 인 흔한 케이스를 1회 호출로 끝낼 수 있도록
    `also_register_as_teacher=true` 옵션 제공. true 면 owner + teacher 두 멤버 행 자동 생성.
    """

    slug: str = Field(min_length=2, max_length=100, pattern=r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
    name: str = Field(min_length=1, max_length=200)
    business_number: str | None = Field(default=None, max_length=20)
    phone: str | None = Field(default=None, max_length=30)
    address: str | None = Field(default=None, max_length=500)
    description: str | None = None
    timezone: str = "Asia/Seoul"
    locale: str = "ko"
    # 1탭 onboarding — 학원장 본인이 겸직 강사로도 등록 (소규모 음악학원 흔한 패턴).
    also_register_as_teacher: bool = False


class AcademyUpdate(BaseModel):
    """학원 기본 정보 수정 (학원장만). slug 변경은 별도 절차 (재발급)."""

    name: str | None = Field(default=None, min_length=1, max_length=200)
    business_number: str | None = Field(default=None, max_length=20)
    phone: str | None = Field(default=None, max_length=30)
    address: str | None = Field(default=None, max_length=500)
    description: str | None = None
    timezone: str | None = None
    locale: str | None = None


class AcademyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    slug: str
    name: str
    owner_user_id: str
    business_number: str | None = None
    phone: str | None = None
    address: str | None = None
    description: str | None = None
    timezone: str
    locale: str
    created_at: _dt.datetime
    updated_at: _dt.datetime


# ---------------------------------------------------------------------------
# AcademyMember
# ---------------------------------------------------------------------------


class AcademyMemberResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    user_id: str
    role: AcademyMemberRole
    public_page_consent: bool
    onboarding_until: _dt.datetime | None = None
    access_revoked_at: _dt.datetime | None = None
    delegate_role: str
    delegate_role_granted_at: _dt.datetime | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime


class AcademyMemberListResponse(BaseModel):
    members: list[AcademyMemberResponse] = []
    total_count: int


class AcademyMemberConsentUpdate(BaseModel):
    """강사가 본인 public_page_consent 토글."""

    public_page_consent: bool


# ---------------------------------------------------------------------------
# AcademyStudent
# ---------------------------------------------------------------------------


class AcademyStudentCreate(BaseModel):
    """학원장이 학생 신규 등록 (lesson-app 가입 전이라도 가능)."""

    name: str = Field(min_length=1, max_length=100)
    instrument: str | None = Field(default=None, max_length=50)
    teacher_member_id: str | None = None  # 매칭 강사 (waiting 이면 null)
    student_user_id: str | None = None  # 학생 본인 lesson-app 가입 시 연결
    parent_user_id: str | None = None
    intake_notes: str | None = None
    deposit_code: str | None = Field(default=None, max_length=30)


class AcademyStudentUpdate(BaseModel):
    """학원장이 학생 정보 수정."""

    name: str | None = Field(default=None, min_length=1, max_length=100)
    instrument: str | None = Field(default=None, max_length=50)
    teacher_member_id: str | None = None
    student_user_id: str | None = None
    parent_user_id: str | None = None
    status: AcademyStudentStatus | None = None
    intake_notes: str | None = None
    deposit_code: str | None = Field(default=None, max_length=30)


class AcademyStudentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    student_user_id: str | None = None
    parent_user_id: str | None = None
    teacher_member_id: str | None = None
    name: str
    instrument: str | None = None
    status: AcademyStudentStatus
    registered_at: _dt.datetime
    matched_at: _dt.datetime | None = None
    status_changed_at: _dt.datetime | None = None
    intake_notes: str | None = None
    deposit_code: str | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime


class AcademyStudentListResponse(BaseModel):
    students: list[AcademyStudentResponse] = []
    total_count: int


# ---------------------------------------------------------------------------
# AcademyInvite
# ---------------------------------------------------------------------------


class AcademyInviteCreate(BaseModel):
    """학원장이 강사 초대 발급. target_* 는 사전 통보된 강사 식별 (선택)."""

    roles: list[AcademyMemberRole] = Field(default_factory=lambda: [AcademyMemberRole.teacher])
    target_email: str | None = Field(default=None, max_length=255)
    target_phone: str | None = Field(default=None, max_length=30)
    expires_in_hours: int = Field(default=168, ge=1, le=720)  # 기본 7일, 최대 30일
    note: str | None = None


class AcademyInviteResponse(BaseModel):
    """학원장에게 반환 — token 원문은 발급 시 1회만."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    invited_by_user_id: str
    roles: list[str]
    target_email: str | None = None
    target_phone: str | None = None
    expires_at: _dt.datetime
    state: AcademyInviteState
    accepted_at: _dt.datetime | None = None
    declined_at: _dt.datetime | None = None
    revoked_at: _dt.datetime | None = None
    accepted_member_id: str | None = None
    note: str | None = None
    created_at: _dt.datetime


class AcademyInviteCreatedResponse(AcademyInviteResponse):
    """발급 직후 응답 — token 원문 1회 노출."""

    token: str  # 원문 (DB 에는 hash 만 저장)
    share_url: str | None = None


class AcademyInviteListResponse(BaseModel):
    invites: list[AcademyInviteResponse] = []
    total_count: int


class AcademyInvitePreview(BaseModel):
    """공개 endpoint — 토큰 미리보기 (학원/역할 최소 정보, 학원장 PII 마스킹)."""

    academy_id: str
    academy_name: str
    academy_slug: str
    roles: list[str]
    invited_by_name: str  # 학원장 이름 (성씨만 노출)
    expires_at: _dt.datetime
    is_expired: bool


class AcademyInviteAcceptRequest(BaseModel):
    """강사가 토큰 수락 시 공개 페이지 노출 동의 여부."""

    public_page_consent: bool = False


class AcademyInviteRejectRequest(BaseModel):
    reason: str | None = Field(default=None, max_length=500)
