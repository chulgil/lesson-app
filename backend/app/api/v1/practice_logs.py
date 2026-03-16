"""Practice log endpoints."""

from __future__ import annotations

import datetime as _dt
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.practice_log import (
    PracticeLogCreate,
    PracticeLogResponse,
    PracticeLogUpdate,
    PracticeStatsResponse,
)
from app.services.practice_log_service import PracticeLogService

router = APIRouter()


@router.get(
    "/",
    response_model=list[PracticeLogResponse],
    summary="List practice logs for a month",
)
async def list_practice_logs(
    student_id: str,
    year: int = Query(...),
    month: int = Query(...),
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> list[PracticeLogResponse]:
    service = PracticeLogService(db)
    return await service.get_logs(student_id, year=year, month=month)


@router.get(
    "/date/{date}",
    response_model=PracticeLogResponse | None,
    summary="Get practice log for a date",
)
async def get_practice_log_by_date(
    date: _dt.date,
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> PracticeLogResponse | None:
    service = PracticeLogService(db)
    return await service.get_log_by_date(student_id, date)


@router.post(
    "/",
    response_model=PracticeLogResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create practice log",
)
async def create_practice_log(
    body: PracticeLogCreate,
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> PracticeLogResponse:
    service = PracticeLogService(db)
    return await service.create_log(student_id, body.model_dump())


@router.put(
    "/{log_id}",
    response_model=PracticeLogResponse,
    summary="Update practice log",
)
async def update_practice_log(
    log_id: str,
    body: PracticeLogUpdate,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> PracticeLogResponse:
    service = PracticeLogService(db)
    return await service.update_log(log_id, body.model_dump(exclude_none=True))


@router.delete(
    "/{log_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete practice log",
)
async def delete_practice_log(
    log_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> None:
    service = PracticeLogService(db)
    await service.delete_log(log_id)


@router.patch(
    "/{log_id}/tasks/{task_id}/toggle",
    response_model=PracticeLogResponse,
    summary="Toggle task completion",
)
async def toggle_task(
    log_id: str,
    task_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> PracticeLogResponse:
    service = PracticeLogService(db)
    return await service.toggle_task(log_id, task_id)


@router.get(
    "/weekly",
    response_model=list[bool],
    summary="Get weekly practice status",
)
async def get_weekly_practice(
    student_id: str,
    week_start: _dt.date = Query(...),
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> list[bool]:
    service = PracticeLogService(db)
    return await service.get_weekly_practice(student_id, week_start)


@router.get(
    "/stats",
    response_model=PracticeStatsResponse,
    summary="Get monthly practice stats",
)
async def get_monthly_stats(
    student_id: str,
    year: int = Query(...),
    month: int = Query(...),
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    current_user: Annotated[User, Depends(get_current_user)] = None,
) -> PracticeStatsResponse:
    service = PracticeLogService(db)
    return await service.get_monthly_stats(student_id, year, month)
