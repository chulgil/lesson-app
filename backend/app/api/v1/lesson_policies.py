"""Lesson policy endpoints for Flutter subscription policy screens."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db
from app.models.user import User
from app.schemas.lesson_policy import LessonPolicyPayload, LessonPolicyResponse
from app.services.lesson_policy_service import LessonPolicyService

router = APIRouter()


@router.get(
    "/teacher/{teacher_id}",
    response_model=LessonPolicyResponse,
    status_code=status.HTTP_200_OK,
)
async def get_teacher_policy(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonPolicyResponse:
    """Return a teacher default lesson policy."""
    service = LessonPolicyService(db)
    return await service.get_teacher_policy(teacher_id)


@router.get(
    "/class/{lesson_class_id}",
    response_model=LessonPolicyResponse,
    status_code=status.HTTP_200_OK,
)
async def get_class_policy(
    lesson_class_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LessonPolicyResponse:
    """Class-specific policies are not separated yet; return 404 until configured."""
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Class lesson policy not found")


@router.get(
    "/effective",
    response_model=LessonPolicyResponse,
    status_code=status.HTTP_200_OK,
)
async def get_effective_policy(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    lesson_class_id: str | None = None,
) -> LessonPolicyResponse:
    """Return the effective policy, currently the teacher default policy."""
    service = LessonPolicyService(db)
    return await service.get_effective_policy(teacher_id, lesson_class_id)


@router.post(
    "",
    response_model=LessonPolicyResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_policy(
    payload: LessonPolicyPayload,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonPolicyResponse:
    """Create or replace a teacher default lesson policy."""
    service = LessonPolicyService(db)
    return await service.create_policy(payload, current_user)


@router.put(
    "/{policy_id}",
    response_model=LessonPolicyResponse,
    status_code=status.HTTP_200_OK,
)
async def update_policy(
    policy_id: str,
    payload: LessonPolicyPayload,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonPolicyResponse:
    """Update a policy."""
    service = LessonPolicyService(db)
    return await service.update_policy(policy_id, payload)


@router.delete(
    "/{policy_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_policy(
    policy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Delete a policy."""
    service = LessonPolicyService(db)
    await service.delete_policy(policy_id)
