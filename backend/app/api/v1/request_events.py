"""RequestEvent endpoints — Plan A Phase 1 SSOT for lesson request chat history.

Routes:
  POST  /schedule/lesson-requests/{request_id}/events
  GET   /schedule/lesson-requests/{request_id}/events
  GET   /schedule/request-events/{event_id}
  PATCH /schedule/request-events/{event_id}
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.request_event import (
    RequestEventCreate,
    RequestEventResponse,
    RequestEventUpdate,
)
from app.services.request_event_service import RequestEventService

router = APIRouter()


@router.post(
    "/lesson-requests/{request_id}/events",
    response_model=RequestEventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Append a request event (chat message)",
)
async def create_request_event(
    request_id: str,
    body: RequestEventCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RequestEventResponse:
    """Append a new event to a lesson request's chat history."""
    service = RequestEventService(db)
    return await service.create_event(request_id, body, current_user)


@router.get(
    "/lesson-requests/{request_id}/events",
    response_model=list[RequestEventResponse],
    status_code=status.HTTP_200_OK,
    summary="List request events",
)
async def list_request_events(
    request_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[RequestEventResponse]:
    """List all events of a lesson request (chronological, oldest first)."""
    service = RequestEventService(db)
    return await service.list_events(request_id, current_user)


@router.get(
    "/request-events/{event_id}",
    response_model=RequestEventResponse,
    status_code=status.HTTP_200_OK,
    summary="Get a single request event",
)
async def get_request_event(
    event_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RequestEventResponse:
    """Fetch one event by id (caller must be a participant of its request)."""
    service = RequestEventService(db)
    return await service.get_event(event_id, current_user)


@router.patch(
    "/request-events/{event_id}",
    response_model=RequestEventResponse,
    status_code=status.HTTP_200_OK,
    summary="Partial update of a request event",
)
async def update_request_event(
    event_id: str,
    body: RequestEventUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RequestEventResponse:
    """Update selected_slot_index or message on an event the caller authored."""
    service = RequestEventService(db)
    return await service.update_event(event_id, body, current_user)
