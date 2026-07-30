"""Public child growth-report preview endpoint (#1217, no auth — minor-safe)."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.share import PublicGrowthReportResponse
from app.services.share_token_service import ShareTokenService

router = APIRouter()


@router.get(
    "/public/growth-reports/{token}",
    response_model=PublicGrowthReportResponse,
    status_code=status.HTTP_200_OK,
    summary="Get public child growth report by share token",
)
async def get_public_growth_report(
    token: Annotated[str, Path(..., description="Opaque share token")],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PublicGrowthReportResponse:
    """Return a token-gated, read-only, minor-safe public child growth report."""
    service = ShareTokenService(db)
    return await service.get_public_growth_report(token)
