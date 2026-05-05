"""Practice log endpoints."""

from __future__ import annotations

import datetime as _dt
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
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
    response_model=PaginatedResponse[PracticeLogResponse],
    status_code=status.HTTP_200_OK,
    summary="List practice logs",
)
@router.get(
    "",
    response_model=PaginatedResponse[PracticeLogResponse],
    status_code=status.HTTP_200_OK,
    summary="List practice logs for a month",
)
async def list_practice_logs(
    student_id: str,
    year: int | None = Query(None),
    month: int | None = Query(None),
    date: _dt.date | None = Query(None),
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
    pagination: Annotated[dict, Depends(get_pagination)] = None,  # type: ignore[assignment]
) -> PaginatedResponse[PracticeLogResponse]:
    service = PracticeLogService(db)
    logs = await service.get_logs(student_id, year=year, month=month, log_date=date)
    start = pagination["offset"]
    end = start + pagination["size"]
    return PaginatedResponse.create(
        items=[PracticeLogResponse.model_validate(log) for log in logs[start:end]],
        total=len(logs),
        page=pagination["page"],
        size=pagination["size"],
    )


@router.get(
    "/date/{date}",
    response_model=PracticeLogResponse | None,
    status_code=status.HTTP_200_OK,
    summary="Get practice log for a date",
)
async def get_practice_log_by_date(
    date: _dt.date,
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> PracticeLogResponse | None:
    service = PracticeLogService(db)
    return await service.get_log_by_date(student_id, date)


@router.get(
    "/weekly",
    response_model=list[bool],
    status_code=status.HTTP_200_OK,
    summary="Get weekly practice status",
)
async def get_weekly_practice(
    student_id: str,
    week_start: _dt.date | None = Query(None),
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> list[bool]:
    service = PracticeLogService(db)
    if week_start is None:
        today = _dt.date.today()
        week_start = today - _dt.timedelta(days=today.weekday())
    return await service.get_weekly_practice(student_id, week_start)


@router.get(
    "/stats",
    response_model=PracticeStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get monthly practice stats",
)
async def get_monthly_stats(
    student_id: str,
    year: int = Query(...),
    month: int = Query(...),
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> PracticeStatsResponse:
    service = PracticeLogService(db)
    data = await service.get_monthly_stats(student_id, year, month)
    return PracticeStatsResponse.model_validate(data)


@router.get(
    "/{log_id}",
    response_model=PracticeLogResponse,
    status_code=status.HTTP_200_OK,
    summary="Get practice log by ID",
)
async def get_practice_log_by_id(
    log_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> PracticeLogResponse:
    service = PracticeLogService(db)
    result: PracticeLogResponse = await service.get_log_by_id(log_id)
    return result


@router.put(
    "/{log_id}",
    response_model=PracticeLogResponse,
    status_code=status.HTTP_200_OK,
    summary="Update practice log",
)
async def update_practice_log(
    log_id: str,
    body: PracticeLogUpdate,
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> PracticeLogResponse:
    service = PracticeLogService(db)
    result: PracticeLogResponse = await service.update_log(log_id, body.model_dump(exclude_none=True))
    return result


@router.delete(
    "/{log_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete practice log",
)
async def delete_practice_log(
    log_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> None:
    service = PracticeLogService(db)
    await service.delete_log(log_id)


@router.patch(
    "/{log_id}/tasks/{task_id}/toggle",
    response_model=PracticeLogResponse,
    status_code=status.HTTP_200_OK,
    summary="Toggle task completion",
)
async def toggle_task(
    log_id: str,
    task_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> PracticeLogResponse:
    service = PracticeLogService(db)
    result: PracticeLogResponse = await service.toggle_task(log_id, task_id)
    return result


@router.post(
    "/",
    response_model=PracticeLogResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create practice log",
)
@router.post(
    "",
    response_model=PracticeLogResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create practice log",
)
async def create_practice_log(
    body: PracticeLogCreate,
    student_id: str | None = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
) -> PracticeLogResponse:
    service = PracticeLogService(db)
    target_student_id = student_id or body.student_id
    if target_student_id is None:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="student_id is required",
        )
    data = body.model_dump(exclude={"student_id"})
    result: PracticeLogResponse = await service.create_log(target_student_id, data)
    return result
