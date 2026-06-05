"""Active-context dependency utilities — AC-M2 권한 매트릭스.

Spec: docs/specs/web/academy/context_toggle_spec.md §6, §9.

JWT 페이로드의 ``active_context`` 값으로 콘솔 / lesson-app 모드를 격리한다.

* ``require_owner_context``  — active_context 가 ``"teacher"`` 이면 403
  FORBIDDEN_TEACHER_SCOPE. 콘솔 운영 라우트 (academy_billing, governance,
  학원장 발송 공지 등) 에 적용.
* ``require_teacher_context`` — active_context 가 ``"academy_owner"`` 이면 403
  FORBIDDEN_ACADEMY_OWNER_SCOPE. 학생 노트·녹음·연습 기록 등 lesson-app
  전용 라우트에 적용.

active_context 가 JWT 에 명시되지 않은 경우 (AC-M1 호환 / 토글 미경유 일반
로그인) 는 통과시킨다 — context_toggle_spec §6 은 토글된 모드의 격리만
정의하며, 전체 라우트의 owner/teacher 결정은 ``role`` / ``assert_owner``
같은 기존 체크에 위임한다.

차단 시 ``ContextAccessDenialLog`` 에 audit 기록 + ``audit_id`` 를 응답
detail 에 포함 (§6.3, §9). audit 는 메인 db 세션으로 즉시 commit — dependency
시점에는 다른 dirty state 가 없으므로 안전. 이후 HTTPException raise 로
``get_db`` 가 rollback 해도 이미 commit 된 audit 는 보존된다.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user, oauth2_scheme
from app.core.security import decode_access_token
from app.models.academy_governance import ContextAccessDenialLog
from app.models.user import User


async def get_active_context(
    token: Annotated[str | None, Depends(oauth2_scheme)],
) -> tuple[str | None, str | None, str | None]:
    """JWT 페이로드에서 (active_context, academy_id, teacher_id) 추출.

    토큰 없음 / 디코딩 실패 시 (None, None, None). 인증 자체는
    ``get_current_user`` 가 별도로 강제하므로 여기서는 호환성을 위해 None 허용.
    """
    if token is None:
        return None, None, None
    payload = decode_access_token(token)
    if payload is None:
        return None, None, None
    return (
        payload.get("active_context"),
        payload.get("academy_id"),
        payload.get("teacher_id"),
    )


ActiveContext = Annotated[tuple[str | None, str | None, str | None], Depends(get_active_context)]


async def record_access_denial(
    *,
    db: AsyncSession,
    request: Request,
    user_id: str,
    active_context: str | None,
    academy_id: str | None,
    denial_code: str,
    target_resource_id: str | None = None,
) -> str:
    """차단 audit 를 메인 세션에 add + commit. 후속 rollback 과 무관하게 보존.

    Returns:
        audit_id — ContextAccessDenialLog.id (응답 detail.audit_id 에 포함).
    """
    log = ContextAccessDenialLog(
        user_id=user_id,
        active_context=active_context,
        academy_id=academy_id,
        denial_code=denial_code,
        endpoint_path=request.url.path,
        http_method=request.method,
        target_resource_id=target_resource_id,
        denied_at=datetime.now(UTC),
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return log.id


async def require_owner_context(
    request: Request,
    current_user: Annotated[User, Depends(get_current_user)],
    context: ActiveContext,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """콘솔 운영 라우트 가드. active_context == "teacher" 이면 403."""
    active_context, academy_id, _ = context
    if active_context == "teacher":
        audit_id = await record_access_denial(
            db=db,
            request=request,
            user_id=current_user.id,
            active_context=active_context,
            academy_id=academy_id,
            denial_code="FORBIDDEN_TEACHER_SCOPE",
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "FORBIDDEN_TEACHER_SCOPE",
                "message": "강사는 학원 운영 메뉴에 접근할 수 없습니다.",
                "audit_id": audit_id,
                "remediation": "학원장 모드로 전환 후 다시 시도하세요.",
            },
        )
    return current_user


async def require_teacher_context(
    request: Request,
    current_user: Annotated[User, Depends(get_current_user)],
    context: ActiveContext,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """lesson-app 전용 라우트 가드. active_context == "academy_owner" 이면 403."""
    active_context, academy_id, _ = context
    if active_context == "academy_owner":
        audit_id = await record_access_denial(
            db=db,
            request=request,
            user_id=current_user.id,
            active_context=active_context,
            academy_id=academy_id,
            denial_code="FORBIDDEN_ACADEMY_OWNER_SCOPE",
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "FORBIDDEN_ACADEMY_OWNER_SCOPE",
                "message": "학원장은 학생 개별 진도/노트에 접근할 수 없습니다.",
                "audit_id": audit_id,
                "remediation": "노트 일시 접근을 신청하려면 학생 상세에서 '일시 접근 요청'을 사용하세요.",
            },
        )
    return current_user


OwnerContext = Annotated[User, Depends(require_owner_context)]
TeacherContext = Annotated[User, Depends(require_teacher_context)]
