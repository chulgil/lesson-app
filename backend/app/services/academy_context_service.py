"""Academy context switch service — AC-M2.

Spec: docs/specs/web/academy/context_toggle_spec.md §3-§9.

책임:
- 사용 가능한 컨텍스트 산출 (학원장 / 강사 / 겸직)
- 컨텍스트 전환 검증 (can_switch_context §3.2)
- 새 JWT 발급 (active_context + academy_id + teacher_id 포함)
- ContextSwitchLog 자동 기록 (감사)
- 학원장 자동 복귀 감지: 학원장 모드 전환 시 활성 위임 자동 종료

UX 원칙 (내부 복잡 / 사용자 단순):
- 토글 가능한 컨텍스트 자동 산출 (FE 가 직접 검사할 필요 없음)
- 학원장 ↔ 강사 토글 1탭 → 새 JWT + redirect_url 한 번에 응답
- 학원장 복귀 시 위임 자동 정리 (학원장 액션 0회)
"""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import Academy, AcademyMember, AcademyMemberRole
from app.models.academy_governance import (
    AcademyContext as ContextEnum,
)
from app.models.academy_governance import (
    ContextSwitchTrigger,
)
from app.models.teacher import Teacher
from app.models.user import User
from app.schemas.academy_context import (
    AcademyContext,
    AvailableContext,
    ContextResponse,
    ContextSwitchRequest,
    ContextSwitchResponse,
)
from app.services.academy_governance_service import AcademyGovernanceService


def _role_to_context(role: AcademyMemberRole) -> ContextEnum:
    return ContextEnum.academy_owner if role == AcademyMemberRole.owner else ContextEnum.teacher


def _context_to_role(ctx: AcademyContext) -> AcademyMemberRole:
    return AcademyMemberRole.owner if ctx == AcademyContext.academy_owner else AcademyMemberRole.teacher


class AcademyContextService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Available contexts
    # ------------------------------------------------------------------

    async def get_current_context(
        self,
        *,
        user: User,
        current_active_context: str | None = None,
        current_academy_id: str | None = None,
        current_teacher_id: str | None = None,
    ) -> ContextResponse:
        """JWT 가 보유한 context 정보 + 사용 가능한 모든 컨텍스트 산출."""
        # 사용자 멤버십 전체 조회.
        members = (
            await self.db.scalars(
                select(AcademyMember)
                .where(AcademyMember.user_id == user.id)
                .where(AcademyMember.access_revoked_at.is_(None))
            )
        ).all()
        available: list[AvailableContext] = []
        academies_cache: dict[str, Academy] = {}
        for member in members:
            academy = academies_cache.get(member.academy_id)
            if academy is None:
                academy = await self.db.get(Academy, member.academy_id)
                if academy is not None:
                    academies_cache[member.academy_id] = academy
            if academy is None:
                continue
            ctx = _role_to_context(member.role)
            role_label = "학원장" if member.role == AcademyMemberRole.owner else "강사"
            from datetime import UTC
            from datetime import datetime as _dt

            now = _dt.now(UTC)
            is_onboarding = (
                member.onboarding_until is not None
                and member.onboarding_until.replace(tzinfo=member.onboarding_until.tzinfo or UTC) > now
            )
            available.append(
                AvailableContext(
                    context=ctx,
                    academy_id=academy.id,
                    label=f"{academy.name} {role_label}",
                    member_id=member.id,
                    is_onboarding=is_onboarding,
                    delegation_active=False,  # 향후 위임 감지 보강
                )
            )
        active = (
            AcademyContext(current_active_context)
            if current_active_context in {c.value for c in AcademyContext}
            else None
        )
        return ContextResponse(
            user_id=user.id,
            active_context=active,
            academy_id=current_academy_id,
            teacher_id=current_teacher_id,
            available_contexts=available,
        )

    # ------------------------------------------------------------------
    # Context switch
    # ------------------------------------------------------------------

    async def switch_context(
        self,
        *,
        user: User,
        body: ContextSwitchRequest,
        ip: str | None = None,
        user_agent: str | None = None,
        current_active_context: str | None = None,
    ) -> ContextSwitchResponse:
        """컨텍스트 전환 — context_toggle_spec §4.1.

        절차:
        1. can_switch_context 검증 (§3.2): AcademyMember.exists
        2. 새 JWT 발급 (active_context/academy_id/teacher_id 포함)
        3. ContextSwitchLog 자동 기록
        4. target=academy_owner 면 활성 위임 자동 종료 (학원장 자동 복귀 감지)
        """
        target_role = _context_to_role(body.target_context)
        member = await self.db.scalar(
            select(AcademyMember)
            .where(AcademyMember.academy_id == body.academy_id)
            .where(AcademyMember.user_id == user.id)
            .where(AcademyMember.role == target_role)
            .where(AcademyMember.access_revoked_at.is_(None))
        )
        if member is None:
            # context_toggle_spec §4.1 실패 응답.
            available = await self._available_context_names(user.id, body.academy_id)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "error": "FORBIDDEN_CONTEXT_SWITCH",
                    "message": "해당 학원의 권한이 없습니다.",
                    "available_contexts": available,
                },
            )

        # teacher_id resolve (target_context=teacher 일 때만 의미).
        teacher_id: str | None = None
        if body.target_context == AcademyContext.teacher:
            teacher_id = await self.db.scalar(select(Teacher.id).where(Teacher.user_id == user.id))

        # 새 JWT 발급.
        token_payload: dict[str, Any] = {
            "sub": user.id,
            "role": user.role.value if user.role else None,
            "active_context": body.target_context.value,
            "academy_id": body.academy_id,
            "teacher_id": teacher_id,
        }
        new_token = create_access_token(data=token_payload)

        # ContextSwitchLog 기록.
        gov = AcademyGovernanceService(self.db)
        from_ctx = (
            ContextEnum(current_active_context)
            if current_active_context in {c.value for c in ContextEnum}
            else ContextEnum.teacher  # 미선택 상태에서의 첫 토글은 teacher 로 간주
        )
        await gov.record_context_switch(
            user_id=user.id,
            academy_id=body.academy_id,
            from_context=from_ctx,
            to_context=ContextEnum(body.target_context.value),
            ip=ip,
            user_agent=user_agent,
            triggered_by=ContextSwitchTrigger.user,
        )

        # 학원장 자동 복귀 감지: target=academy_owner 진입 시 활성 위임 자동 종료.
        if body.target_context == AcademyContext.academy_owner:
            await gov.auto_end_on_owner_return(academy_id=body.academy_id, owner_user_id=user.id)

        # redirect_url 힌트 (콘솔/lesson-app 도메인은 FE 또는 환경 변수로 분리. 본 layer 는 path 만).
        redirect_url = (
            f"/console?academy={body.academy_id}" if body.target_context == AcademyContext.academy_owner else "/today"
        )

        return ContextSwitchResponse(
            access_token=new_token,
            active_context=body.target_context,
            academy_id=body.academy_id,
            teacher_id=teacher_id,
            member_id=member.id,
            redirect_url=redirect_url,
        )

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    async def _available_context_names(self, user_id: str, academy_id: str) -> list[str]:
        members = (
            await self.db.scalars(
                select(AcademyMember)
                .where(AcademyMember.user_id == user_id)
                .where(AcademyMember.academy_id == academy_id)
                .where(AcademyMember.access_revoked_at.is_(None))
            )
        ).all()
        return [_role_to_context(m.role).value for m in members]


__all__ = ["AcademyContextService"]
