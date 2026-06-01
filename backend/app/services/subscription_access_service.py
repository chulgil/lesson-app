"""Subscription access policy helpers."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.teacher_id_resolver import try_resolve_teacher_id


class SubscriptionAccessService:
    """Resolve subscription visibility and ownership for user roles."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    def actor_type(self, user: Any) -> str:
        role = getattr(user, "role", None)
        return getattr(role, "value", role) or ""

    async def visible_student_ids(self, user: Any) -> list[str]:
        """Return Student ids visible to student or parent actors."""
        role = self.actor_type(user)
        if role == "student":
            return await self.student_identifiers(user)
        if role == "parent":
            return await self.parent_child_student_ids(user)
        return []

    async def teacher_identifiers(self, user: Any) -> list[str]:
        identifiers = [user.id]
        teacher_profile_id = await try_resolve_teacher_id(self.db, user.id)
        if teacher_profile_id and teacher_profile_id not in identifiers:
            identifiers.append(teacher_profile_id)
        return identifiers

    async def student_identifiers(self, user: Any) -> list[str]:
        """Return user id plus linked Student profile ids for student actors."""
        from app.models.student import Student

        identifiers = [user.id]
        result = await self.db.scalars(select(Student.id).where(Student.user_id == user.id))
        for student_id in result.all():
            if student_id not in identifiers:
                identifiers.append(student_id)
        return identifiers

    async def parent_child_student_ids(self, user: Any) -> list[str]:
        """Return active child Student ids for a parent user."""
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == user.id))
        if parent_id is None:
            return []

        result = await self.db.scalars(
            select(ParentChildRelation.student_id).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        return list(result.all())

    async def visible_subscription_query(self, query: Select[Any], user: Any) -> Select[Any]:
        """Apply current-user visibility constraints to a Subscription query."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        role = self.actor_type(user)
        if role in {"student", "parent"}:
            return query.where(Subscription.student_id.in_(await self.visible_student_ids(user)))
        if role == "teacher":
            return (
                query.join(ClassMembership, Subscription.membership_id == ClassMembership.id)
                .join(LessonClass, ClassMembership.lesson_class_id == LessonClass.id)
                .where(LessonClass.teacher_id.in_(await self.teacher_identifiers(user)))
            )
        return query.where(False)

    async def get_subscription_for_user(self, subscription_id: str, current_user: Any) -> Any:
        """Return subscription if the current user can access it."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.subscription import Subscription

        sub = await self.db.get(Subscription, subscription_id)
        if sub is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subscription not found",
            )

        role = self.actor_type(current_user)
        if role in {"student", "parent"} and sub.student_id in await self.visible_student_ids(current_user):
            return sub

        if role == "teacher":
            teacher_id = await self.db.scalar(
                select(LessonClass.teacher_id)
                .join(ClassMembership, ClassMembership.lesson_class_id == LessonClass.id)
                .where(ClassMembership.id == sub.membership_id)
            )
            if teacher_id in await self.teacher_identifiers(current_user):
                return sub

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def require_teacher_subscription(self, subscription_id: str, current_user: Any) -> Any:
        """Return a subscription only when the actor is the owning teacher."""
        sub = await self.get_subscription_for_user(subscription_id, current_user)
        if self.actor_type(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return sub

    async def get_membership_for_teacher(
        self,
        membership_id: str,
        current_user: Any,
        *,
        student_id: str | None = None,
    ) -> Any:
        """Return membership only when it belongs to the current teacher."""
        from app.models.lesson import ClassMembership, LessonClass

        membership = await self.db.scalar(
            select(ClassMembership)
            .join(LessonClass, ClassMembership.lesson_class_id == LessonClass.id)
            .where(
                ClassMembership.id == membership_id,
                LessonClass.teacher_id.in_(await self.teacher_identifiers(current_user)),
            )
        )
        if membership is None:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        if student_id is not None and membership.student_id != student_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="membership_id does not belong to student_id",
            )
        return membership
