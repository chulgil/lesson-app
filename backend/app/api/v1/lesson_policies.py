"""Lesson policy endpoints for Flutter subscription policy screens."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db
from app.models.policy import LessonPolicy
from app.models.user import User
from app.services.teacher_id_resolver import resolve_teacher_id

router = APIRouter()


class LessonPolicyPayload(BaseModel):
    """Frontend LessonPolicy JSON shape."""

    teacher_id: str | None = None
    lesson_class_id: str | None = None
    min_cancel_hours: int | None = None
    max_changes_per_month: int | None = None
    allow_same_day_cancel: bool | None = None
    late_cancel_deadline: str | None = None
    deduct_lesson_on_no_show: bool | None = None
    grace_period_minutes: int | None = None
    allow_carryover: bool | None = None
    max_carryover_lessons: int | None = None
    carryover_period_months: int | None = None
    full_refund_days: int | None = None
    partial_refund_ratio: float | None = None
    halfway_refund_ratio: float | None = None
    no_show_refund_ratio: float | None = None


class LessonPolicyResponse(BaseModel):
    """Frontend-compatible lesson policy response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_class_id: str | None = None
    teacher_id: str
    min_cancel_hours: int = 4
    max_changes_per_month: int = 2
    allow_same_day_cancel: bool = False
    late_cancel_deadline: str | None = None
    deduct_lesson_on_no_show: bool = True
    grace_period_minutes: int = 15
    allow_carryover: bool = True
    max_carryover_lessons: int = 1
    carryover_period_months: int = 1
    full_refund_days: int = 1
    partial_refund_ratio: float = 0.67
    halfway_refund_ratio: float = 0.0
    no_show_refund_ratio: float = 0.67
    created_at: datetime
    updated_at: datetime | None = None


def _to_response(policy: LessonPolicy) -> LessonPolicyResponse:
    return LessonPolicyResponse(
        id=policy.id,
        teacher_id=policy.teacher_id,
        min_cancel_hours=policy.cancellation_deadline_hours,
        max_changes_per_month=policy.max_reschedule_per_subscription,
        allow_same_day_cancel=policy.cancellation_deadline_hours == 0,
        late_cancel_deadline=policy.notes,
        deduct_lesson_on_no_show=policy.no_show_deducts_lesson,
        grace_period_minutes=15,
        allow_carryover=True,
        max_carryover_lessons=1,
        carryover_period_months=1,
        created_at=policy.created_at,
        updated_at=policy.updated_at,
    )


def _apply_payload(policy: LessonPolicy, payload: LessonPolicyPayload) -> None:
    if payload.min_cancel_hours is not None:
        policy.cancellation_deadline_hours = payload.min_cancel_hours
    if payload.max_changes_per_month is not None:
        policy.max_reschedule_per_subscription = payload.max_changes_per_month
    if payload.deduct_lesson_on_no_show is not None:
        policy.no_show_deducts_lesson = payload.deduct_lesson_on_no_show
    if payload.late_cancel_deadline is not None:
        policy.notes = payload.late_cancel_deadline


async def _get_by_teacher(db: AsyncSession, teacher_id: str) -> LessonPolicy | None:
    return await db.scalar(select(LessonPolicy).where(LessonPolicy.teacher_id == teacher_id))


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
    policy = await _get_by_teacher(db, teacher_id)
    if policy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
    return _to_response(policy)


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
    policy = await _get_by_teacher(db, teacher_id)
    if policy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
    return _to_response(policy)


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
    teacher_id = payload.teacher_id or await resolve_teacher_id(db, current_user.id)
    existing = await _get_by_teacher(db, teacher_id)
    if existing is not None:
        _apply_payload(existing, payload)
        await db.flush()
        await db.refresh(existing)
        return _to_response(existing)

    policy = LessonPolicy(teacher_id=teacher_id)
    _apply_payload(policy, payload)
    db.add(policy)
    await db.flush()
    await db.refresh(policy)
    return _to_response(policy)


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
    policy = await db.get(LessonPolicy, policy_id)
    if policy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
    _apply_payload(policy, payload)
    await db.flush()
    await db.refresh(policy)
    return _to_response(policy)


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
    policy = await db.get(LessonPolicy, policy_id)
    if policy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
    await db.delete(policy)
    await db.flush()
