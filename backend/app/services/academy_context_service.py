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
        current_jti: str | None = None,
    ) -> ContextSwitchResponse:
        """컨텍스트 전환 — context_toggle_spec §4.1, §7.2.

        절차:
        1. can_switch_context 검증 (§3.2): AcademyMember.exists
        2. 새 JWT 발급 (active_context/academy_id/teacher_id 포함, 자동 jti)
        3. 이전 access token jti 가 있으면 ``TokenBlacklist`` 에 추가
           (§7.2 동시 세션 금지 — 토글 직후 이전 JWT 401).
        4. ContextSwitchLog 자동 기록
        5. target=academy_owner 면 활성 위임 자동 종료 (학원장 자동 복귀 감지)
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

        # AC-M2 §7.2: 이전 토큰 만료.
        # 1) jti 단건 blacklist — 호출자 토큰 즉시 무효
        # 2) user.tokens_revoked_at epoch 갱신 — 같은 user 의 다른 디바이스
        #    활성 토큰도 일괄 만료 (다중 디바이스 동시 세션 금지). 새 토큰은
        #    직후 발급되므로 iat > tokens_revoked_at 이라 통과.
        from datetime import UTC, datetime, timedelta

        from app.core.config import settings
        from app.models.user import TokenBlacklist

        now = datetime.now(UTC)
        user.tokens_revoked_at = now
        if current_jti:
            existing = await self.db.scalar(select(TokenBlacklist).where(TokenBlacklist.jti == current_jti))
            if existing is None:
                expires_at = now + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
                self.db.add(TokenBlacklist(jti=current_jti, user_id=user.id, expires_at=expires_at))
        await self.db.flush()

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
    # §8.4 Session resume — 재로그인 시 직전 active_context 자동 복원
    # ------------------------------------------------------------------

    async def restore_last_context(self, user_id: str) -> dict[str, str | None]:
        """가장 최근 ContextSwitchLog 행으로 직전 컨텍스트 복원.

        Spec §8.4:
        - 직전 컨텍스트 권한이 여전히 활성이면 그대로 복원
        - 박탈됐으면 fallback (학원장 권한 있으면 owner 우선, 없으면 teacher)
        - 멤버십 0개 또는 ContextSwitchLog 0개면 빈 dict (payload 미확장)

        Returns:
            ``{"active_context": str | None, "academy_id": str | None,
               "teacher_id": str | None}`` — payload 에 merge 할 dict.
            컨텍스트 복원이 불가능하면 모든 값이 None.
        """
        from app.models.academy_governance import ContextSwitchLog
        from app.models.teacher import Teacher

        empty: dict[str, str | None] = {
            "active_context": None,
            "academy_id": None,
            "teacher_id": None,
        }

        last_log = await self.db.scalar(
            select(ContextSwitchLog)
            .where(ContextSwitchLog.user_id == user_id)
            .order_by(ContextSwitchLog.switched_at.desc())
            .limit(1)
        )
        if last_log is not None:
            target_role = (
                AcademyMemberRole.owner
                if last_log.to_context == ContextEnum.academy_owner
                else AcademyMemberRole.teacher
            )
            still_active = await self.db.scalar(
                select(AcademyMember)
                .where(AcademyMember.user_id == user_id)
                .where(AcademyMember.academy_id == last_log.academy_id)
                .where(AcademyMember.role == target_role)
                .where(AcademyMember.access_revoked_at.is_(None))
            )
            if still_active is not None:
                teacher_id: str | None = None
                if target_role == AcademyMemberRole.teacher:
                    teacher_id = await self.db.scalar(select(Teacher.id).where(Teacher.user_id == user_id))
                return {
                    "active_context": last_log.to_context.value,
                    "academy_id": last_log.academy_id,
                    "teacher_id": teacher_id,
                }
            # 권한 박탈 — fallback 으로 떨어짐.

        # Fallback: 어떤 학원이든 활성 owner 멤버십 우선, 없으면 teacher.
        owner_member = await self.db.scalar(
            select(AcademyMember)
            .where(AcademyMember.user_id == user_id)
            .where(AcademyMember.role == AcademyMemberRole.owner)
            .where(AcademyMember.access_revoked_at.is_(None))
            .order_by(AcademyMember.created_at.asc())
            .limit(1)
        )
        if owner_member is not None:
            return {
                "active_context": ContextEnum.academy_owner.value,
                "academy_id": owner_member.academy_id,
                "teacher_id": None,
            }
        teacher_member = await self.db.scalar(
            select(AcademyMember)
            .where(AcademyMember.user_id == user_id)
            .where(AcademyMember.role == AcademyMemberRole.teacher)
            .where(AcademyMember.access_revoked_at.is_(None))
            .order_by(AcademyMember.created_at.asc())
            .limit(1)
        )
        if teacher_member is not None:
            teacher_id = await self.db.scalar(select(Teacher.id).where(Teacher.user_id == user_id))
            return {
                "active_context": ContextEnum.teacher.value,
                "academy_id": teacher_member.academy_id,
                "teacher_id": teacher_id,
            }
        return empty

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
