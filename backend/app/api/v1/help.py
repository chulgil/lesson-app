"""Help manual endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import get_current_user
from app.schemas.help import HelpFaqResponse, HelpRole
from app.services.help_service import HelpService

router = APIRouter()


@router.get(
    "/faqs",
    response_model=list[HelpFaqResponse],
    status_code=status.HTTP_200_OK,
)
async def list_help_faqs(
    _current_user: Annotated[object, Depends(get_current_user)],
    role: Annotated[HelpRole, Query()],
    query: Annotated[str | None, Query()] = None,
) -> list[HelpFaqResponse]:
    service = HelpService()
    return service.list_faqs(role=role, query=query)
