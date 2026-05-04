"""Subscription, template, and proposal endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.request_event import RequestEventCreate, RequestEventResponse
from app.schemas.subscription import (
    ConfirmPaymentRequest,
    ProposalConfirmRequest,
    ProposalRespondRequest,
    SubscriptionCreate,
    SubscriptionProposalCreate,
    SubscriptionProposalResponse,
    SubscriptionResponse,
    SubscriptionTemplateCreate,
    SubscriptionTemplateResponse,
    SubscriptionTemplateUpdate,
    SubscriptionUpdate,
    SubscriptionUsageCreate,
    SubscriptionUsageResponse,
    UpdateStatusRequest,
    UseLessonRequest,
)
from app.services.subscription_service import SubscriptionService

router = APIRouter()


# ---------------------------------------------------------------------------
# Subscriptions
# ---------------------------------------------------------------------------


@router.get(
    "",
    response_model=PaginatedResponse[SubscriptionResponse],
    status_code=status.HTTP_200_OK,
    summary="List subscriptions",
)
async def list_subscriptions(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    student_id: str | None = None,
    membership_id: str | None = None,
    teacher_id: str | None = None,
    payment_confirmed: str | None = None,
    sub_status: Annotated[str | None, Query(alias="status")] = None,
) -> PaginatedResponse[SubscriptionResponse]:
    """List subscriptions with optional filters."""
    service = SubscriptionService(db)
    return await service.get_all(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        student_id=student_id,
        membership_id=membership_id,
        teacher_id=teacher_id,
        payment_confirmed=payment_confirmed,
        status=sub_status,
    )


@router.post(
    "",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create subscription (teacher only)",
)
async def create_subscription(
    body: SubscriptionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionResponse:
    """Create a new subscription."""
    service = SubscriptionService(db)
    return await service.create(body, current_user)


@router.get(
    "/{subscription_id}",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Get subscription detail",
)
async def get_subscription(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SubscriptionResponse:
    """Return a subscription with usage history."""
    service = SubscriptionService(db)
    return await service.get_by_id(subscription_id, current_user)


@router.put(
    "/{subscription_id}",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Update subscription (teacher only)",
)
async def update_subscription(
    subscription_id: str,
    body: SubscriptionUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionResponse:
    """Update subscription fields."""
    service = SubscriptionService(db)
    return await service.update(subscription_id, body, current_user)


@router.patch(
    "/{subscription_id}/use-lesson",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Deduct a lesson (teacher only)",
)
async def use_lesson(
    subscription_id: str,
    body: UseLessonRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionResponse:
    """Deduct one lesson from the subscription."""
    service = SubscriptionService(db)
    return await service.deduct_lesson(subscription_id, body, current_user)


@router.patch(
    "/{subscription_id}/use-reschedule",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Use a reschedule credit (teacher only)",
)
async def use_reschedule(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionResponse:
    """Use a reschedule credit from the subscription."""
    service = SubscriptionService(db)
    return await service.use_reschedule(subscription_id, current_user)


@router.patch(
    "/{subscription_id}/status",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Update subscription status (teacher only)",
)
async def update_subscription_status(
    subscription_id: str,
    body: UpdateStatusRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionResponse:
    """Update the status of a subscription."""
    service = SubscriptionService(db)
    return await service.update_status(subscription_id, body.status, current_user)


@router.get(
    "/{subscription_id}/usage",
    response_model=list[SubscriptionUsageResponse],
    status_code=status.HTTP_200_OK,
    summary="Get subscription usage history",
)
async def get_usage_history(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[SubscriptionUsageResponse]:
    """Return usage history for a subscription."""
    service = SubscriptionService(db)
    items = await service.get_usage_history(subscription_id, current_user)
    return [SubscriptionUsageResponse.model_validate(u) for u in items]


@router.post(
    "/{subscription_id}/usage",
    response_model=SubscriptionUsageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add usage record (teacher only)",
)
async def add_usage(
    subscription_id: str,
    body: SubscriptionUsageCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionUsageResponse:
    """Add a usage record to a subscription."""
    service = SubscriptionService(db)
    usage = await service.add_usage(subscription_id, body.model_dump(), current_user)
    return SubscriptionUsageResponse.model_validate(usage)


@router.get(
    "/{subscription_id}/events",
    response_model=list[RequestEventResponse],
    status_code=status.HTTP_200_OK,
    summary="Get subscription schedule-change chat history",
)
async def get_subscription_events(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    session_number: int | None = None,
) -> list[RequestEventResponse]:
    """Return subscription event history, optionally scoped to one session."""
    service = SubscriptionService(db)
    return await service.get_events(
        subscription_id,
        current_user,
        session_number=session_number,
    )


@router.post(
    "/{subscription_id}/events",
    response_model=RequestEventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create subscription schedule-change chat event",
)
async def create_subscription_event(
    subscription_id: str,
    body: RequestEventCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RequestEventResponse:
    """Create a schedule-change or message event for a subscription."""
    service = SubscriptionService(db)
    return await service.add_event(subscription_id, body, current_user)


@router.post(
    "/{subscription_id}/renew",
    response_model=SubscriptionProposalResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create renewal proposal (teacher only)",
)
async def create_renewal_proposal(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionProposalResponse:
    """Create a renewal proposal linked to the expiring/expired subscription."""
    service = SubscriptionService(db)
    return await service.create_renewal_proposal(subscription_id, current_user)


@router.patch(
    "/{subscription_id}/confirm-payment",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirm payment (teacher only)",
)
async def confirm_payment(
    subscription_id: str,
    body: ConfirmPaymentRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionResponse:
    """Mark a subscription as paid."""
    service = SubscriptionService(db)
    return await service.confirm_payment(subscription_id, body, current_user)


# ---------------------------------------------------------------------------
# Templates
# ---------------------------------------------------------------------------


@router.get(
    "-templates",
    response_model=list[SubscriptionTemplateResponse],
    status_code=status.HTTP_200_OK,
    summary="List subscription templates",
)
async def list_templates(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> list[SubscriptionTemplateResponse]:
    """List all active subscription templates for the teacher."""
    service = SubscriptionService(db)
    return await service.get_all_templates(current_user)


@router.post(
    "-templates",
    response_model=SubscriptionTemplateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create template (teacher only)",
)
async def create_template(
    body: SubscriptionTemplateCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionTemplateResponse:
    """Create a reusable subscription template."""
    service = SubscriptionService(db)
    return await service.create_template(body, current_user)


@router.put(
    "-templates/{template_id}",
    response_model=SubscriptionTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Update template",
)
async def update_template(
    template_id: str,
    body: SubscriptionTemplateUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionTemplateResponse:
    """Update a subscription template."""
    service = SubscriptionService(db)
    return await service.update_template(template_id, body, current_user)


@router.delete(
    "-templates/{template_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Deactivate template",
)
async def delete_template(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Deactivate a subscription template."""
    service = SubscriptionService(db)
    await service.deactivate_template(template_id, current_user)


# ---------------------------------------------------------------------------
# Proposals
# ---------------------------------------------------------------------------


@router.get(
    "-proposals",
    response_model=PaginatedResponse[SubscriptionProposalResponse],
    status_code=status.HTTP_200_OK,
    summary="List proposals",
)
async def list_proposals(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    student_id: str | None = None,
    proposal_status: Annotated[str | None, Query(alias="status")] = None,
) -> PaginatedResponse[SubscriptionProposalResponse]:
    """List subscription proposals."""
    service = SubscriptionService(db)
    return await service.get_all_proposals(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        student_id=student_id,
        status=proposal_status,
    )


@router.post(
    "-proposals",
    response_model=SubscriptionProposalResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create proposal (teacher only)",
)
async def create_proposal(
    body: SubscriptionProposalCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionProposalResponse:
    """Send a subscription proposal to a student."""
    service = SubscriptionService(db)
    return await service.create_proposal(body, current_user)


@router.patch(
    "-proposals/{proposal_id}/respond",
    response_model=SubscriptionProposalResponse,
    status_code=status.HTTP_200_OK,
    summary="Respond to proposal (student)",
)
async def respond_to_proposal(
    proposal_id: str,
    body: ProposalRespondRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SubscriptionProposalResponse:
    """Accept or reject a subscription proposal."""
    service = SubscriptionService(db)
    return await service.respond_to_proposal(proposal_id, body, current_user)


@router.patch(
    "-proposals/{proposal_id}/confirm",
    response_model=SubscriptionProposalResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirm proposal (teacher)",
)
async def confirm_proposal(
    proposal_id: str,
    body: ProposalConfirmRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionProposalResponse:
    """Confirm a proposal after payment verification."""
    service = SubscriptionService(db)
    return await service.confirm_proposal(proposal_id, current_user)
