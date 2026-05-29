"""Public lesson summary sharing endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.share import PublicLessonSummaryResponse
from app.services.share_token_service import ShareTokenService

router = APIRouter()


@router.get(
    "/public/student-summaries/{token}",
    response_model=PublicLessonSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get public lesson summary by share token",
)
async def get_public_student_summary(
    token: Annotated[str, Path(..., description="Opaque share token")],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PublicLessonSummaryResponse:
    """Return a token-gated, read-only public lesson summary."""
    service = ShareTokenService(db)
    return await service.get_public_lesson_summary(token)
