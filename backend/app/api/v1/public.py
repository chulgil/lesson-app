"""Public read-only endpoints consumed by Ghost web pages."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.schemas.public_landing import PublicInviteLandingResponse, PublicStudentSummaryResponse
from app.services.public_landing_service import PublicLandingService

router = APIRouter()


@router.get(
    "/invites/{invite_code}/landing",
    response_model=PublicInviteLandingResponse,
    status_code=status.HTTP_200_OK,
    operation_id="get_public_invite_landing",
)
async def get_public_invite_landing(
    invite_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PublicInviteLandingResponse:
    service = PublicLandingService(db)
    return await service.get_invite_landing(invite_code)


@router.get(
    "/student-summaries/{token}",
    response_model=PublicStudentSummaryResponse,
    status_code=status.HTTP_200_OK,
    operation_id="get_public_student_summary",
)
async def get_public_student_summary(
    token: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PublicStudentSummaryResponse:
    service = PublicLandingService(db)
    return await service.get_student_summary(token)
