from typing import Any

import aioboto3

from app.core.config import settings


class VultrStorageService:
    """Async client for Vultr Object Storage (S3-compatible)."""

    def __init__(self) -> None:
        self._session = aioboto3.Session()

    def _get_client_kwargs(self) -> dict[str, Any]:
        """Return common kwargs for creating S3 client."""
        return {
            "service_name": "s3",
            "endpoint_url": settings.VULTR_STORAGE_ENDPOINT,
            "aws_access_key_id": settings.VULTR_STORAGE_ACCESS_KEY,
            "aws_secret_access_key": settings.VULTR_STORAGE_SECRET_KEY,
            "region_name": "sgp1",
        }

    async def upload_file(
        self,
        file_data: bytes,
        key: str,
        content_type: str = "application/octet-stream",
        bucket: str | None = None,
    ) -> str:
        """Upload file bytes to object storage. Returns the object key."""
        bucket = bucket or settings.VULTR_STORAGE_BUCKET
        async with self._session.client(**self._get_client_kwargs()) as s3:
            await s3.put_object(
                Bucket=bucket,
                Key=key,
                Body=file_data,
                ContentType=content_type,
            )
        return key

    async def download_file(self, key: str, bucket: str | None = None) -> bytes:
        """Download file from object storage. Returns file bytes."""
        bucket = bucket or settings.VULTR_STORAGE_BUCKET
        async with self._session.client(**self._get_client_kwargs()) as s3:
            response = await s3.get_object(Bucket=bucket, Key=key)
            data: bytes = await response["Body"].read()
        return data

    async def delete_file(self, key: str, bucket: str | None = None) -> None:
        """Delete a file from object storage."""
        bucket = bucket or settings.VULTR_STORAGE_BUCKET
        async with self._session.client(**self._get_client_kwargs()) as s3:
            await s3.delete_object(Bucket=bucket, Key=key)

    async def generate_presigned_url(
        self,
        key: str,
        expires_in: int = 3600,
        bucket: str | None = None,
    ) -> str:
        """Generate a presigned URL for temporary access to a file."""
        bucket = bucket or settings.VULTR_STORAGE_BUCKET
        async with self._session.client(**self._get_client_kwargs()) as s3:
            url: str = await s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": bucket, "Key": key},
                ExpiresIn=expires_in,
            )
        return url
