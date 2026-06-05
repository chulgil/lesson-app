"""Academy context endpoints — AC-M2.

Spec: docs/specs/web/academy/context_toggle_spec.md §4, §7.2, §9.

POST /auth/context/switch       — 컨텍스트 전환 + 새 JWT + 자동 위임 정리
                                  + 이전 JWT 즉시 만료 (§7.2)
GET  /auth/context              — 현재 컨텍스트 + 사용 가능한 컨텍스트 리스트
GET  /auth/me/access-denials    — 본인 권한 매트릭스 차단 audit 전체 조회
                                  (학원 무관 포함, 모든 모드 허용 — §9 transparency)
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Header, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.security import decode_access_token
from app.models.user import User
from app.schemas.academy_context import (
    ContextResponse,
    ContextSwitchRequest,
    ContextSwitchResponse,
)
from app.schemas.academy_governance import (
    ContextAccessDenialLogListResponse,
    ContextAccessDenialLogResponse,
)
from app.services.academy_context_service import AcademyContextService
from app.services.academy_governance_service import AcademyGovernanceService

router = APIRouter()


@router.get(
    "/me/access-denials",
    response_model=ContextAccessDenialLogListResponse,
    status_code=status.HTTP_200_OK,
    summary="List my context access denial history (transparency, all academies + academy-less)",
)
async def list_my_access_denials_global(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    denial_code: Annotated[str | None, Query(max_length=50)] = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 100,
) -> ContextAccessDenialLogListResponse:
    """본인 권한 매트릭스 차단 audit 전체 조회 (spec §9 transparency).

    학원 관련(academy_id 채움) + 학원 무관(예: recordings, practice_logs) 모두 포함.
    학원 prefix 의 ``/academies/{id}/access-denials/me`` 와 달리 active_context 무관
    호출 가능 — 본인 데이터 조회는 모드와 무관하다.
    """
    service = AcademyGovernanceService(db)
    logs, total = await service.list_access_denials_for_user(
        user_id=current_user.id,
        academy_id=None,
        denial_code=denial_code,
        limit=limit,
    )
    return ContextAccessDenialLogListResponse(
        logs=[ContextAccessDenialLogResponse.model_validate(log) for log in logs],
        total_count=total,
    )


def _extract_context_from_token(
    authorization: str | None,
) -> tuple[str | None, str | None, str | None, str | None]:
    """JWT 페이로드에서 (active_context, academy_id, teacher_id, jti) 추출."""
    if not authorization or not authorization.lower().startswith("bearer "):
        return None, None, None, None
    token = authorization.split(None, 1)[1]
    payload = decode_access_token(token)
    if payload is None:
        return None, None, None, None
    return (
        payload.get("active_context"),
        payload.get("academy_id"),
        payload.get("teacher_id"),
        payload.get("jti"),
    )


@router.get(
    "/context",
    response_model=ContextResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current context + available contexts",
)
async def get_current_context(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    authorization: Annotated[str | None, Header()] = None,
) -> ContextResponse:
    active_context, academy_id, teacher_id, _jti = _extract_context_from_token(authorization)
    service = AcademyContextService(db)
    return await service.get_current_context(
        user=current_user,
        current_active_context=active_context,
        current_academy_id=academy_id,
        current_teacher_id=teacher_id,
    )


@router.post(
    "/context/switch",
    response_model=ContextSwitchResponse,
    status_code=status.HTTP_200_OK,
    summary="Switch context (owner ↔ teacher) — UX 1tap",
)
async def switch_context(
    body: ContextSwitchRequest,
    request: Request,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    authorization: Annotated[str | None, Header()] = None,
    user_agent: Annotated[str | None, Header(alias="User-Agent")] = None,
) -> ContextSwitchResponse:
    current_ctx, current_academy_id, _, current_jti = _extract_context_from_token(authorization)
    ip = request.client.host if request.client else None
    service = AcademyContextService(db)
    return await service.switch_context(
        user=current_user,
        body=body,
        ip=ip,
        user_agent=user_agent,
        current_active_context=current_ctx,
        current_academy_id=current_academy_id,
        current_jti=current_jti,
    )


__all__ = ["router"]
