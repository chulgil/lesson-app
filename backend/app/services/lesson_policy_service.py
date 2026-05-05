"""Lesson policy service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.lesson_policy import LessonPolicyPayload, LessonPolicyResponse
from app.services.teacher_id_resolver import resolve_teacher_id


class LessonPolicyService:
    """Manage teacher lesson policies."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_teacher_policy(self, teacher_id: str) -> LessonPolicyResponse:
        policy = await self._get_by_teacher(teacher_id)
        if policy is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
        return self._to_response(policy)

    async def get_effective_policy(self, teacher_id: str, lesson_class_id: str | None = None) -> LessonPolicyResponse:
        policy = await self._get_by_teacher(teacher_id)
        if policy is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
        return self._to_response(policy)

    async def create_policy(self, payload: LessonPolicyPayload, current_user: Any) -> LessonPolicyResponse:
        from app.models.policy import LessonPolicy

        current_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        teacher_id = payload.teacher_id or current_teacher_id
        self._assert_policy_teacher_owner(teacher_id, current_teacher_id)
        existing = await self._get_by_teacher(teacher_id)
        if existing is not None:
            self._apply_payload(existing, payload)
            await self.db.flush()
            await self.db.refresh(existing)
            return self._to_response(existing)

        policy = LessonPolicy(teacher_id=teacher_id)
        self._apply_payload(policy, payload)
        self.db.add(policy)
        await self.db.flush()
        await self.db.refresh(policy)
        return self._to_response(policy)

    async def update_policy(
        self,
        policy_id: str,
        payload: LessonPolicyPayload,
        current_user: Any,
    ) -> LessonPolicyResponse:
        from app.models.policy import LessonPolicy

        policy = await self.db.get(LessonPolicy, policy_id)
        if policy is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
        current_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        self._assert_policy_teacher_owner(policy.teacher_id, current_teacher_id)
        if payload.teacher_id is not None:
            self._assert_policy_teacher_owner(payload.teacher_id, current_teacher_id)
        self._apply_payload(policy, payload)
        await self.db.flush()
        await self.db.refresh(policy)
        return self._to_response(policy)

    async def delete_policy(self, policy_id: str, current_user: Any) -> None:
        from app.models.policy import LessonPolicy

        policy = await self.db.get(LessonPolicy, policy_id)
        if policy is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson policy not found")
        current_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        self._assert_policy_teacher_owner(policy.teacher_id, current_teacher_id)
        await self.db.delete(policy)
        await self.db.flush()

    async def _get_by_teacher(self, teacher_id: str) -> Any | None:
        from app.models.policy import LessonPolicy

        return await self.db.scalar(select(LessonPolicy).where(LessonPolicy.teacher_id == teacher_id))

    def _assert_policy_teacher_owner(self, teacher_id: str, current_teacher_id: str) -> None:
        if teacher_id != current_teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot manage another teacher's policy")

    def _to_response(self, policy: Any) -> LessonPolicyResponse:
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

    def _apply_payload(self, policy: Any, payload: LessonPolicyPayload) -> None:
        if payload.min_cancel_hours is not None:
            policy.cancellation_deadline_hours = payload.min_cancel_hours
        if payload.max_changes_per_month is not None:
            policy.max_reschedule_per_subscription = payload.max_changes_per_month
        if payload.deduct_lesson_on_no_show is not None:
            policy.no_show_deducts_lesson = payload.deduct_lesson_on_no_show
        if payload.late_cancel_deadline is not None:
            policy.notes = payload.late_cancel_deadline
