"""Relationship and follow service."""

from __future__ import annotations

import secrets
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.services.student_id_resolver import resolve_student_id
from app.services.teacher_id_resolver import resolve_teacher_id, try_resolve_teacher_id


class RelationshipService:
    """Handle teacher-student relationships and follows."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def invite(self, student_id: str, method: str, current_user: Any) -> Any:
        """Create an invitation to connect with a student."""
        from app.models.relationship import RelationStatus, TeacherStudentRelation

        tid = await resolve_teacher_id(self.db, current_user.id)
        invite_code = secrets.token_urlsafe(6).upper()[:6]

        relation = TeacherStudentRelation(
            teacher_id=tid,
            student_id=student_id,
            invite_code=invite_code,
            status=RelationStatus.trialBooked,
        )
        self.db.add(relation)
        await self.db.flush()
        await self.db.refresh(relation)

        # Notification delivery (SMS/push) deferred until FCM integration

        return relation

    async def connect(self, invite_code: str, current_user: Any) -> Any:
        """Accept an invitation using an invite code."""
        from app.models.relationship import TeacherStudentRelation

        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.invite_code == invite_code,
                TeacherStudentRelation.status == "trialBooked",
            )
        )
        if relation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid or expired invite code",
            )

        student_id = await resolve_student_id(self.db, current_user.id)
        if relation.student_id != student_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid or expired invite code",
            )

        relation.status = "active"  # type: ignore[assignment]
        await self.db.flush()
        await self.db.refresh(relation)
        return relation

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        teacher_id: str | None = None,
        student_id: str | None = None,
        status: str | None = None,
        is_manually_registered: bool | None = None,
    ) -> PaginatedResponse:
        """List all relationships for the current user."""
        from app.models.relationship import TeacherStudentRelation

        tid = await try_resolve_teacher_id(self.db, user.id)
        query = select(TeacherStudentRelation).where(
            (TeacherStudentRelation.teacher_id == (tid or user.id)) | (TeacherStudentRelation.student_id == user.id)
        )
        if teacher_id is not None:
            query = query.where(TeacherStudentRelation.teacher_id == teacher_id)
        if student_id is not None:
            query = query.where(TeacherStudentRelation.student_id == student_id)
        if status is not None:
            query = query.where(TeacherStudentRelation.status == status)
        if is_manually_registered is not None:
            query = query.where(TeacherStudentRelation.is_manually_registered == is_manually_registered)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = result.all()

        return PaginatedResponse.create(items=list(items), total=total, page=page, size=size)

    async def get_by_id(self, relationship_id: str, current_user: Any) -> Any:
        """Return a single relationship by ID."""
        from app.models.relationship import TeacherStudentRelation

        relation = await self.db.get(TeacherStudentRelation, relationship_id)
        if relation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Relationship not found",
            )
        await self._assert_relationship_party(relation, current_user)
        return relation

    async def update_status(
        self,
        relationship_id: str,
        new_status: str | None,
        current_user: Any,
        *,
        subscription_id: str | None = None,
        booking_id: str | None = None,
        last_lesson_day: int | None = None,
        last_lesson_time: str | None = None,
        last_lesson_duration: int | None = None,
        can_view_practice: bool | None = None,
        can_comment: bool | None = None,
        can_suggest_assignments: bool | None = None,
    ) -> Any:
        """Change the status of a relationship with optional metadata."""
        from datetime import UTC, datetime

        from app.models.relationship import RelationStatus, TeacherStudentRelation

        relation = await self.db.get(TeacherStudentRelation, relationship_id)
        if relation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Relationship not found",
            )
        party = await self._relationship_party_role(relation, current_user)

        # Field-level authorization — the endpoint used to accept every field
        # from either party, letting a student self-grant privileged statuses
        # or forge subscription/booking links. Same-value status echoes pass
        # (FE PUTs the full model back); only privilege-escalating *changes*
        # are teacher-only. Permission flags stay writable by both parties
        # (CoachConnection contract: the teacher manages them).
        privileged_statuses = {
            RelationStatus.invitePending,
            RelationStatus.pending,
            RelationStatus.trialBooked,
            RelationStatus.active,
        }
        current_status = getattr(relation.status, "value", relation.status)
        if party != "teacher":
            if (
                new_status is not None
                and new_status != current_status
                and RelationStatus(new_status) in privileged_statuses
            ):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only the teacher may set this status",
                )
            if subscription_id or booking_id or last_lesson_day:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only the teacher may update relationship metadata",
                )

        if new_status is not None:
            relation.status = RelationStatus(new_status)

        # Update optional metadata
        if subscription_id:
            relation.active_subscription_id = subscription_id
        if booking_id:
            relation.trial_booking_id = booking_id
        if last_lesson_day:
            relation.last_lesson_day = str(last_lesson_day)
            relation.last_lesson_time = last_lesson_time
            relation.last_lesson_duration = last_lesson_duration
            relation.schedule_recorded_at = datetime.now(UTC)
        if can_view_practice is not None:
            relation.can_view_practice = can_view_practice
        if can_comment is not None:
            relation.can_comment = can_comment
        if can_suggest_assignments is not None:
            relation.can_suggest_assignments = can_suggest_assignments

        await self.db.flush()
        await self.db.refresh(relation)
        return relation

    async def get_notification_settings(self, user_id: str, target_user_id: str, current_user: Any) -> Any:
        """Return notification settings for a user/target pair, creating defaults when absent."""
        self._assert_notification_settings_owner(user_id, current_user)
        await self._assert_notification_settings_target_access(user_id, target_user_id)
        from app.models.settings import NotificationSettings

        settings = await self.db.scalar(
            select(NotificationSettings).where(
                NotificationSettings.user_id == user_id,
                NotificationSettings.target_user_id == target_user_id,
            )
        )
        if settings is None:
            settings = NotificationSettings(user_id=user_id, target_user_id=target_user_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def save_notification_settings(self, data: dict[str, Any], current_user: Any) -> Any:
        """Create or update notification settings from frontend payload."""
        user_id = data["user_id"]
        target_user_id = data["target_user_id"]
        settings = await self.get_notification_settings(user_id, target_user_id, current_user)

        for key in (
            "push_enabled",
            "practice_share_enabled",
            "lesson_reminder_enabled",
            "payment_reminder_enabled",
        ):
            if key in data:
                setattr(settings, key, data[key])

        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    async def delete_notification_settings(self, setting_id: str, current_user: Any) -> None:
        """Delete notification settings owned by the current user."""
        from app.models.settings import NotificationSettings

        settings = await self.db.get(NotificationSettings, setting_id)
        if settings is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification settings not found")
        self._assert_notification_settings_owner(settings.user_id, current_user)

        await self.db.delete(settings)
        await self.db.flush()

    async def _assert_relationship_party(self, relation: Any, current_user: Any) -> None:
        """Require the caller to be the teacher or student party of the relation."""
        await self._relationship_party_role(relation, current_user)

    async def _relationship_party_role(self, relation: Any, current_user: Any) -> str:
        """Return which side of the relation the caller is ("teacher"/"student")."""
        role = getattr(getattr(current_user, "role", None), "value", None)

        if role == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            if teacher_id == relation.teacher_id:
                return "teacher"
        elif role == "student":
            from app.models.student import Student

            student_id = await self.db.scalar(select(Student.id).where(Student.user_id == current_user.id))
            if student_id is not None and student_id == relation.student_id:
                return "student"

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another party's relationship",
        )

    def _assert_notification_settings_owner(self, user_id: str, current_user: Any) -> None:
        if user_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot manage another user's settings")

    async def _assert_notification_settings_target_access(self, user_id: str, target_user_id: str) -> None:
        """Require an active teacher-student relation before creating target settings."""
        if user_id == target_user_id:
            return

        if await self._has_active_teacher_student_relation(user_id, target_user_id):
            return

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot manage notification settings for an unrelated target",
        )

    async def _has_active_teacher_student_relation(self, user_id: str, target_user_id: str) -> bool:
        from app.models.relationship import RelationStatus, TeacherStudentRelation

        user_teacher_ids = await self._teacher_relation_ids_for_user(user_id)
        target_teacher_ids = await self._teacher_relation_ids_for_user(target_user_id)
        user_student_ids = await self._student_relation_ids_for_user(user_id)
        target_student_ids = await self._student_relation_ids_for_user(target_user_id)

        relation_id = await self.db.scalar(
            select(TeacherStudentRelation.id)
            .where(
                TeacherStudentRelation.status == RelationStatus.active,
                or_(
                    and_(
                        TeacherStudentRelation.teacher_id.in_(user_teacher_ids),
                        TeacherStudentRelation.student_id.in_(target_student_ids),
                    ),
                    and_(
                        TeacherStudentRelation.teacher_id.in_(target_teacher_ids),
                        TeacherStudentRelation.student_id.in_(user_student_ids),
                    ),
                ),
            )
            .limit(1)
        )
        return relation_id is not None

    async def _teacher_relation_ids_for_user(self, user_id: str) -> set[str]:
        teacher_ids = {user_id}
        teacher_id = await try_resolve_teacher_id(self.db, user_id)
        if teacher_id is not None:
            teacher_ids.add(teacher_id)
        return teacher_ids

    async def _student_relation_ids_for_user(self, user_id: str) -> set[str]:
        from app.models.student import Student

        student_ids = {user_id}
        result = await self.db.scalars(select(Student.id).where(Student.user_id == user_id))
        student_ids.update(result.all())
        return student_ids

    async def follow(self, following_id: str, target_type: str, current_user: Any) -> Any:
        """Follow a user."""
        from app.models.relationship import Follow

        follow = Follow(
            follower_id=current_user.id,
            following_id=following_id,
            target_type=target_type,
        )
        self.db.add(follow)
        await self.db.flush()
        await self.db.refresh(follow)
        return follow

    async def get_all_follows(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        follower_id: str | None = None,
        following_id: str | None = None,
        target_type: str | None = None,
        direction: str | None = None,
    ) -> PaginatedResponse:
        """List follows involving the current user."""
        from app.models.relationship import Follow

        query = select(Follow).where((Follow.follower_id == user.id) | (Follow.following_id == user.id))
        if direction == "following":
            query = query.where(Follow.follower_id == user.id)
        elif direction == "followers":
            query = query.where(Follow.following_id == user.id)
        elif direction is not None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid follow direction")

        if follower_id:
            query = query.where(Follow.follower_id == follower_id)
        if following_id:
            query = query.where(Follow.following_id == following_id)
        if target_type:
            query = query.where(Follow.target_type == target_type)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0
        result = await self.db.scalars(query.order_by(Follow.created_at.desc()).offset(offset).limit(size))
        follows = list(result.all())

        # Resolve following_name via User JOIN
        if follows:
            from app.models.user import User

            following_ids = [f.following_id for f in follows]
            users_result = await self.db.scalars(select(User).where(User.id.in_(following_ids)))
            name_map = {u.id: u.name for u in users_result.all()}
            for f in follows:
                f.following_name = name_map.get(f.following_id)

        return PaginatedResponse.create(items=follows, total=total, page=page, size=size)

    async def update_follow(self, follow_id: str, data: dict[str, Any], current_user: Any) -> Any:
        """Update follow preferences."""
        from app.models.relationship import Follow

        follow = await self.db.get(Follow, follow_id)
        if follow is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Follow not found")
        if follow.follower_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot update another user's follow")
        if "notification_enabled" in data:
            follow.notification_enabled = data["notification_enabled"]
        await self.db.flush()
        await self.db.refresh(follow)
        return follow

    async def unfollow(self, follow_id: str, current_user: Any) -> None:
        """Unfollow."""
        from app.models.relationship import Follow

        follow = await self.db.get(Follow, follow_id)
        if follow is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Follow not found",
            )
        if follow.follower_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot unfollow for another user",
            )
        await self.db.delete(follow)
        await self.db.flush()
