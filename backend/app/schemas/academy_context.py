"""Academy context (학원장 ↔ 강사 모드 전환) API schemas.

Spec: docs/specs/web/academy/context_toggle_spec.md §4.
"""

from __future__ import annotations

import enum

from pydantic import BaseModel, Field


class AcademyContext(str, enum.Enum):
    academy_owner = "academy_owner"
    teacher = "teacher"


class ContextSwitchRequest(BaseModel):
    """POST /auth/context/switch body."""

    target_context: AcademyContext
    academy_id: str


class ContextSwitchResponse(BaseModel):
    """새 JWT + redirect 정보. context_toggle_spec §4.1 응답."""

    access_token: str
    active_context: AcademyContext
    academy_id: str
    teacher_id: str | None = None
    member_id: str
    # 어디로 이동할지 클라이언트 힌트 — UX 자동 redirect.
    redirect_url: str | None = None


class AvailableContext(BaseModel):
    """현재 사용자가 토글 가능한 컨텍스트 1건."""

    context: AcademyContext
    academy_id: str
    label: str  # 예: "강남리듬 학원장"
    member_id: str
    is_onboarding: bool = False  # 수습 강사 여부
    delegation_active: bool = False  # 위임 받은 자인지


class ContextResponse(BaseModel):
    """GET /auth/context — 현재 활성 컨텍스트 + 사용 가능한 컨텍스트들."""

    user_id: str
    active_context: AcademyContext | None = None  # 미선택 상태 가능
    academy_id: str | None = None
    teacher_id: str | None = None
    available_contexts: list[AvailableContext] = Field(default_factory=list)


class ForbiddenContextSwitchResponse(BaseModel):
    """context_toggle_spec §4.1 실패 응답."""

    error: str = "FORBIDDEN_CONTEXT_SWITCH"
    message: str
    available_contexts: list[str] = Field(default_factory=list)
