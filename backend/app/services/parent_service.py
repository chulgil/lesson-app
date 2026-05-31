"""Parent service."""

from __future__ import annotations

import secrets
import string
from datetime import UTC, date, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.lesson import LessonResponse
from app.schemas.parent import (
    ChildProfileCreate,
    ChildProfileResponse,
    ChildProfileUpdate,
    ChildTeacherConnectRequest,
    ParentChildRelationResponse,
    ParentChildRelationUpdate,
    ParentCreate,
    ParentInvitationCreate,
    ParentInvitationResponse,
    ParentNotificationSettingsResponse,
    ParentNotificationSettingsUpdate,
    ParentResponse,
    ParentUpdate,
    ParentVisibilitySettingsResponse,
    ParentVisibilitySettingsUpdate,
)
from app.schemas.practice import PracticeStatsResponse


class ParentService:
    """Handle parent profile and child management."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_parents(self, current_user: Any) -> PaginatedResponse[ParentResponse]:
        """Return parent profiles visible to the current user."""
        from app.models.parent import Parent

        query = select(Parent)
        role = self._role(current_user)
        if role == "parent":
            query = query.where(Parent.user_id == current_user.id)
        elif role not in {"teacher", "student"}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to list parents")

        result = await self.db.scalars(query.order_by(Parent.created_at.desc()))
        items = [ParentResponse.model_validate(parent) for parent in result.all()]
        return PaginatedResponse.create(items=items, total=len(items), page=1, size=max(len(items), 1))

    async def get_parent(self, parent_id: str, current_user: Any) -> ParentResponse:
        """Return a parent profile by ID."""
        parent = await self._get_parent_or_404(parent_id)
        await self._assert_can_access_parent(parent.id, current_user)
        return ParentResponse.model_validate(parent)

    async def create_parent(self, data: ParentCreate, current_user: Any) -> ParentResponse:
        """Create a parent profile."""
        from app.models.parent import Parent, ParentStatus

        role = self._role(current_user)
        user_id = current_user.id if role == "parent" or data.user_id is None else data.user_id

        existing = await self.db.scalar(select(Parent).where(Parent.user_id == user_id))
        if existing is not None:
            if role == "parent" and existing.user_id == current_user.id:
                existing.name = data.name
                existing.phone = data.phone
                existing.email = data.email
                existing.profile_image_url = data.profile_image_url
                existing.profile_color = data.profile_color
                await self.db.flush()
                await self.db.refresh(existing)
                return ParentResponse.model_validate(existing)
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Parent profile already exists")

        parent = Parent(
            user_id=user_id,
            name=data.name,
            phone=data.phone,
            email=data.email,
            profile_image_url=data.profile_image_url,
            profile_color=data.profile_color,
            status=ParentStatus.active if role == "parent" else ParentStatus.pending,
        )
        self.db.add(parent)
        await self.db.flush()
        await self.db.refresh(parent)
        return ParentResponse.model_validate(parent)

    async def delete_parent(self, parent_id: str, current_user: Any) -> None:
        """Delete a parent profile and related parent-child relations."""
        from app.models.parent import ParentChildRelation

        parent = await self._get_parent_or_404(parent_id)
        await self._assert_can_access_parent(parent.id, current_user)

        relations = await self.db.scalars(
            select(ParentChildRelation).where(ParentChildRelation.parent_id == parent.id)
        )
        for relation in relations.all():
            await self.db.delete(relation)
        await self.db.delete(parent)
        await self.db.flush()

    async def get_profile(self, current_user: Any) -> ParentResponse:
        """Return the parent profile."""
        from app.models.parent import Parent

        parent = await self.db.scalar(
            select(Parent).where(Parent.user_id == current_user.id)
        )
        if parent is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent profile not found")
        return ParentResponse.model_validate(parent)

    async def update_profile(self, data: ParentUpdate, current_user: Any) -> ParentResponse:
        """Update the parent profile."""
        from app.models.parent import Parent

        parent = await self.db.scalar(
            select(Parent).where(Parent.user_id == current_user.id)
        )
        if parent is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent profile not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(parent, key, value)
        await self.db.flush()
        await self.db.refresh(parent)
        return ParentResponse.model_validate(parent)

    async def get_children(self, current_user: Any) -> list[ParentChildRelationResponse]:
        """Return the list of linked children."""
        from app.models.parent import Parent, ParentChildRelation

        parent = await self.db.scalar(
            select(Parent).where(Parent.user_id == current_user.id)
        )
        if parent is None:
            return []

        relations = await self.db.scalars(
            select(ParentChildRelation).where(ParentChildRelation.parent_id == parent.id)
        )

        return [self._relation_response(relation) for relation in relations.all()]

    async def connect_child(self, invite_code: str, current_user: Any) -> ParentChildRelationResponse:
        """Link a child via invite code."""
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus, ParentInvitation
        from app.models.relationship import TeacherStudentRelation
        from app.models.student import Student

        parent = await self.db.scalar(
            select(Parent).where(Parent.user_id == current_user.id)
        )
        if parent is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent profile not found")

        invitation = await self.db.scalar(
            select(ParentInvitation).where(
                ParentInvitation.invitation_code == invite_code,
                ParentInvitation.expires_at > datetime.now(UTC),
            )
        )
        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.invite_code == invite_code,
            )
        )
        if invitation is None and relation is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid invite code")

        student_id = invitation.student_id if invitation is not None else relation.student_id  # type: ignore[union-attr]
        student = await self.db.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        existing = await self.db.scalar(
            select(ParentChildRelation).where(
                ParentChildRelation.parent_id == parent.id,
                ParentChildRelation.student_id == student.id,
            )
        )
        if existing:
            return self._relation_response(existing)

        if invitation is not None and invitation.is_used:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Invitation already used")

        link = ParentChildRelation(
            parent_id=parent.id,
            student_id=student.id,
            status=ParentChildRelationStatus.active,
        )
        self.db.add(link)
        if invitation is not None:
            invitation.is_used = True
        await self.db.flush()
        await self.db.refresh(link)

        return self._relation_response(link)

    async def get_child_profiles(self, parent_id: str, current_user: Any) -> list[ChildProfileResponse]:
        """Return active child profiles for a parent."""
        from app.models.parent import ParentChildRelation, ParentChildRelationStatus
        from app.models.student import Student

        await self._assert_can_access_parent(parent_id, current_user)
        result = await self.db.execute(
            select(Student, ParentChildRelation)
            .join(ParentChildRelation, ParentChildRelation.student_id == Student.id)
            .where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
            .order_by(Student.created_at.desc())
        )
        return [await self._child_profile_response(student, relation) for student, relation in result.all()]

    async def get_child_profile(self, child_id: str, current_user: Any) -> ChildProfileResponse:
        """Return a child profile if visible to the current parent/teacher."""
        student, relation = await self._get_child_profile_for_user(child_id, current_user)
        return await self._child_profile_response(student, relation)

    async def create_child_profile(
        self,
        data: ChildProfileCreate,
        current_user: Any,
    ) -> ChildProfileResponse:
        """Create a parent-owned child profile backed by Student."""
        from app.models.parent import ParentChildRelation, ParentChildRelationStatus
        from app.models.student import Student, StudentLevel

        await self._assert_can_access_parent(data.parent_id, current_user)
        student = Student(
            teacher_id=None,
            name=data.name,
            instrument=data.instrument,
            level=StudentLevel(data.level),
            birth_date=date(data.birth_year, 1, 1),
            profile_color=data.profile_color or "#6B5B95",
        )
        self.db.add(student)
        await self.db.flush()

        relation = ParentChildRelation(
            parent_id=data.parent_id,
            student_id=student.id,
            status=ParentChildRelationStatus.active,
        )
        self.db.add(relation)
        await self.db.flush()
        await self.db.refresh(student)
        await self.db.refresh(relation)
        return await self._child_profile_response(student, relation)

    async def update_child_profile(
        self,
        child_id: str,
        data: ChildProfileUpdate,
        current_user: Any,
    ) -> ChildProfileResponse:
        """Update a parent-owned child profile."""
        from app.models.parent import ParentChildRelationStatus
        from app.models.student import StudentLevel

        student, relation = await self._get_child_profile_for_user(child_id, current_user)
        update_data = data.model_dump(exclude_unset=True)
        if "name" in update_data:
            student.name = update_data["name"]
        if "instrument" in update_data:
            student.instrument = update_data["instrument"]
        if "level" in update_data:
            student.level = StudentLevel(update_data["level"])
        if "birth_year" in update_data:
            student.birth_date = date(update_data["birth_year"], 1, 1)
        if "profile_color" in update_data:
            student.profile_color = update_data["profile_color"]
        if "status" in update_data:
            relation.status = ParentChildRelationStatus(update_data["status"])
            if relation.status == ParentChildRelationStatus.inactive and relation.unlinked_at is None:
                relation.unlinked_at = datetime.now(UTC)
            elif relation.status != ParentChildRelationStatus.inactive:
                relation.unlinked_at = None

        await self.db.flush()
        await self.db.refresh(student)
        await self.db.refresh(relation)
        return await self._child_profile_response(student, relation)

    async def delete_child_profile(self, child_id: str, current_user: Any) -> None:
        """Soft-delete a child profile by marking the parent relation inactive."""
        from app.models.parent import ParentChildRelationStatus

        student, relation = await self._get_child_profile_for_user(child_id, current_user)
        student.is_active = False
        relation.status = ParentChildRelationStatus.inactive
        relation.unlinked_at = datetime.now(UTC)
        await self.db.flush()

    async def connect_teacher_to_child(
        self,
        child_id: str,
        data: ChildTeacherConnectRequest,
        current_user: Any,
    ) -> ChildProfileResponse:
        """Connect a teacher to a parent-owned child profile."""
        from app.models.relationship import RelationStatus, TeacherStudentRelation
        from app.models.teacher import Teacher

        student, relation = await self._get_child_profile_for_user(child_id, current_user)
        teacher = await self.db.get(Teacher, data.teacher_id)
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")

        student.teacher_id = teacher.id
        teacher_relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id == teacher.id,
                TeacherStudentRelation.student_id == student.id,
            )
        )
        if teacher_relation is None:
            teacher_relation = TeacherStudentRelation(
                teacher_id=teacher.id,
                student_id=student.id,
                status=RelationStatus.active,
                connected_at=datetime.now(UTC),
                is_app_connected=True,
                app_connected_at=datetime.now(UTC),
            )
            self.db.add(teacher_relation)
        else:
            teacher_relation.status = RelationStatus.active
            teacher_relation.connected_at = teacher_relation.connected_at or datetime.now(UTC)
            teacher_relation.disconnected_at = None
            teacher_relation.is_app_connected = True
            teacher_relation.app_connected_at = teacher_relation.app_connected_at or datetime.now(UTC)

        await self.db.flush()
        await self.db.refresh(student)
        return await self._child_profile_response(student, relation, teacher_name=data.teacher_name)

    async def disconnect_teacher_from_child(
        self,
        child_id: str,
        current_user: Any,
    ) -> ChildProfileResponse:
        """Disconnect the current teacher relation from a child profile."""
        from app.models.relationship import RelationStatus, TeacherStudentRelation

        student, relation = await self._get_child_profile_for_user(child_id, current_user)
        if student.teacher_id:
            teacher_relation = await self.db.scalar(
                select(TeacherStudentRelation).where(
                    TeacherStudentRelation.teacher_id == student.teacher_id,
                    TeacherStudentRelation.student_id == student.id,
                )
            )
            if teacher_relation is not None:
                teacher_relation.status = RelationStatus.disconnected
                teacher_relation.disconnected_at = datetime.now(UTC)
                teacher_relation.is_app_connected = False
        student.teacher_id = None
        await self.db.flush()
        await self.db.refresh(student)
        return await self._child_profile_response(student, relation)

    async def get_child_lessons(
        self,
        student_id: str,
        current_user: Any,
        *,
        date_from: str | None = None,
        date_to: str | None = None,
    ) -> list[LessonResponse]:
        """Return lessons for a linked child."""
        from app.models.lesson import Lesson
        from app.models.parent import ParentVisibilitySettings

        await self._assert_parent_can_access_child(current_user.id, student_id)

        blocked_visibility = (
            select(ParentVisibilitySettings.id)
            .where(
                ParentVisibilitySettings.teacher_id == Lesson.teacher_id,
                ParentVisibilitySettings.student_id == Lesson.student_id,
                ParentVisibilitySettings.can_view_schedule == False,  # noqa: E712
            )
            .exists()
        )
        query = select(Lesson).where(
            Lesson.student_id == student_id,
            ~blocked_visibility,
        )
        if date_from:
            query = query.where(Lesson.date >= date_from)
        if date_to:
            query = query.where(Lesson.date <= date_to)

        result = await self.db.scalars(query.order_by(Lesson.date.desc()))
        return [LessonResponse.model_validate(lesson) for lesson in result.all()]

    async def _assert_parent_can_access_child(self, parent_user_id: str, student_id: str) -> None:
        from app.models.parent import Parent, ParentChildRelation

        parent = await self.db.scalar(
            select(Parent).where(
                Parent.user_id == parent_user_id,
                Parent.status == "active",
            )
        )
        if parent is None:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Parent access denied")

        relation = await self.db.scalar(
            select(ParentChildRelation.id).where(
                ParentChildRelation.parent_id == parent.id,
                ParentChildRelation.student_id == student_id,
                ParentChildRelation.status == "active",
            )
        )
        if relation is None:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Child access denied")

    async def get_child_practice(
        self,
        student_id: str,
        current_user: Any,
        *,
        year: int | None = None,
        month: int | None = None,
    ) -> PracticeStatsResponse:
        """Return practice statistics for a child."""
        from app.services.practice_service import PracticeService

        practice_svc = PracticeService(self.db)
        return await practice_svc.get_stats(student_id, year, month, current_user)

    async def create_invitation(
        self,
        data: ParentInvitationCreate,
        current_user: Any,
    ) -> ParentInvitationResponse:
        """Create a parent invitation."""
        from app.models.parent import ParentInvitation, ParentInvitationSource
        from app.models.user import User
        from app.services.teacher_id_resolver import resolve_teacher_id

        source = ParentInvitationSource(data.source)
        role = self._role(current_user)
        if source == ParentInvitationSource.teacher:
            if role != "teacher":
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access required")
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            if data.teacher_id is not None and data.teacher_id != teacher_id:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to invite for teacher")
        elif role == "student" and current_user.id != data.student_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to invite for student")
        elif role not in {"teacher", "student"}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to create invitation")

        student = await self.db.get(User, data.student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        invitation = ParentInvitation(
            student_id=data.student_id,
            teacher_id=data.teacher_id,
            source=source,
            parent_phone=data.parent_phone,
            parent_email=data.parent_email,
            invitation_code=await self._generate_invitation_code(),
            expires_at=datetime.now(UTC) + timedelta(days=7),
        )
        self.db.add(invitation)
        await self.db.flush()
        await self.db.refresh(invitation)
        return ParentInvitationResponse.model_validate(invitation)

    async def get_or_list_invitations(
        self,
        current_user: Any,
        *,
        code: str | None = None,
        student_id: str | None = None,
        status_filter: str | None = None,
    ) -> Any:
        """Return one invitation by code or a paginated invitation list."""
        from app.models.parent import ParentInvitation

        if code:
            invitation = await self.db.scalar(
                select(ParentInvitation).where(ParentInvitation.invitation_code == code)
            )
            if invitation is None:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")
            return ParentInvitationResponse.model_validate(invitation)

        query = select(ParentInvitation)
        role = self._role(current_user)
        if role == "teacher":
            from app.models.student import Student
            from app.services.teacher_id_resolver import resolve_teacher_id

            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            if student_id is not None:
                student = await self.db.get(Student, student_id)
                if student is not None and student.teacher_id != teacher_id:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Not allowed to view invitations",
                    )
            query = query.where(ParentInvitation.teacher_id == teacher_id)
        elif role == "student":
            query = query.where(ParentInvitation.student_id == current_user.id)
            if student_id is not None and student_id != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not allowed to view invitations",
                )
        else:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to view invitations")
        if student_id:
            query = query.where(ParentInvitation.student_id == student_id)
        if status_filter == "pending":
            query = query.where(
                ParentInvitation.is_used == False,  # noqa: E712
                ParentInvitation.expires_at > datetime.now(UTC),
            )
        elif status_filter == "used":
            query = query.where(ParentInvitation.is_used == True)  # noqa: E712

        result = await self.db.scalars(query.order_by(ParentInvitation.created_at.desc()))
        items = [ParentInvitationResponse.model_validate(invitation) for invitation in result.all()]
        return PaginatedResponse.create(items=items, total=len(items), page=1, size=max(len(items), 1))

    async def mark_invitation_used(self, invitation_id: str, current_user: Any) -> ParentInvitationResponse:
        """Mark a parent invitation as used."""
        from app.models.parent import ParentInvitation

        invitation = await self.db.get(ParentInvitation, invitation_id)
        if invitation is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")
        invitation.is_used = True
        await self.db.flush()
        await self.db.refresh(invitation)
        return ParentInvitationResponse.model_validate(invitation)

    async def get_relations_for_student(
        self,
        student_id: str,
        current_user: Any,
    ) -> PaginatedResponse[ParentChildRelationResponse]:
        """Return parent-child relations for a student."""
        from app.models.parent import ParentChildRelation

        role = self._role(current_user)
        if role not in {"teacher", "student", "parent"}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to view relations")
        if role == "student" and current_user.id != student_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to view relations")
        await self._assert_can_view_student_relations(student_id, current_user)

        result = await self.db.scalars(
            select(ParentChildRelation).where(ParentChildRelation.student_id == student_id)
        )
        items = [self._relation_response(relation) for relation in result.all()]
        return PaginatedResponse.create(items=items, total=len(items), page=1, size=max(len(items), 1))

    async def _assert_can_view_student_relations(self, student_id: str, current_user: Any) -> None:
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus, ParentStatus
        from app.models.student import Student
        from app.services.teacher_id_resolver import resolve_teacher_id

        role = self._role(current_user)
        student = await self.db.get(Student, student_id)
        if role == "teacher":
            if student is None:
                return
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            if student.teacher_id == teacher_id:
                return
        elif role == "student":
            if current_user.id == student_id or (student is not None and student.user_id == current_user.id):
                return
        elif role == "parent":
            parent = await self.db.scalar(
                select(Parent).where(
                    Parent.user_id == current_user.id,
                    Parent.status == ParentStatus.active,
                )
            )
            if parent is not None:
                relation = await self.db.scalar(
                    select(ParentChildRelation.id).where(
                        ParentChildRelation.parent_id == parent.id,
                        ParentChildRelation.student_id == student_id,
                        ParentChildRelation.status == ParentChildRelationStatus.active,
                    )
                )
                if relation is not None:
                    return

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to view relations")

    async def update_relation(
        self,
        relation_id: str,
        data: ParentChildRelationUpdate,
        current_user: Any,
    ) -> ParentChildRelationResponse:
        """Update parent-child relation flags/status."""
        from app.models.parent import ParentChildRelationStatus

        relation = await self._get_relation_or_404(relation_id)
        await self._assert_can_manage_relation(relation.parent_id, current_user)

        update_data = data.model_dump(exclude_none=True)
        for key, value in update_data.items():
            if key in {"parent_id", "student_id"}:
                continue
            if key == "status":
                value = ParentChildRelationStatus(value)
                if value == ParentChildRelationStatus.inactive and relation.unlinked_at is None:
                    relation.unlinked_at = datetime.now(UTC)
                elif value != ParentChildRelationStatus.inactive:
                    relation.unlinked_at = None
            setattr(relation, key, value)

        await self.db.flush()
        await self.db.refresh(relation)
        return self._relation_response(relation)

    async def delete_relation(self, relation_id: str, current_user: Any) -> None:
        """Delete a parent-child relation."""
        relation = await self._get_relation_or_404(relation_id)
        await self._assert_can_manage_relation(relation.parent_id, current_user)
        await self.db.delete(relation)
        await self.db.flush()

    async def get_billing_target_for_student(self, student_id: str, current_user: Any) -> ParentResponse:
        """Return the active billing-target parent for a student."""
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        result = await self.db.scalars(
            select(Parent)
            .join(ParentChildRelation, ParentChildRelation.parent_id == Parent.id)
            .where(
                ParentChildRelation.student_id == student_id,
                ParentChildRelation.is_billing_target == True,  # noqa: E712
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        parent = result.first()
        if parent is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Billing target not found")
        return ParentResponse.model_validate(parent)

    async def get_parent_notification_settings(
        self,
        parent_id: str,
        current_user: Any,
    ) -> ParentNotificationSettingsResponse:
        """Return parent notification settings."""
        await self._assert_can_access_parent(parent_id, current_user)
        settings = await self._get_or_create_parent_notification_settings(parent_id)
        return ParentNotificationSettingsResponse.model_validate(settings)

    async def save_parent_notification_settings(
        self,
        data: ParentNotificationSettingsUpdate,
        current_user: Any,
    ) -> ParentNotificationSettingsResponse:
        """Update parent notification settings, keeping required payment toggles on."""
        await self._assert_can_access_parent(data.parent_id, current_user)
        settings = await self._get_or_create_parent_notification_settings(data.parent_id)
        update_data = data.model_dump(exclude={"parent_id"}, exclude_none=True)
        update_data.pop("payment_request", None)
        update_data.pop("payment_complete", None)
        for key, value in update_data.items():
            setattr(settings, key, value)
        settings.payment_request = True
        settings.payment_complete = True
        await self.db.flush()
        await self.db.refresh(settings)
        return ParentNotificationSettingsResponse.model_validate(settings)

    async def get_visibility_settings(
        self,
        teacher_id: str,
        student_id: str,
        current_user: Any,
    ) -> ParentVisibilitySettingsResponse:
        """Return visibility settings, creating spec defaults when absent."""
        await self._assert_can_read_visibility_settings(teacher_id, student_id, current_user)
        settings = await self._get_or_create_visibility_settings(teacher_id, student_id)
        return ParentVisibilitySettingsResponse.model_validate(settings)

    async def save_visibility_settings(
        self,
        data: ParentVisibilitySettingsUpdate,
        current_user: Any,
    ) -> ParentVisibilitySettingsResponse:
        """Create or update visibility settings for a teacher/student pair."""
        await self._assert_can_write_visibility_settings(data.teacher_id, current_user)
        settings = await self._get_or_create_visibility_settings(data.teacher_id, data.student_id)
        update_data = data.model_dump(exclude={"teacher_id", "student_id"}, exclude_none=True)
        for key, value in update_data.items():
            setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return ParentVisibilitySettingsResponse.model_validate(settings)

    async def _get_or_create_visibility_settings(self, teacher_id: str, student_id: str) -> Any:
        from app.models.parent import ParentVisibilitySettings

        settings = await self.db.scalar(
            select(ParentVisibilitySettings).where(
                ParentVisibilitySettings.teacher_id == teacher_id,
                ParentVisibilitySettings.student_id == student_id,
            )
        )
        if settings is None:
            settings = ParentVisibilitySettings(teacher_id=teacher_id, student_id=student_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def _assert_can_read_visibility_settings(
        self,
        teacher_id: str,
        student_id: str,
        current_user: Any,
    ) -> None:
        role = getattr(getattr(current_user, "role", None), "value", None)
        if role == "teacher":
            await self._assert_teacher_owns_visibility_settings(teacher_id, current_user.id)
            return

        if role == "parent":
            if await self._parent_is_linked_to_student(current_user.id, student_id):
                return
        elif role == "student" and current_user.id == student_id:
            return

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to view visibility settings")

    async def _assert_can_write_visibility_settings(self, teacher_id: str, current_user: Any) -> None:
        role = getattr(getattr(current_user, "role", None), "value", None)
        if role != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access required")

        await self._assert_teacher_owns_visibility_settings(teacher_id, current_user.id)

    async def _assert_teacher_owns_visibility_settings(self, teacher_id: str, teacher_user_id: str) -> None:
        from app.services.teacher_id_resolver import resolve_teacher_id

        current_teacher_id = await resolve_teacher_id(self.db, teacher_user_id)
        if current_teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to manage this teacher")

    async def _parent_is_linked_to_student(self, parent_user_id: str, student_id: str) -> bool:
        from app.models.parent import Parent, ParentChildRelation

        parent = await self.db.scalar(select(Parent).where(Parent.user_id == parent_user_id))
        if parent is None:
            return False

        relation = await self.db.scalar(
            select(ParentChildRelation.id).where(
                ParentChildRelation.parent_id == parent.id,
                ParentChildRelation.student_id == student_id,
            )
        )
        return relation is not None

    async def _get_parent_or_404(self, parent_id: str) -> Any:
        from app.models.parent import Parent

        parent = await self.db.get(Parent, parent_id)
        if parent is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent not found")
        return parent

    async def _get_relation_or_404(self, relation_id: str) -> Any:
        from app.models.parent import ParentChildRelation

        relation = await self.db.get(ParentChildRelation, relation_id)
        if relation is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Relation not found")
        return relation

    async def _get_child_profile_for_user(self, child_id: str, current_user: Any) -> tuple[Any, Any]:
        """Return Student and parent relation if the current user can access the child."""
        from app.models.parent import ParentChildRelation
        from app.models.student import Student

        student = await self.db.get(Student, child_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child profile not found")

        relation = await self.db.scalar(select(ParentChildRelation).where(ParentChildRelation.student_id == child_id))
        if relation is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child profile not found")

        await self._assert_can_access_parent(relation.parent_id, current_user)
        return student, relation

    async def _child_profile_response(
        self,
        student: Any,
        relation: Any,
        *,
        teacher_name: str | None = None,
    ) -> ChildProfileResponse:
        """Map Student + ParentChildRelation to the Flutter child profile shape."""
        if teacher_name is None and student.teacher_id:
            teacher_name = await self._teacher_name(student.teacher_id)

        status_value = getattr(relation.status, "value", relation.status)
        teacher_id = student.teacher_id or None
        connection_status = "connected" if status_value == "active" and teacher_id else "unconnected"
        if status_value == "pending":
            connection_status = "pending"

        return ChildProfileResponse(
            id=student.id,
            parent_id=relation.parent_id,
            name=student.name,
            birth_year=student.birth_date.year if student.birth_date else date.today().year,
            instrument=student.instrument,
            level=getattr(student.level, "value", student.level),
            teacher_id=teacher_id,
            teacher_name=teacher_name,
            linked_student_id=student.id,
            profile_color=student.profile_color or "#6B5B95",
            status=status_value,
            connection_status=connection_status,
            created_at=student.created_at,
            updated_at=student.updated_at,
        )

    async def _teacher_name(self, teacher_id: str) -> str | None:
        from app.models.teacher import Teacher
        from app.models.user import User

        result = await self.db.execute(
            select(User.name)
            .join(Teacher, Teacher.user_id == User.id)
            .where(Teacher.id == teacher_id)
        )
        name: str | None = result.scalar_one_or_none()
        return name

    async def _assert_can_access_parent(self, parent_id: str, current_user: Any) -> None:
        from app.models.parent import Parent

        role = self._role(current_user)
        if role == "teacher":
            return
        if role == "parent":
            parent_user_id = await self.db.scalar(select(Parent.user_id).where(Parent.id == parent_id))
            if parent_user_id == current_user.id:
                return
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to access parent")

    async def _assert_can_manage_relation(self, parent_id: str, current_user: Any) -> None:
        role = self._role(current_user)
        if role == "teacher":
            return
        await self._assert_can_access_parent(parent_id, current_user)

    async def _get_or_create_parent_notification_settings(self, parent_id: str) -> Any:
        from app.models.settings import ParentNotificationSettings

        settings = await self.db.scalar(
            select(ParentNotificationSettings).where(ParentNotificationSettings.parent_id == parent_id)
        )
        if settings is None:
            settings = ParentNotificationSettings(parent_id=parent_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    def _relation_response(self, relation: Any) -> ParentChildRelationResponse:
        return ParentChildRelationResponse(
            id=relation.id,
            parent_id=relation.parent_id,
            student_id=relation.student_id,
            is_primary_guardian=relation.is_primary_guardian,
            is_billing_target=relation.is_billing_target,
            status=getattr(relation.status, "value", relation.status),
            linked_at=relation.connected_at,
            unlinked_at=relation.unlinked_at,
        )

    async def _generate_invitation_code(self) -> str:
        from app.models.parent import ParentInvitation

        alphabet = string.ascii_uppercase + string.digits
        while True:
            code = "".join(secrets.choice(alphabet) for _ in range(8))
            exists = await self.db.scalar(
                select(ParentInvitation.id).where(ParentInvitation.invitation_code == code)
            )
            if exists is None:
                return code

    def _role(self, current_user: Any) -> str | None:
        return getattr(getattr(current_user, "role", None), "value", None)
