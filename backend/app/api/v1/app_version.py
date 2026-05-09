"""Public app version, news, and roadmap endpoint (R6 trust-building)."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Header, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.schemas.app_version import AppVersionResponse
from app.services.app_version_service import AppVersionService

router = APIRouter()


@router.get(
    "",
    response_model=AppVersionResponse,
    status_code=status.HTTP_200_OK,
)
async def get_app_version(
    db: Annotated[AsyncSession, Depends(get_db)],
    x_app_platform: Annotated[str | None, Header()] = "ios",
) -> AppVersionResponse:
    """Return latest/min version, news, and roadmap. No auth required."""
    service = AppVersionService(db)
    return await service.get_app_version(x_app_platform)
