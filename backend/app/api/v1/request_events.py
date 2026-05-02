"""Request event endpoints — chat history for lesson requests."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.request_event import (
    RequestEventCreate,
    RequestEventResponse,
)
from app.services.request_event_service import RequestEventService

router = APIRouter()


@router.get(
    "",
    response_model=list[RequestEventResponse],
    status_code=status.HTTP_200_OK,
    summary="List events for a lesson request",
)
async def list_request_events(
    request_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[RequestEventResponse]:
    """Return all chat-history events for a lesson request."""
    service = RequestEventService(db)
    return await service.get_events_by_request_id(request_id, current_user)


@router.post(
    "",
    response_model=RequestEventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create an event for a lesson request",
)
async def create_request_event(
    request_id: str,
    body: RequestEventCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RequestEventResponse:
    """Add a new event to a lesson request's chat history."""
    service = RequestEventService(db)
    return await service.create_event(request_id, body, current_user)
