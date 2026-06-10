"""User-related schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, Field


class UserResponse(BaseModel):
    """Public user representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str | None = None
    name: str | None = None
    phone: str | None = None
    role: str | None = None
    profile_image_url: str | None = None
    locale: str | None = None
    country: str | None = None
    timezone: str | None = None
    currency: str | None = None
    onboarding_completed: bool = False
    # #430 G1 B2 — phone_verification_policy.md §5.2
    terms_accepted_at: _dt.datetime | None = None
    marketing_consent_at: _dt.datetime | None = None
    # #608 Job 7 — §13 퀘스트 시스템: 11/11 완료 축하 카드 1회 표시 보장
    quest_celebrated_at: _dt.datetime | None = None
    created_at: _dt.datetime | None = None


class TermsConsentRequest(BaseModel):
    """#430 G1 B2 — 약관 동의 기록 요청.

    필수 묶음(서비스 이용약관 + 개인정보 처리방침) 은 본 요청 자체로
    동의된 것으로 간주된다(클라이언트는 필수 미체크 시 요청 자체를 보내지
    않는다). 마케팅 정보 수신은 정보통신망법 제50조에 따라 별도 필드로
    기록한다.
    """

    marketing_consent: bool = False


class UserUpdate(BaseModel):
    """Fields that a user can update on their own profile."""

    name: str | None = None
    phone: str | None = None
    profile_image_url: str | None = None


class RoleUpdate(BaseModel):
    """Update user role (used during onboarding)."""

    role: str


class LocaleUpdate(BaseModel):
    """Update locale / country / timezone / currency settings."""

    locale: str | None = None
    country: str | None = None
    timezone: str | None = None
    currency: str | None = None


class SupportedLocale(BaseModel):
    """Single supported locale entry."""

    locale: str
    language_name: str
    native_name: str
    default_country: str


class SupportedLocalesResponse(BaseModel):
    """List of supported locales."""

    locales: list[SupportedLocale]


class OnboardingQuestResponse(BaseModel):
    """Single onboarding quest state."""

    id: str
    title: str
    description: str
    category: str
    status: str
    completed_at: _dt.datetime | None = None
    celebration_message: str | None = None


class OnboardingProgressUpdate(BaseModel):
    """Patch onboarding progress state."""

    current_phase: str | None = None
    profile_completeness: int | None = None
    walkthrough_skipped: bool | None = None
    coach_marks_seen: dict[str, bool] | None = None
    coach_marks_dismissed: dict[str, bool] | None = None


class OnboardingProgressResponse(BaseModel):
    """Onboarding v2 progress response."""

    user_id: str
    role: str | None = None
    current_phase: str
    quests: list[OnboardingQuestResponse]
    profile_completeness: int
    walkthrough_skipped: bool
    coach_marks_seen: dict[str, bool] = Field(default_factory=dict)
    coach_marks_dismissed: dict[str, bool] = Field(default_factory=dict)
    started_at: _dt.datetime
    completed_at: _dt.datetime | None = None
    completed_quest_count: int
    total_required_quests: int
    is_all_required_completed: bool
    progress_percentage: float


class OnboardingQuestListResponse(BaseModel):
    """List of quests for the current user."""

    quests: list[OnboardingQuestResponse]
