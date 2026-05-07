"""Recording service – upload, download, share."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.practice import (
    RecordingFeedbackCreate,
    RecordingFeedbackResponse,
    RecordingFeedbackUpdate,
    RecordingResponse,
    RecordingUploadResponse,
)


class RecordingService:
    """Handle recording upload to object storage, metadata, and sharing."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def upload(
        self,
        *,
        file: UploadFile,
        section_id: str | None,
        duration_seconds: int | None,
        bpm: int | None,
        user: Any,
    ) -> RecordingUploadResponse:
        """Upload a recording file to Vultr Object Storage and save metadata."""
        from app.models.practice import PracticeRecording

        # Generate unique file key
        file_ext = file.filename.rsplit(".", 1)[-1] if file.filename else "m4a"
        file_key = f"recordings/{uuid.uuid4()}.{file_ext}"

        # Upload to object storage
        file_url = await self._upload_to_storage(file_key, file)

        # Save metadata
        recording = PracticeRecording(
            section_id=section_id,
            student_id=user.id,
            file_path=file_key,
            file_url=file_url,
            file_key=file_key,
            duration_seconds=duration_seconds,
            bpm=bpm,
        )
        self.db.add(recording)
        await self.db.flush()
        await self.db.refresh(recording)
        return RecordingUploadResponse.model_validate(recording)

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        section_id: str | None = None,
        student_id: str | None = None,
    ) -> PaginatedResponse[RecordingResponse]:
        """List recordings with optional filters."""
        from app.models.practice import PracticeRecording

        query = select(PracticeRecording).where(await self._access_filter(PracticeRecording, user))
        if section_id:
            query = query.where(PracticeRecording.section_id == section_id)
        if student_id:
            query = query.where(PracticeRecording.student_id == student_id)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(
            query.order_by(PracticeRecording.created_at.desc()).offset(offset).limit(size)
        )
        items = [RecordingResponse.model_validate(r) for r in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_by_id(self, recording_id: str, current_user: Any) -> RecordingResponse:
        """Return recording metadata."""
        rec = await self._get_accessible_recording(recording_id, current_user)
        return RecordingResponse.model_validate(rec)

    async def get_download_url(self, recording_id: str, current_user: Any) -> dict:
        """Generate a presigned download URL."""
        rec = await self._get_accessible_recording(recording_id, current_user)

        download_url = await self._generate_presigned_url(rec.file_key)
        expires_at = datetime.now(UTC) + timedelta(hours=1)

        return {
            "download_url": download_url,
            "expires_at": expires_at.isoformat(),
        }

    async def delete(self, recording_id: str, current_user: Any) -> None:
        """Delete recording (file + metadata)."""
        rec = await self._get_accessible_recording(recording_id, current_user)

        # Delete from storage
        await self._delete_from_storage(rec.file_key)

        await self.db.delete(rec)
        await self.db.flush()

    async def set_representative(self, recording_id: str, current_user: Any) -> RecordingResponse:
        """Mark a recording as the representative for its section."""
        from app.models.practice import PracticeRecording

        rec = await self._get_accessible_recording(recording_id, current_user)

        # Unset previous representative for the same section
        if rec.section_id:
            result = await self.db.scalars(
                select(PracticeRecording).where(
                    PracticeRecording.section_id == rec.section_id,
                    PracticeRecording.student_id == current_user.id,
                    PracticeRecording.is_representative == True,  # noqa: E712
                )
            )
            for other in result.all():
                other.is_representative = False

        rec.is_representative = True
        await self.db.flush()
        await self.db.refresh(rec)
        return RecordingResponse.model_validate(rec)

    async def create_share_link(self, recording_id: str, current_user: Any) -> dict:
        """Generate a shareable link for a recording."""
        await self._get_accessible_recording(recording_id, current_user)

        share_token = str(uuid.uuid4())
        expires_at = datetime.now(UTC) + timedelta(days=7)

        return {
            "share_url": f"https://api.lessonaza.app/shared/recordings/{share_token}",
            "expires_at": expires_at.isoformat(),
        }

    async def list_feedback(self, recording_id: str, current_user: Any) -> list[RecordingFeedbackResponse]:
        """List feedback attached to an accessible recording."""
        from app.models.practice import RecordingFeedback

        await self._get_accessible_recording(recording_id, current_user)
        result = await self.db.scalars(
            select(RecordingFeedback)
            .where(RecordingFeedback.recording_id == recording_id)
            .order_by(RecordingFeedback.created_at.asc())
        )
        return [RecordingFeedbackResponse.model_validate(feedback) for feedback in result.all()]

    async def create_feedback(
        self,
        recording_id: str,
        data: RecordingFeedbackCreate,
        current_user: Any,
    ) -> RecordingFeedbackResponse:
        """Create teacher feedback for an accessible recording."""
        from app.models.practice import RecordingFeedback
        from app.services.teacher_id_resolver import resolve_teacher_id

        self._assert_teacher(current_user)
        await self._get_accessible_recording(recording_id, current_user)
        content = self._trim_feedback_content(data.content)
        teacher_id = await resolve_teacher_id(self.db, current_user.id)

        feedback = RecordingFeedback(
            recording_id=recording_id,
            teacher_id=teacher_id,
            content=content,
        )
        self.db.add(feedback)
        await self.db.flush()
        await self.db.refresh(feedback)
        return RecordingFeedbackResponse.model_validate(feedback)

    async def update_feedback(
        self,
        recording_id: str,
        feedback_id: str,
        data: RecordingFeedbackUpdate,
        current_user: Any,
    ) -> RecordingFeedbackResponse:
        """Update teacher feedback for an accessible recording."""
        feedback = await self._get_mutable_feedback(recording_id, feedback_id, current_user)
        feedback.content = self._trim_feedback_content(data.content)
        await self.db.flush()
        await self.db.refresh(feedback)
        return RecordingFeedbackResponse.model_validate(feedback)

    async def delete_feedback(self, recording_id: str, feedback_id: str, current_user: Any) -> None:
        """Delete teacher feedback for an accessible recording."""
        feedback = await self._get_mutable_feedback(recording_id, feedback_id, current_user)
        await self.db.delete(feedback)
        await self.db.flush()

    async def _get_accessible_recording(self, recording_id: str, current_user: Any) -> Any:
        """Return a recording when the current user may view it."""
        from app.models.practice import PracticeRecording

        rec = await self.db.scalar(
            select(PracticeRecording).where(
                PracticeRecording.id == recording_id,
                await self._access_filter(PracticeRecording, current_user),
            )
        )
        if rec is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")
        return rec

    async def _get_mutable_feedback(self, recording_id: str, feedback_id: str, current_user: Any) -> Any:
        """Return feedback when the current teacher authored it."""
        from app.models.practice import RecordingFeedback
        from app.services.teacher_id_resolver import resolve_teacher_id

        self._assert_teacher(current_user)
        await self._get_accessible_recording(recording_id, current_user)
        feedback = await self.db.scalar(
            select(RecordingFeedback).where(
                RecordingFeedback.id == feedback_id,
                RecordingFeedback.recording_id == recording_id,
            )
        )
        if feedback is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording feedback not found")

        teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if feedback.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return feedback

    def _assert_teacher(self, current_user: Any) -> None:
        role = getattr(getattr(current_user, "role", None), "value", None)
        if role != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access required")

    def _trim_feedback_content(self, content: str) -> str:
        trimmed = content.strip()
        if not trimmed:
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Feedback content is required")
        return trimmed

    async def _access_filter(self, recording_model: Any, current_user: Any) -> Any:
        """Build the recording visibility condition for a user.

        Students can access their own recordings. Teachers can also access recordings
        for students who have an active app-connected teacher-student relation.
        """
        accessible_student_ids = {current_user.id}

        role = getattr(getattr(current_user, "role", None), "value", None)
        if role == "teacher":
            from app.models.relationship import RelationStatus, TeacherStudentRelation
            from app.services.teacher_id_resolver import try_resolve_teacher_id

            teacher_id = await try_resolve_teacher_id(self.db, current_user.id)
            if teacher_id:
                result = await self.db.scalars(
                    select(TeacherStudentRelation.student_id).where(
                        TeacherStudentRelation.teacher_id == teacher_id,
                        TeacherStudentRelation.status == RelationStatus.active,
                        TeacherStudentRelation.is_app_connected == True,  # noqa: E712
                        TeacherStudentRelation.can_view_practice == True,  # noqa: E712
                    )
                )
                candidate_student_ids = result.all()
                accessible_student_ids.update(
                    await self._filter_students_with_practice_share_enabled(
                        list(candidate_student_ids),
                        current_user.id,
                    )
                )
        elif role == "parent":
            accessible_student_ids.update(await self._parent_visible_recording_student_ids(current_user.id))

        return recording_model.student_id.in_(accessible_student_ids)

    async def _filter_students_with_practice_share_enabled(
        self,
        student_ids: list[str],
        teacher_user_id: str,
    ) -> list[str]:
        """Keep students whose per-target practice sharing is enabled.

        Missing notification settings use the frontend/spec default: enabled.
        """
        if not student_ids:
            return []

        from app.models.settings import NotificationSettings

        disabled_result = await self.db.scalars(
            select(NotificationSettings.user_id).where(
                NotificationSettings.user_id.in_(student_ids),
                NotificationSettings.target_user_id == teacher_user_id,
                NotificationSettings.practice_share_enabled == False,  # noqa: E712
            )
        )
        disabled_student_ids = set(disabled_result.all())
        return [student_id for student_id in student_ids if student_id not in disabled_student_ids]

    async def _parent_visible_recording_student_ids(self, parent_user_id: str) -> list[str]:
        """Return linked child IDs whose recordings are visible to this parent."""
        from app.models.parent import Parent, ParentChildRelation, ParentVisibilitySettings

        parent = await self.db.scalar(select(Parent).where(Parent.user_id == parent_user_id))
        if parent is None:
            return []

        linked_result = await self.db.scalars(
            select(ParentChildRelation.student_id).where(ParentChildRelation.parent_id == parent.id)
        )
        linked_student_ids = linked_result.all()
        if not linked_student_ids:
            return []

        visible_result = await self.db.scalars(
            select(ParentVisibilitySettings.student_id).where(
                ParentVisibilitySettings.student_id.in_(linked_student_ids),
                ParentVisibilitySettings.can_view_recordings == True,  # noqa: E712
            )
        )
        return list(visible_result.all())

    # ------------------------------------------------------------------
    # Storage helpers (Vultr Object Storage via boto3)
    # ------------------------------------------------------------------

    async def _upload_to_storage(self, file_key: str, file: UploadFile) -> str:
        """Upload file to Vultr Object Storage and return the URL."""
        from app.core.config import settings

        try:
            import aioboto3

            session = aioboto3.Session()
            async with session.client(
                "s3",
                endpoint_url=settings.VULTR_STORAGE_ENDPOINT,
                aws_access_key_id=settings.VULTR_STORAGE_ACCESS_KEY,
                aws_secret_access_key=settings.VULTR_STORAGE_SECRET_KEY,
            ) as s3:
                content = await file.read()
                await s3.put_object(
                    Bucket=settings.VULTR_STORAGE_BUCKET,
                    Key=file_key,
                    Body=content,
                    ContentType=file.content_type or "audio/m4a",
                )
            return f"{settings.VULTR_STORAGE_ENDPOINT}/{settings.VULTR_STORAGE_BUCKET}/{file_key}"
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to upload file: {e}",
            )

    async def _generate_presigned_url(self, file_key: str) -> str:
        """Generate a presigned URL for downloading."""
        from app.core.config import settings

        try:
            import aioboto3

            session = aioboto3.Session()
            async with session.client(
                "s3",
                endpoint_url=settings.VULTR_STORAGE_ENDPOINT,
                aws_access_key_id=settings.VULTR_STORAGE_ACCESS_KEY,
                aws_secret_access_key=settings.VULTR_STORAGE_SECRET_KEY,
            ) as s3:
                url: str = await s3.generate_presigned_url(
                    "get_object",
                    Params={"Bucket": settings.VULTR_STORAGE_BUCKET, "Key": file_key},
                    ExpiresIn=3600,
                )
            return url
        except Exception:
            return ""

    async def _delete_from_storage(self, file_key: str) -> None:
        """Delete a file from object storage."""
        from app.core.config import settings

        try:
            import aioboto3

            session = aioboto3.Session()
            async with session.client(
                "s3",
                endpoint_url=settings.VULTR_STORAGE_ENDPOINT,
                aws_access_key_id=settings.VULTR_STORAGE_ACCESS_KEY,
                aws_secret_access_key=settings.VULTR_STORAGE_SECRET_KEY,
            ) as s3:
                await s3.delete_object(
                    Bucket=settings.VULTR_STORAGE_BUCKET,
                    Key=file_key,
                )
        except Exception:
            pass  # Log but don't fail the request
