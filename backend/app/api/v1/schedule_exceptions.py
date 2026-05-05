"""Schedule exception endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.schedule_ext import (
    ScheduleExceptionCreate,
    ScheduleExceptionResponse,
    ScheduleExceptionUpdate,
)
from app.services.schedule_ext_service import ScheduleExtService

router = APIRouter()


@router.get(
    "/",
    response_model=list[ScheduleExceptionResponse],
    summary="List schedule exceptions",
    operation_id="list_schedule_exceptions_legacy",
)
async def list_exceptions(
    teacher_availability_id: Annotated[str, Query(description="Teacher availability ID")],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[ScheduleExceptionResponse]:
    service = ScheduleExtService(db)
    return await service.get_exceptions(teacher_availability_id)


@router.post(
    "/",
    response_model=ScheduleExceptionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a schedule exception",
    operation_id="create_schedule_exception_legacy",
)
async def create_exception(
    teacher_availability_id: Annotated[str, Query(description="Teacher availability ID")],
    body: ScheduleExceptionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleExceptionResponse:
    service = ScheduleExtService(db)
    result: ScheduleExceptionResponse = await service.create_exception(
        teacher_availability_id, body.model_dump()
    )
    return result


@router.put(
    "/{exception_id}",
    response_model=ScheduleExceptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a schedule exception",
    operation_id="update_schedule_exception_legacy",
)
async def update_exception(
    exception_id: str,
    body: ScheduleExceptionUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ScheduleExceptionResponse:
    service = ScheduleExtService(db)
    result: ScheduleExceptionResponse = await service.update_exception(
        exception_id, body.model_dump(exclude_none=True)
    )
    return result


@router.delete(
    "/{exception_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a schedule exception",
    operation_id="delete_schedule_exception_legacy",
)
async def delete_exception(
    exception_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    service = ScheduleExtService(db)
    await service.delete_exception(exception_id)
