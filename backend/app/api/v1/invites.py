"""Invite, connection request, and connection endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.invite import (
    ConnectionRequestCreate,
    ConnectionRequestRespondRequest,
    ConnectionRequestResponse,
    ConnectionResponse,
    InviteCreate,
    InviteResponse,
)
from app.services.invite_service import InviteService

router = APIRouter()


# ---------------------------------------------------------------------------
# Invites
# ---------------------------------------------------------------------------


@router.post(
    "/",
    response_model=InviteResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create invite",
)
async def create_invite(
    body: InviteCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> InviteResponse:
    service = InviteService(db)
    return await service.create_invite(
        is_single_use=body.is_single_use,
        max_uses=body.max_uses,
        note=body.note,
        expires_in_hours=body.expires_in_hours,
        current_user=current_user,
    )


@router.get(
    "/",
    response_model=PaginatedResponse[InviteResponse],
    summary="List my invites",
)
async def list_invites(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[InviteResponse]:
    service = InviteService(db)
    return await service.get_invites(
        user_id=current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.patch(
    "/{invite_id}/revoke",
    response_model=InviteResponse,
    summary="Revoke invite",
)
async def revoke_invite(
    invite_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> InviteResponse:
    service = InviteService(db)
    return await service.revoke_invite(invite_id, current_user)


# ---------------------------------------------------------------------------
# Connection Requests
# ---------------------------------------------------------------------------


@router.post(
    "/connection-requests",
    response_model=ConnectionRequestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create connection request",
)
async def create_connection_request(
    body: ConnectionRequestCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ConnectionRequestResponse:
    service = InviteService(db)
    return await service.create_connection_request(
        target_id=body.target_id,
        method=body.method,
        invite_id=body.invite_id,
        invite_code=body.invite_code,
        message=body.message,
        current_user=current_user,
    )


@router.get(
    "/connection-requests/pending",
    response_model=PaginatedResponse[ConnectionRequestResponse],
    summary="List pending connection requests",
)
async def list_pending_requests(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[ConnectionRequestResponse]:
    service = InviteService(db)
    return await service.get_pending_requests(
        user_id=current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.patch(
    "/connection-requests/{request_id}/respond",
    response_model=ConnectionRequestResponse,
    summary="Respond to connection request",
)
async def respond_to_request(
    request_id: str,
    body: ConnectionRequestRespondRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ConnectionRequestResponse:
    service = InviteService(db)
    return await service.respond_to_request(
        request_id, body.action, body.rejection_reason, current_user
    )


# ---------------------------------------------------------------------------
# Connections
# ---------------------------------------------------------------------------


@router.get(
    "/connections",
    response_model=PaginatedResponse[ConnectionResponse],
    summary="List my connections",
)
async def list_connections(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[ConnectionResponse]:
    service = InviteService(db)
    return await service.get_connections(
        user_id=current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.delete(
    "/connections/{connection_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Deactivate connection",
)
async def deactivate_connection(
    connection_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    service = InviteService(db)
    await service.deactivate_connection(connection_id, current_user)
