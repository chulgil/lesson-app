"""Academy context endpoints — AC-M2.

Spec: docs/specs/web/academy/context_toggle_spec.md §4.

POST /auth/context/switch — 컨텍스트 전환 + 새 JWT + 자동 위임 정리
GET  /auth/context        — 현재 컨텍스트 + 사용 가능한 컨텍스트 리스트
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Header, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.security import decode_access_token
from app.models.user import User
from app.schemas.academy_context import (
    ContextResponse,
    ContextSwitchRequest,
    ContextSwitchResponse,
)
from app.services.academy_context_service import AcademyContextService

router = APIRouter()


def _extract_context_from_token(authorization: str | None) -> tuple[str | None, str | None, str | None]:
    """JWT 페이로드에서 active_context/academy_id/teacher_id 추출."""
    if not authorization or not authorization.lower().startswith("bearer "):
        return None, None, None
    token = authorization.split(None, 1)[1]
    payload = decode_access_token(token)
    if payload is None:
        return None, None, None
    return (
        payload.get("active_context"),
        payload.get("academy_id"),
        payload.get("teacher_id"),
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
    active_context, academy_id, teacher_id = _extract_context_from_token(authorization)
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
    current_ctx, _, _ = _extract_context_from_token(authorization)
    ip = request.client.host if request.client else None
    service = AcademyContextService(db)
    return await service.switch_context(
        user=current_user,
        body=body,
        ip=ip,
        user_agent=user_agent,
        current_active_context=current_ctx,
    )


__all__ = ["router"]
