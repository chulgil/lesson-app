"""Subscription refund request endpoints — issue #1271."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.refund_request import (
    RefundRequestCompleteRequest,
    RefundRequestCreate,
    RefundRequestRejectRequest,
    RefundRequestResponse,
)
from app.services.refund_request_service import RefundRequestService

router = APIRouter()


@router.post(
    "",
    response_model=RefundRequestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a subscription refund request (student)",
)
async def create_refund_request(
    body: RefundRequestCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RefundRequestResponse:
    """Student submits bank account details to request a subscription refund."""
    service = RefundRequestService(db)
    return await service.create(body, current_user)


@router.get(
    "",
    response_model=list[RefundRequestResponse],
    status_code=status.HTTP_200_OK,
    summary="List refund requests visible to the current user",
)
async def list_refund_requests(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[RefundRequestResponse]:
    """Return refund requests scoped to the caller's role (teacher/student)."""
    service = RefundRequestService(db)
    return await service.list_for_user(current_user)


@router.patch(
    "/{refund_request_id}/complete",
    response_model=RefundRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark a refund request completed (teacher only)",
)
async def complete_refund_request(
    refund_request_id: str,
    body: RefundRequestCompleteRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RefundRequestResponse:
    """Teacher confirms the external bank transfer was completed."""
    service = RefundRequestService(db)
    return await service.complete(refund_request_id, body, current_user)


@router.patch(
    "/{refund_request_id}/reject",
    response_model=RefundRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Reject a refund request (teacher only)",
)
async def reject_refund_request(
    refund_request_id: str,
    body: RefundRequestRejectRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RefundRequestResponse:
    """Teacher rejects a refund request with a reason."""
    service = RefundRequestService(db)
    return await service.reject(refund_request_id, body, current_user)
