"""Teacher vacation endpoints (#431 G3 휴가 모드).

Spec: docs/specs/schedule/teacher_vacation_mode.md §9.

본 모듈 범위:
- POST           — 휴가 등록 + 영향 미리보기 + disposition 처리 (§5.1/5.2/5.3)
- GET   /        — 목록 (active 기본, include_cancelled=true 옵션)
- GET   /impact  — 기간 입력 시 영향 미리보기
- DELETE /{id}   — 24h 내 일괄 취소 (auto_extended_days revert)

Disposition 처리 (vacation_service._apply_dispositions):
- rollForward  → Subscription.auto_extended_days += vacation_days
- freeCancel   → LessonBooking.status = cancelled
- makeupCredit → MakeupCredit 적립 + booking cancel
알림: LNZ_TEACHER_VACATION 알림톡 fan-out + 인앱 알림 (vacation_service).
"""

from __future__ import annotations

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.vacation import (
    VacationBatchCreate,
    VacationBatchResponse,
    VacationImpactPreview,
    VacationListResponse,
    VacationPeriodCreate,
    VacationPeriodResponse,
)
from app.services.teacher_id_resolver import resolve_teacher_id
from app.services.vacation_service import VacationService

router = APIRouter()


@router.post(
    "",
    response_model=VacationPeriodResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a teacher vacation period",
)
async def register_vacation(
    body: VacationPeriodCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> VacationPeriodResponse:
    """휴가 등록. 기본 처리 옵션이 rollForward 이면 영향 받는 수강권의
    `auto_extended_days` 가 자동 증가한다. (spec §5.3)
    """
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = VacationService(db)
    try:
        return await service.register_vacation(teacher_id, body)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.post(
    "/batch",
    response_model=VacationBatchResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register multiple vacation segments at once (#768 ②)",
)
async def register_vacation_batch(
    body: VacationBatchCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> VacationBatchResponse:
    """다구간 휴가 등록. 보상옵션은 구간별, 사유/학생별 예외는 전 구간 공유.

    구간 간 겹침은 거부한다 (같은 레슨 이중 처리로 차감/연장 무결성 훼손 방지).
    """
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = VacationService(db)
    try:
        return await service.register_vacation_batch(teacher_id, body)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.get(
    "/impact",
    response_model=VacationImpactPreview,
    status_code=status.HTTP_200_OK,
    summary="Preview vacation impact (lessons/students)",
)
async def preview_vacation_impact(
    start: Annotated[date, Query(description="Vacation start date (inclusive)")],
    end: Annotated[date, Query(description="Vacation end date (inclusive)")],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> VacationImpactPreview:
    """기간 입력 시 영향 받는 활성 레슨/학생 수를 반환. (spec §4.1 step 2)"""
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = VacationService(db)
    try:
        return await service.preview_impact(teacher_id, start, end)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.get(
    "",
    response_model=VacationListResponse,
    status_code=status.HTTP_200_OK,
    summary="List teacher's vacation periods",
)
async def list_vacations(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    include_cancelled: Annotated[
        bool,
        Query(description="Include cancelled vacations in the response"),
    ] = False,
) -> VacationListResponse:
    """선생님의 휴가 목록. 기본은 active 만, include_cancelled=true 면 취소된 것도 포함."""
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = VacationService(db)
    return await service.list_vacations(teacher_id, include_cancelled=include_cancelled)


@router.delete(
    "/{period_id}",
    response_model=VacationPeriodResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel a vacation within 24h (Recovery, spec §7)",
)
async def cancel_vacation(
    period_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> VacationPeriodResponse:
    """24h 내 일괄 취소: cancelled_at 설정 + auto_extended_days revert."""
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = VacationService(db)
    return await service.cancel_vacation(period_id, teacher_id)
