"""Profile image upload service — Vultr Object Storage."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, UploadFile, status

from app.schemas.profile_image import ProfileImageUploadResponse


class ProfileImageService:
    """Handle profile and background image upload to Vultr Object Storage."""

    ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
    MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

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
            uploaded_at=datetime.now(timezone.utc),
        )

    async def delete(self, file_key: str) -> None:
        """Delete an image from object storage."""
        await self._delete_from_storage(file_key)

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
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to upload image: {e}",
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
