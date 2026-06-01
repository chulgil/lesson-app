"""Teacher vacation endpoints (#431 G3 휴가 모드).

Spec: docs/specs/schedule/teacher_vacation_mode.md §9.

본 모듈은 1차 BE 작업 범위만 포함 (등록 + 영향 미리보기).
후속 PR: GET 목록 / DELETE 24h 일괄 취소 / 알림톡 발송.
"""

from __future__ import annotations

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.vacation import (
    VacationImpactPreview,
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
