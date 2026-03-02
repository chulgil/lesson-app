"""Recording endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.practice import RecordingResponse, RecordingUploadResponse
from app.services.recording_service import RecordingService

router = APIRouter()


@router.post(
    "/upload",
    response_model=RecordingUploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a recording",
)
async def upload_recording(
    file: UploadFile = File(...),
    section_id: str | None = Form(None),
    duration_seconds: int | None = Form(None),
    bpm: int | None = Form(None),
    *,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RecordingUploadResponse:
    """Upload a recording file (m4a, wav, mp3) to object storage."""
    service = RecordingService(db)
    return await service.upload(
        file=file,
        section_id=section_id,
        duration_seconds=duration_seconds,
        bpm=bpm,
        user=current_user,
    )


@router.get(
    "",
    response_model=PaginatedResponse[RecordingResponse],
    status_code=status.HTTP_200_OK,
    summary="List recordings",
)
async def list_recordings(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    section_id: str | None = None,
    student_id: str | None = None,
) -> PaginatedResponse[RecordingResponse]:
    """List recordings with optional filters."""
    service = RecordingService(db)
    return await service.get_all(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        section_id=section_id,
        student_id=student_id,
    )


@router.get(
    "/{recording_id}",
    response_model=RecordingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get recording metadata",
)
async def get_recording(
    recording_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RecordingResponse:
    """Return metadata for a recording."""
    service = RecordingService(db)
    return await service.get_by_id(recording_id, current_user)


@router.get(
    "/{recording_id}/download",
    status_code=status.HTTP_200_OK,
    summary="Get download URL",
)
async def download_recording(
    recording_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Generate a presigned download URL for a recording."""
    service = RecordingService(db)
    return await service.get_download_url(recording_id, current_user)


@router.delete(
    "/{recording_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete recording",
)
async def delete_recording(
    recording_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a recording (file + metadata)."""
    service = RecordingService(db)
    await service.delete(recording_id, current_user)


@router.patch(
    "/{recording_id}/representative",
    response_model=RecordingResponse,
    status_code=status.HTTP_200_OK,
    summary="Set representative recording",
)
async def set_representative(
    recording_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RecordingResponse:
    """Mark this recording as the representative for its section."""
    service = RecordingService(db)
    return await service.set_representative(recording_id, current_user)


@router.post(
    "/{recording_id}/share",
    status_code=status.HTTP_200_OK,
    summary="Generate share link",
)
async def share_recording(
    recording_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Generate a shareable link for a recording."""
    service = RecordingService(db)
    return await service.create_share_link(recording_id, current_user)
