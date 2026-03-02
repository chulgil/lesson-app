"""Recording service – upload, download, share."""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.practice import RecordingResponse, RecordingUploadResponse


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

        query = select(PracticeRecording)
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
        from app.models.practice import PracticeRecording

        rec = await self.db.get(PracticeRecording, recording_id)
        if rec is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")
        return RecordingResponse.model_validate(rec)

    async def get_download_url(self, recording_id: str, current_user: Any) -> dict:
        """Generate a presigned download URL."""
        from app.models.practice import PracticeRecording

        rec = await self.db.get(PracticeRecording, recording_id)
        if rec is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")

        download_url = await self._generate_presigned_url(rec.file_key)
        expires_at = datetime.now(timezone.utc) + timedelta(hours=1)

        return {
            "download_url": download_url,
            "expires_at": expires_at.isoformat(),
        }

    async def delete(self, recording_id: str, current_user: Any) -> None:
        """Delete recording (file + metadata)."""
        from app.models.practice import PracticeRecording

        rec = await self.db.get(PracticeRecording, recording_id)
        if rec is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")

        # Delete from storage
        await self._delete_from_storage(rec.file_key)

        await self.db.delete(rec)
        await self.db.flush()

    async def set_representative(self, recording_id: str, current_user: Any) -> RecordingResponse:
        """Mark a recording as the representative for its section."""
        from app.models.practice import PracticeRecording

        rec = await self.db.get(PracticeRecording, recording_id)
        if rec is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")

        # Unset previous representative for the same section
        if rec.section_id:
            result = await self.db.scalars(
                select(PracticeRecording).where(
                    PracticeRecording.section_id == rec.section_id,
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
        from app.models.practice import PracticeRecording

        rec = await self.db.get(PracticeRecording, recording_id)
        if rec is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")

        share_token = str(uuid.uuid4())
        expires_at = datetime.now(timezone.utc) + timedelta(days=7)

        return {
            "share_url": f"https://api.lessonaza.app/shared/recordings/{share_token}",
            "expires_at": expires_at.isoformat(),
        }

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
                endpoint_url=settings.vultr_storage_endpoint,
                aws_access_key_id=settings.vultr_storage_access_key,
                aws_secret_access_key=settings.vultr_storage_secret_key,
            ) as s3:
                content = await file.read()
                await s3.put_object(
                    Bucket=settings.vultr_storage_bucket,
                    Key=file_key,
                    Body=content,
                    ContentType=file.content_type or "audio/m4a",
                )
            return f"{settings.vultr_storage_endpoint}/{settings.vultr_storage_bucket}/{file_key}"
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
                endpoint_url=settings.vultr_storage_endpoint,
                aws_access_key_id=settings.vultr_storage_access_key,
                aws_secret_access_key=settings.vultr_storage_secret_key,
            ) as s3:
                url = await s3.generate_presigned_url(
                    "get_object",
                    Params={"Bucket": settings.vultr_storage_bucket, "Key": file_key},
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
                endpoint_url=settings.vultr_storage_endpoint,
                aws_access_key_id=settings.vultr_storage_access_key,
                aws_secret_access_key=settings.vultr_storage_secret_key,
            ) as s3:
                await s3.delete_object(
                    Bucket=settings.vultr_storage_bucket,
                    Key=file_key,
                )
        except Exception:
            pass  # Log but don't fail the request
