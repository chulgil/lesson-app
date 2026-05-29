"""Public invite landing data endpoint."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.schemas.invite import PublicInviteLandingResponse
from app.services.invite_service import InviteService

router = APIRouter()


@router.get(
    "/public/invites/{code}/landing",
    response_model=PublicInviteLandingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get public invite landing data",
)
async def get_public_invite_landing(
    code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PublicInviteLandingResponse:
    """Return public JSON consumed by the Ghost invite landing page."""
    service = InviteService(db)
    return await service.get_public_invite_landing(code)
