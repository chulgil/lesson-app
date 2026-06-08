"""Profile image upload service — Vultr Object Storage."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.profile_image import ProfileImageUploadResponse


class ProfileImageService:
    """Handle profile and background image upload to Vultr Object Storage."""

    ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
    MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

    def __init__(self, db: AsyncSession | None = None) -> None:
        self.db = db

    async def _assert_can_modify_entity(
        self,
        *,
        current_user_id: str,
        entity_type: str,
        entity_id: str | None,
    ) -> None:
        """Reject cross-tenant access before any storage or DB mutation.

        - entity_type="teacher": entity_id is ignored — service only mutates the
          current user's own row (no IDOR vector).
        - entity_type="student": the student must belong to the current user,
          either as their teacher (teacher_id) or as the linked user account
          (student.user_id == current_user_id).
        """
        if entity_type == "student":
            if not entity_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="entity_id is required for student images",
                )
            if self.db is None:
                raise RuntimeError("Database session is required for ownership check")

            from app.models.student import Student
            from app.models.teacher import Teacher

            student = await self.db.get(Student, entity_id)
            if student is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Student not found",
                )

            if student.user_id == current_user_id:
                return

            teacher_id = await self.db.scalar(select(Teacher.id).where(Teacher.user_id == current_user_id))
            if teacher_id is not None and student.teacher_id == teacher_id:
                return

            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to modify this student's image",
            )

    async def upload(
        self,
        *,
        file: UploadFile,
        image_type: str,
        user_id: str,
        entity_type: str = "teacher",
        entity_id: str | None = None,
    ) -> ProfileImageUploadResponse:
        """Upload a profile or background image to object storage."""
        await self._assert_can_modify_entity(
            current_user_id=user_id,
            entity_type=entity_type,
            entity_id=entity_id,
        )

        if file.content_type not in self.ALLOWED_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported file type: {file.content_type}. Allowed: {self.ALLOWED_TYPES}",
            )

        content = await file.read()
        if len(content) > self.MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File too large. Maximum size: {self.MAX_FILE_SIZE // (1024 * 1024)}MB",
            )

        file_ext = file.filename.rsplit(".", 1)[-1] if file.filename else "jpg"
        target_id = entity_id or user_id
        file_key = f"images/{entity_type}/{image_type}/{target_id}/{uuid.uuid4()}.{file_ext}"

        file_url = await self._upload_to_storage(file_key, content, file.content_type)

        return ProfileImageUploadResponse(
            image_url=file_url,
            image_type=image_type,
            file_key=file_key,
            uploaded_at=datetime.now(UTC),
        )

    async def delete(self, file_key: str) -> None:
        """Delete an image from object storage."""
        await self._delete_from_storage(file_key)

    async def update_profile_image(
        self,
        *,
        current_user_id: str,
        entity_type: str,
        entity_id: str | None,
        image_url: str | None,
    ) -> None:
        """Update profile_image_url in the appropriate table."""
        if self.db is None:
            raise RuntimeError("Database session is required")
        await self._assert_can_modify_entity(
            current_user_id=current_user_id,
            entity_type=entity_type,
            entity_id=entity_id,
        )
        if entity_type == "teacher":
            from app.models.user import User as UserModel

            user = await self.db.get(UserModel, current_user_id)
            if user:
                user.profile_image_url = image_url
                await self.db.flush()
        elif entity_type == "student" and entity_id:
            from app.models.student import Student

            student = await self.db.get(Student, entity_id)
            if student:
                student.profile_image_url = image_url
                await self.db.flush()

    async def update_background_image(
        self,
        *,
        current_user_id: str,
        entity_type: str,
        entity_id: str | None,
        image_url: str | None,
    ) -> None:
        """Update background_image_url in the appropriate table."""
        if self.db is None:
            raise RuntimeError("Database session is required")
        await self._assert_can_modify_entity(
            current_user_id=current_user_id,
            entity_type=entity_type,
            entity_id=entity_id,
        )
        if entity_type == "teacher":
            from app.models.teacher import Teacher

            teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == current_user_id))
            if teacher:
                teacher.background_image = image_url
                await self.db.flush()
        elif entity_type == "student" and entity_id:
            from app.models.student import Student

            student = await self.db.get(Student, entity_id)
            if student:
                student.background_image_url = image_url
                await self.db.flush()

    async def _upload_to_storage(self, file_key: str, content: bytes, content_type: str | None) -> str:
        """Upload to Vultr Object Storage and return URL."""
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
                await s3.put_object(
                    Bucket=settings.VULTR_STORAGE_BUCKET,
                    Key=file_key,
                    Body=content,
                    ContentType=content_type or "image/jpeg",
                    ACL="public-read",
                )
            return f"{settings.VULTR_STORAGE_ENDPOINT}/{settings.VULTR_STORAGE_BUCKET}/{file_key}"
        except ImportError:
            # Development fallback — return a local-style URL
            return f"/storage/{file_key}"
        except Exception:
            # S3 SDK 의 raw 에러 메시지에 인프라 정보가 들어갈 수 있어 응답에 노출하지 않는다.
            import logging

            logging.getLogger(__name__).exception("Profile image upload to object storage failed")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to upload image",
            )

    async def _delete_from_storage(self, file_key: str) -> None:
        """Delete from Vultr Object Storage."""
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
        except ImportError:
            pass
        except Exception:
            pass
