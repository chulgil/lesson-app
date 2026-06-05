"""Academy governance service — AC-M1 그룹 B.

Spec:
- ContextSwitchLog: context_toggle_spec §3.3, §9
- AcademyDelegation: temporary_delegation_spec §4-§7
- AcademyActivityLog: academy_schedule_authority §4

책임:
- 학원장↔강사 모드 전환 audit 기록·조회
- 임시 권한 위임 시작/회수/만료 + 모든 액션 audit + 학원장 사후 검토
- 강사 활동 timeline 기록·조회

UX 원칙 (내부 복잡 / 사용자 단순):
- 위임 시작: 명시 confirmation 1탭 (향후 PIN 도입)
- 위임 종료: 학원장 다음 콘솔 로그인 자동 감지 → auto_end
- audit 검토: 전체 승인 1탭 + 개별 이의 제기
- 권한 차단 응답: FORBIDDEN_DELEGATION_EXPIRED 코드로 명확
"""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academy import AcademyMember, AcademyMemberRole
from app.models.academy_governance import (
    AcademyActivityLog,
    AcademyContext,
    AcademyDelegation,
    AcademyDelegationAction,
    ContextAccessDenialLog,
    ContextSwitchLog,
    ContextSwitchTrigger,
    DelegationRevokeReason,
    DelegationState,
)
from app.schemas.academy_governance import (
    AcademyDelegationCreate,
)


def _utcnow() -> datetime:
    return datetime.now(UTC)


def _ensure_aware(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


class AcademyGovernanceService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # ContextSwitchLog
    # ------------------------------------------------------------------

    async def record_context_switch(
        self,
        *,
        user_id: str,
        academy_id: str,
        from_context: AcademyContext,
        to_context: AcademyContext,
        ip: str | None = None,
        user_agent: str | None = None,
        triggered_by: ContextSwitchTrigger = ContextSwitchTrigger.user,
    ) -> ContextSwitchLog:
        """auth 라우터 (POST /auth/context/switch) 가 토글 시 호출."""
        log = ContextSwitchLog(
            user_id=user_id,
            academy_id=academy_id,
            from_context=from_context,
            to_context=to_context,
            switched_at=_utcnow(),
            ip=ip,
            user_agent=user_agent,
            triggered_by=triggered_by,
        )
        self.db.add(log)
        await self.db.flush()
        return log

    async def list_context_switches_for_user(
        self,
        *,
        user_id: str,
        academy_id: str | None = None,
        limit: int = 100,
    ) -> tuple[list[ContextSwitchLog], int]:
        """학원장 본인 로그만 조회 (감사 투명성). 운영자 어드민은 별도 endpoint."""
        stmt = select(ContextSwitchLog).where(ContextSwitchLog.user_id == user_id)
        if academy_id is not None:
            stmt = stmt.where(ContextSwitchLog.academy_id == academy_id)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(ContextSwitchLog.switched_at.desc()).limit(limit))
        return list(result.all()), total

    async def list_access_denials_for_user(
        self,
        *,
        user_id: str,
        academy_id: str | None = None,
        denial_code: str | None = None,
        limit: int = 100,
    ) -> tuple[list[ContextAccessDenialLog], int]:
        """학원장 본인 권한 매트릭스 차단 로그 조회 (감사 투명성, §9).

        academy_id 지정 시 해당 학원 관련 차단만. None 이면 전부 (학원 무관
        포함). denial_code 지정 시 해당 차단 코드만. 운영자 어드민은 별도
        endpoint.
        """
        stmt = select(ContextAccessDenialLog).where(ContextAccessDenialLog.user_id == user_id)
        if academy_id is not None:
            stmt = stmt.where(ContextAccessDenialLog.academy_id == academy_id)
        if denial_code is not None:
            stmt = stmt.where(ContextAccessDenialLog.denial_code == denial_code)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(ContextAccessDenialLog.denied_at.desc()).limit(limit))
        return list(result.all()), total

    # ------------------------------------------------------------------
    # AcademyDelegation
    # ------------------------------------------------------------------

    async def start_delegation(
        self,
        *,
        academy_id: str,
        delegator_user_id: str,
        body: AcademyDelegationCreate,
    ) -> AcademyDelegation:
        """학원장이 위임 시작 (UX 1탭 onboarding).

        검증:
        1. 명시 confirmation=true
        2. delegatee_member_id 가 같은 학원 멤버 + active
        3. 같은 학원에 active/scheduled 위임이 이미 있으면 409
        4. ends_at > starts_at
        5. 권한 항목 비어있지 않음 (Pydantic 검증)
        """
        if not body.confirmation:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Explicit confirmation required to start delegation",
            )
        if _ensure_aware(body.ends_at) <= _ensure_aware(body.starts_at):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="ends_at must be after starts_at",
            )

        # delegatee 가 같은 학원의 활성 멤버인지 검증.
        delegatee = await self.db.get(AcademyMember, body.delegatee_member_id)
        if delegatee is None or delegatee.academy_id != academy_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="delegatee_member_id not in this academy",
            )
        if delegatee.access_revoked_at is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="delegatee access has been revoked",
            )

        # 동시 위임 1개 제한.
        existing = await self.db.scalar(
            select(AcademyDelegation.id)
            .where(AcademyDelegation.academy_id == academy_id)
            .where(AcademyDelegation.state.in_([DelegationState.scheduled, DelegationState.active]))
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Active delegation already exists for this academy",
            )

        now = _utcnow()
        initial_state = DelegationState.active if _ensure_aware(body.starts_at) <= now else DelegationState.scheduled

        delegation = AcademyDelegation(
            academy_id=academy_id,
            delegator_user_id=delegator_user_id,
            delegatee_member_id=body.delegatee_member_id,
            permissions=list(body.permissions),
            starts_at=body.starts_at,
            ends_at=body.ends_at,
            reason=body.reason,
            reason_note=body.reason_note,
            state=initial_state,
        )
        self.db.add(delegation)
        await self.db.flush()
        return delegation

    async def get_delegation(self, delegation_id: str) -> AcademyDelegation:
        delegation = await self.db.get(AcademyDelegation, delegation_id)
        if delegation is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delegation not found")
        return delegation

    async def get_active_delegation(self, academy_id: str) -> AcademyDelegation | None:
        """학원당 활성 위임 1개 조회. 없으면 None."""
        # state=scheduled 이 starts_at 도달했으면 active 로 전환.
        now = _utcnow()
        scheduled = await self.db.scalars(
            select(AcademyDelegation)
            .where(AcademyDelegation.academy_id == academy_id)
            .where(AcademyDelegation.state == DelegationState.scheduled)
        )
        for d in scheduled.all():
            if _ensure_aware(d.starts_at) <= now:
                d.state = DelegationState.active
        # ends_at 지난 active 는 expired 로.
        actives = await self.db.scalars(
            select(AcademyDelegation)
            .where(AcademyDelegation.academy_id == academy_id)
            .where(AcademyDelegation.state == DelegationState.active)
        )
        active_list = list(actives.all())
        for d in active_list:
            if _ensure_aware(d.ends_at) < now:
                d.state = DelegationState.expired
                d.revoked_at = now
                d.revoked_reason = DelegationRevokeReason.expired
        await self.db.flush()
        # 다시 select.
        result = await self.db.scalar(
            select(AcademyDelegation)
            .where(AcademyDelegation.academy_id == academy_id)
            .where(AcademyDelegation.state == DelegationState.active)
        )
        return result

    async def revoke_delegation(
        self,
        *,
        delegation_id: str,
        by_user_id: str,
        reason: DelegationRevokeReason = DelegationRevokeReason.owner_manual,
    ) -> AcademyDelegation:
        delegation = await self.get_delegation(delegation_id)
        if delegation.state not in (DelegationState.scheduled, DelegationState.active):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Delegation already {delegation.state.value}",
            )
        delegation.state = (
            DelegationState.auto_ended if reason == DelegationRevokeReason.owner_returned else DelegationState.revoked
        )
        delegation.revoked_at = _utcnow()
        delegation.revoked_by_user_id = by_user_id
        delegation.revoked_reason = reason
        await self.db.flush()
        return delegation

    async def auto_end_on_owner_return(self, *, academy_id: str, owner_user_id: str) -> AcademyDelegation | None:
        """학원장 콘솔 로그인 자동 감지 → 활성 위임 자동 종료.

        auth 라우터 (POST /auth/context/switch) 가 학원장 모드 진입 시 호출.
        """
        active = await self.get_active_delegation(academy_id)
        if active is None:
            return None
        return await self.revoke_delegation(
            delegation_id=active.id,
            by_user_id=owner_user_id,
            reason=DelegationRevokeReason.owner_returned,
        )

    async def list_delegations(
        self,
        *,
        academy_id: str,
        state_filter: DelegationState | None = None,
    ) -> tuple[list[AcademyDelegation], int]:
        stmt = select(AcademyDelegation).where(AcademyDelegation.academy_id == academy_id)
        if state_filter is not None:
            stmt = stmt.where(AcademyDelegation.state == state_filter)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyDelegation.created_at.desc()))
        return list(result.all()), total

    # ------------------------------------------------------------------
    # AcademyDelegationAction
    # ------------------------------------------------------------------

    async def log_delegation_action(
        self,
        *,
        delegation_id: str,
        performed_by_user_id: str,
        permission_used: str,
        endpoint: str,
        response_status: int,
        target_resource_id: str | None = None,
        request_summary: dict | None = None,
    ) -> AcademyDelegationAction:
        """위임 활성 중 액션 audit. middleware 또는 라우터 helper 에서 호출."""
        action = AcademyDelegationAction(
            delegation_id=delegation_id,
            performed_at=_utcnow(),
            performed_by_user_id=performed_by_user_id,
            permission_used=permission_used,
            endpoint=endpoint,
            target_resource_id=target_resource_id,
            request_summary=request_summary,
            response_status=response_status,
        )
        self.db.add(action)
        await self.db.flush()
        return action

    async def list_delegation_actions(
        self,
        *,
        delegation_id: str,
        pending_review_only: bool = False,
    ) -> tuple[list[AcademyDelegationAction], int, int]:
        stmt = select(AcademyDelegationAction).where(AcademyDelegationAction.delegation_id == delegation_id)
        if pending_review_only:
            stmt = stmt.where(AcademyDelegationAction.owner_reviewed_at.is_(None))
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        # 검토 대기 별도 카운트.
        pending_stmt = (
            select(func.count(AcademyDelegationAction.id))
            .where(AcademyDelegationAction.delegation_id == delegation_id)
            .where(AcademyDelegationAction.owner_reviewed_at.is_(None))
        )
        pending = int((await self.db.scalar(pending_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyDelegationAction.performed_at.desc()))
        return list(result.all()), total, pending

    async def review_actions(
        self,
        *,
        action_ids: list[str],
        by_user_id: str,
        bulk_approve: bool,
        dispute_note: str | None = None,
    ) -> int:
        """학원장 사후 검토 (UX: 전체 승인 또는 개별 이의 제기).

        Returns: 처리된 행 수.
        """
        now = _utcnow()
        actions = (
            await self.db.scalars(select(AcademyDelegationAction).where(AcademyDelegationAction.id.in_(action_ids)))
        ).all()
        for action in actions:
            action.owner_reviewed_at = now
            if not bulk_approve and dispute_note:
                action.owner_dispute_note = dispute_note
        await self.db.flush()
        return len(actions)

    async def auto_approve_stale_reviews(self, *, older_than_days: int = 30) -> int:
        """30일 후 자동 전체 승인 (delegatee 보호 — 학원장 무한 검토 차단).

        temporary_delegation_spec §9.2.
        """
        threshold = _utcnow().replace(tzinfo=UTC)
        # 위임이 종료된 후 N 일 경과 + reviewed_at 없음.
        from datetime import timedelta

        cutoff = threshold - timedelta(days=older_than_days)
        stmt = (
            select(AcademyDelegationAction)
            .join(
                AcademyDelegation,
                AcademyDelegation.id == AcademyDelegationAction.delegation_id,
            )
            .where(AcademyDelegationAction.owner_reviewed_at.is_(None))
            .where(
                AcademyDelegation.state.in_(
                    [
                        DelegationState.expired,
                        DelegationState.revoked,
                        DelegationState.auto_ended,
                    ]
                )
            )
            .where(AcademyDelegation.revoked_at < cutoff)
        )
        actions = list((await self.db.scalars(stmt)).all())
        now = _utcnow()
        for action in actions:
            action.owner_reviewed_at = now
        await self.db.flush()
        return len(actions)

    # ------------------------------------------------------------------
    # AcademyActivityLog
    # ------------------------------------------------------------------

    async def record_activity(
        self,
        *,
        academy_id: str,
        actor_member_id: str,
        actor_name: str,
        action_type: str,
        description: str,
        target_resource_type: str | None = None,
        target_resource_id: str | None = None,
        metadata: dict | None = None,
    ) -> AcademyActivityLog:
        """다른 서비스(lesson/subscription/schedule/notification 등)가 호출.

        예: 강사가 레슨 노트 작성 시 NotificationService 가 record_activity 호출.
        """
        activity = AcademyActivityLog(
            academy_id=academy_id,
            actor_member_id=actor_member_id,
            actor_name=actor_name,
            action_type=action_type,
            description=description,
            target_resource_type=target_resource_type,
            target_resource_id=target_resource_id,
            metadata_json=metadata,
            created_at=_utcnow(),
        )
        self.db.add(activity)
        await self.db.flush()
        return activity

    async def list_activities(
        self,
        *,
        academy_id: str,
        actor_member_id: str | None = None,
        action_type: str | None = None,
        limit: int = 100,
    ) -> tuple[list[AcademyActivityLog], int]:
        """학원장은 학원 전체, 강사는 본인 활동만.

        권한 분리는 라우터에서 처리 (NFR-A-5).
        """
        stmt = select(AcademyActivityLog).where(AcademyActivityLog.academy_id == academy_id)
        if actor_member_id is not None:
            stmt = stmt.where(AcademyActivityLog.actor_member_id == actor_member_id)
        if action_type is not None:
            stmt = stmt.where(AcademyActivityLog.action_type == action_type)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyActivityLog.created_at.desc()).limit(limit))
        return list(result.all()), total

    # ------------------------------------------------------------------
    # Member role resolution (라우터 권한 helper)
    # ------------------------------------------------------------------

    async def resolve_member_role(self, *, academy_id: str, user_id: str) -> tuple[str | None, str | None]:
        """(member_id, role) 반환. role ∈ {"owner", "teacher", None}.

        owner 우선 매칭 (학원장 겸직 강사 → owner 권한 적용).
        """
        owner_id = await self.db.scalar(
            select(AcademyMember.id)
            .where(AcademyMember.academy_id == academy_id)
            .where(AcademyMember.user_id == user_id)
            .where(AcademyMember.role == AcademyMemberRole.owner)
            .where(AcademyMember.access_revoked_at.is_(None))
        )
        if owner_id is not None:
            return owner_id, "owner"
        teacher_id = await self.db.scalar(
            select(AcademyMember.id)
            .where(AcademyMember.academy_id == academy_id)
            .where(AcademyMember.user_id == user_id)
            .where(AcademyMember.role == AcademyMemberRole.teacher)
            .where(AcademyMember.access_revoked_at.is_(None))
        )
        if teacher_id is not None:
            return teacher_id, "teacher"
        return None, None


__all__ = ["AcademyGovernanceService"]
