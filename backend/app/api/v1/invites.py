"""Invite, connection request, and connection endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
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
    result: InviteResponse = await service.create_invite(
        is_single_use=body.is_single_use,
        max_uses=body.max_uses,
        note=body.note,
        expires_in_hours=body.expires_in_hours,
        target_role=body.target_role,
        current_user=current_user,
    )
    return result


@router.get(
    "/",
    response_model=PaginatedResponse[InviteResponse],
    status_code=status.HTTP_200_OK,
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


@router.get(
    "/code/{invite_code}",
    response_model=InviteResponse,
    status_code=status.HTTP_200_OK,
    summary="Get invite by code",
)
async def get_invite_by_code(
    invite_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> InviteResponse:
    service = InviteService(db)
    result: InviteResponse = await service.get_invite_by_code(invite_code, current_user)
    return result


@router.patch(
    "/{invite_id}/revoke",
    response_model=InviteResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke invite",
)
async def revoke_invite(
    invite_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> InviteResponse:
    service = InviteService(db)
    result: InviteResponse = await service.revoke_invite(invite_id, current_user)
    return result


# ---------------------------------------------------------------------------
# G3 (#5 D-G3) — Resend invite + pending list
# `/pending` must precede the dynamic `/{invite_id}` GET further down the file
# to avoid it being swallowed as an invite_id.
# ---------------------------------------------------------------------------


@router.get(
    "/pending",
    status_code=status.HTTP_200_OK,
    summary="List the current creator's outstanding invites — #5 D-G3",
)
async def list_pending_invites(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    service = InviteService(db)
    return await service.list_pending_invites(current_user)


@router.post(
    "/{invite_id}/resend",
    response_model=InviteResponse,
    status_code=status.HTTP_200_OK,
    summary="Resend invite — extend expiry, resurrect if expired — #5 D-G3",
)
async def resend_invite(
    invite_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> InviteResponse:
    service = InviteService(db)
    result: InviteResponse = await service.resend_invite(invite_id, current_user)
    return result


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
    result: ConnectionRequestResponse = await service.create_connection_request(
        target_id=body.target_id,
        method=body.method,
        invite_id=body.invite_id,
        invite_code=body.invite_code,
        message=body.message,
        current_user=current_user,
    )
    return result


@router.get(
    "/connection-requests/sent",
    response_model=PaginatedResponse[ConnectionRequestResponse],
    status_code=status.HTTP_200_OK,
    summary="List sent connection requests",
)
async def list_sent_requests(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[ConnectionRequestResponse]:
    service = InviteService(db)
    return await service.get_sent_requests(
        user_id=current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.get(
    "/connection-requests/pending",
    response_model=PaginatedResponse[ConnectionRequestResponse],
    status_code=status.HTTP_200_OK,
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
    status_code=status.HTTP_200_OK,
    summary="Respond to connection request",
)
async def respond_to_request(
    request_id: str,
    body: ConnectionRequestRespondRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ConnectionRequestResponse:
    service = InviteService(db)
    result: ConnectionRequestResponse = await service.respond_to_request(
        request_id, body.action, body.rejection_reason, current_user
    )
    return result


@router.patch(
    "/connection-requests/{request_id}/cancel",
    response_model=ConnectionRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel a sent connection request",
)
async def cancel_request(
    request_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ConnectionRequestResponse:
    service = InviteService(db)
    result: ConnectionRequestResponse = await service.cancel_request(request_id, current_user)
    return result


# ---------------------------------------------------------------------------
# Connections
# ---------------------------------------------------------------------------


@router.get(
    "/connections",
    response_model=PaginatedResponse[ConnectionResponse],
    status_code=status.HTTP_200_OK,
    summary="List my connections",
)
async def list_connections(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    include_inactive: bool = Query(False),
) -> PaginatedResponse[ConnectionResponse]:
    service = InviteService(db)
    return await service.get_connections(
        user_id=current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        include_inactive=include_inactive,
    )


@router.patch(
    "/connections/{connection_id}/reactivate",
    response_model=ConnectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Reactivate connection",
)
async def reactivate_connection(
    connection_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ConnectionResponse:
    service = InviteService(db)
    result: ConnectionResponse = await service.reactivate_connection(connection_id, current_user)
    return result


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


@router.get(
    "/{invite_id}",
    response_model=InviteResponse,
    status_code=status.HTTP_200_OK,
    summary="Get invite by ID",
)
async def get_invite(
    invite_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> InviteResponse:
    service = InviteService(db)
    result: InviteResponse = await service.get_invite(invite_id, current_user)
    return result
