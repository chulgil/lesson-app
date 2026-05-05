"""Manual teacher endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.manual_teacher import (
    ManualTeacherCreate,
    ManualTeacherResponse,
    ManualTeacherUpdate,
)
from app.services.manual_teacher_service import ManualTeacherService

router = APIRouter()


@router.get("", response_model=PaginatedResponse[ManualTeacherResponse])
async def list_manual_teachers(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[ManualTeacherResponse]:
    service = ManualTeacherService(db)
    return await service.list_manual_teachers(
        current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.post(
    "",
    response_model=ManualTeacherResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_manual_teacher(
    body: ManualTeacherCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ManualTeacherResponse:
    service = ManualTeacherService(db)
    return await service.create_manual_teacher(body, current_user)


@router.get("/{teacher_id}", response_model=ManualTeacherResponse)
async def get_manual_teacher(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ManualTeacherResponse:
    service = ManualTeacherService(db)
    return await service.get_manual_teacher(teacher_id, current_user)


@router.put("/{teacher_id}", response_model=ManualTeacherResponse, status_code=status.HTTP_200_OK)
async def update_manual_teacher(
    teacher_id: str,
    body: ManualTeacherUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ManualTeacherResponse:
    service = ManualTeacherService(db)
    return await service.update_manual_teacher(teacher_id, body, current_user)


@router.delete("/{teacher_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_manual_teacher(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    service = ManualTeacherService(db)
    await service.delete_manual_teacher(teacher_id, current_user)
