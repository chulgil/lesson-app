"""Academy governance endpoints — AC-M1 그룹 B.

Spec:
- context_toggle_spec §4 (전환 API)
- temporary_delegation_spec §4-§7 (위임 + audit)
- academy_schedule_authority §4 (activity timeline)
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.academy_governance import (
    AcademyActivityLogListResponse,
    AcademyActivityLogResponse,
    AcademyDelegationActionListResponse,
    AcademyDelegationActionResponse,
    AcademyDelegationActionReviewRequest,
    AcademyDelegationCreate,
    AcademyDelegationListResponse,
    AcademyDelegationResponse,
    AcademyDelegationRevokeRequest,
    ContextSwitchLogListResponse,
    ContextSwitchLogResponse,
    DelegationState,
)
from app.services.academy_governance_service import AcademyGovernanceService
from app.services.academy_service import AcademyService

router = APIRouter()


# ---------------------------------------------------------------------------
# ContextSwitchLog — 학원장 본인 토글 audit (감사 투명성)
# ---------------------------------------------------------------------------


@router.get(
    "/{academy_id}/context-switches/me",
    response_model=ContextSwitchLogListResponse,
    status_code=status.HTTP_200_OK,
    summary="List my context switch history for this academy (transparency)",
)
async def list_my_context_switches(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    limit: Annotated[int, Query(ge=1, le=500)] = 100,
) -> ContextSwitchLogListResponse:
    # 멤버 권한 검사.
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    service = AcademyGovernanceService(db)
    logs, total = await service.list_context_switches_for_user(
        user_id=current_user.id, academy_id=academy_id, limit=limit
    )
    return ContextSwitchLogListResponse(
        logs=[ContextSwitchLogResponse.model_validate(log) for log in logs],
        total_count=total,
    )


# ---------------------------------------------------------------------------
# Delegation — 학원장 시작/회수, 모든 멤버 활성 위임 조회
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/delegations",
    response_model=AcademyDelegationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Start a temporary delegation (owner only, explicit confirmation)",
)
async def start_delegation(
    academy_id: str,
    body: AcademyDelegationCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyDelegationResponse:
    academy_service = AcademyService(db)
    await academy_service.assert_owner(academy_id, current_user.id)
    service = AcademyGovernanceService(db)
    delegation = await service.start_delegation(academy_id=academy_id, delegator_user_id=current_user.id, body=body)
    return AcademyDelegationResponse.model_validate(delegation)


@router.get(
    "/{academy_id}/delegations/active",
    response_model=AcademyDelegationResponse | None,
    status_code=status.HTTP_200_OK,
    summary="Get the currently active delegation (or null)",
)
async def get_active_delegation(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyDelegationResponse | None:
    # 멤버라면 누구나 활성 위임 조회 (delegatee 가 본인이 위임 중인지 확인).
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    service = AcademyGovernanceService(db)
    active = await service.get_active_delegation(academy_id)
    return AcademyDelegationResponse.model_validate(active) if active is not None else None


@router.get(
    "/{academy_id}/delegations",
    response_model=AcademyDelegationListResponse,
    status_code=status.HTTP_200_OK,
    summary="List delegations history (owner only)",
)
async def list_delegations(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    state_filter: Annotated[DelegationState | None, Query(alias="state")] = None,
) -> AcademyDelegationListResponse:
    academy_service = AcademyService(db)
    await academy_service.assert_owner(academy_id, current_user.id)
    service = AcademyGovernanceService(db)
    delegations, total = await service.list_delegations(academy_id=academy_id, state_filter=state_filter)
    return AcademyDelegationListResponse(
        delegations=[AcademyDelegationResponse.model_validate(d) for d in delegations],
        total_count=total,
    )


@router.delete(
    "/delegations/{delegation_id}",
    response_model=AcademyDelegationResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke a delegation (owner manual)",
)
async def revoke_delegation(
    delegation_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    body: AcademyDelegationRevokeRequest | None = None,  # noqa: ARG001
) -> AcademyDelegationResponse:
    service = AcademyGovernanceService(db)
    # 학원장 권한 검사 — delegation 의 academy_id 기준.
    delegation = await service.get_delegation(delegation_id)
    academy_service = AcademyService(db)
    await academy_service.assert_owner(delegation.academy_id, current_user.id)
    delegation = await service.revoke_delegation(delegation_id=delegation_id, by_user_id=current_user.id)
    return AcademyDelegationResponse.model_validate(delegation)


# ---------------------------------------------------------------------------
# Delegation Action — audit + 검토
# ---------------------------------------------------------------------------


@router.get(
    "/delegations/{delegation_id}/actions",
    response_model=AcademyDelegationActionListResponse,
    status_code=status.HTTP_200_OK,
    summary="List actions performed under a delegation (owner only — for review)",
)
async def list_delegation_actions(
    delegation_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pending_review_only: Annotated[bool, Query()] = False,
) -> AcademyDelegationActionListResponse:
    service = AcademyGovernanceService(db)
    delegation = await service.get_delegation(delegation_id)
    academy_service = AcademyService(db)
    await academy_service.assert_owner(delegation.academy_id, current_user.id)
    actions, total, pending = await service.list_delegation_actions(
        delegation_id=delegation_id, pending_review_only=pending_review_only
    )
    return AcademyDelegationActionListResponse(
        actions=[AcademyDelegationActionResponse.model_validate(a) for a in actions],
        total_count=total,
        pending_review_count=pending,
    )


@router.post(
    "/delegations/{delegation_id}/actions/review",
    status_code=status.HTTP_200_OK,
    summary="Review delegation actions (bulk approve or individual dispute)",
)
async def review_delegation_actions(
    delegation_id: str,
    body: AcademyDelegationActionReviewRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    service = AcademyGovernanceService(db)
    delegation = await service.get_delegation(delegation_id)
    academy_service = AcademyService(db)
    await academy_service.assert_owner(delegation.academy_id, current_user.id)
    count = await service.review_actions(
        action_ids=body.action_ids,
        by_user_id=current_user.id,
        bulk_approve=body.bulk_approve,
        dispute_note=body.dispute_note,
    )
    return {"reviewed_count": count}


# ---------------------------------------------------------------------------
# Activity Log — 강사 활동 timeline (NFR-A-5 사후 가시성)
# ---------------------------------------------------------------------------


@router.get(
    "/{academy_id}/activities",
    response_model=AcademyActivityLogListResponse,
    status_code=status.HTTP_200_OK,
    summary="List activity logs (owner: all / teacher: own only)",
)
async def list_activities(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    actor_member_id: Annotated[str | None, Query()] = None,
    action_type: Annotated[str | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 100,
) -> AcademyActivityLogListResponse:
    """학원장은 학원 전체 활동 조회. 강사는 본인 활동만 (NFR-A-5).

    actor_member_id 필터가 본인이 아닌데 학원장도 아니면 403.
    """
    service = AcademyGovernanceService(db)
    member_id, role = await service.resolve_member_role(academy_id=academy_id, user_id=current_user.id)
    if role is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    if role == "teacher":
        if actor_member_id is not None and actor_member_id != member_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Teacher can only view own activity",
            )
        actor_member_id = member_id

    activities, total = await service.list_activities(
        academy_id=academy_id,
        actor_member_id=actor_member_id,
        action_type=action_type,
        limit=limit,
    )
    return AcademyActivityLogListResponse(
        activities=[AcademyActivityLogResponse.model_validate(a) for a in activities],
        total_count=total,
    )


__all__ = ["router"]
