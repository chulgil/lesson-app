"""Subscription, template, and proposal endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import (
    get_current_teacher,
    get_current_user,
    get_db,
    get_pagination,
    require_phone_verified_teacher,
)
from app.models.user import User
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.schemas.request_event import RequestEventCreate, RequestEventResponse
from app.schemas.subscription import (
    ConfirmPaymentRequest,
    NotifyPaymentRequest,
    PendingPaymentCountResponse,
    PendingPaymentResponse,
    ProposalConfirmRequest,
    ProposalRespondRequest,
    SubscriptionCreate,
    SubscriptionDepositSummaryResponse,
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
from app.services.payment_tracking_service import PaymentTrackingService
from app.services.subscription_service import SubscriptionService

router = APIRouter()


class TemplateReorderRequest(BaseModel):
    """Display order update payload from the Flutter template repository."""

    ordered_ids: list[str]


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
    deposit_status: str | None = None,
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
        deposit_status=deposit_status,
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
    current_user: Annotated[User, Depends(require_phone_verified_teacher)],
) -> SubscriptionResponse:
    """Create a new subscription.

    Phone verification (E3 hard gate) is enforced at the dependency layer per
    docs/specs/user/phone_verification_policy.md §4.2 / §5.3. The service still
    re-checks defensively so programmatic callers cannot bypass the gate.
    """
    service = SubscriptionService(db)
    return await service.create(body, current_user)


@router.get(
    "/deposits/summary",
    response_model=SubscriptionDepositSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Summarize manual tuition deposits",
)
async def get_deposit_summary(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    year: int | None = None,
    month: int | None = None,
) -> SubscriptionDepositSummaryResponse:
    """Return manual tuition deposit state summary for visible subscriptions."""
    service = SubscriptionService(db)
    return await service.get_deposit_summary(user=current_user, year=year, month=month)


@router.get(
    "/schedule-change-events/pending",
    response_model=list[RequestEventResponse],
    status_code=status.HTTP_200_OK,
    summary="List pending subscription schedule-change events",
)
async def get_pending_subscription_schedule_change_events(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[RequestEventResponse]:
    """Return latest visible subscription session events that need the user's response."""
    service = SubscriptionService(db)
    return await service.get_pending_schedule_change_events(current_user)


# ---------------------------------------------------------------------------
# Payment-pending dashboard (#424) — must precede `/{subscription_id}` to avoid
# the dynamic route swallowing the static "payment-pending" segment.
# ---------------------------------------------------------------------------


@router.get(
    "/payment-pending/count",
    response_model=PendingPaymentCountResponse,
    status_code=status.HTTP_200_OK,
    summary="Teacher pending-payment count (home card) — #424",
)
async def count_pending_payments(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> PendingPaymentCountResponse:
    service = PaymentTrackingService(db)
    return await service.count_pending(current_user)


@router.get(
    "/payment-pending",
    response_model=PendingPaymentResponse,
    status_code=status.HTTP_200_OK,
    summary="Teacher pending-payment list — #424",
)
async def list_pending_payments(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> PendingPaymentResponse:
    service = PaymentTrackingService(db)
    return await service.list_pending(current_user)


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
    response_model=PaginatedResponse[SubscriptionUsageResponse],
    status_code=status.HTTP_200_OK,
    summary="Get subscription usage history",
)
async def get_usage_history(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> PaginatedResponse[SubscriptionUsageResponse]:
    """Return usage history for a subscription."""
    service = SubscriptionService(db)
    items = await service.get_usage_history(subscription_id, current_user)
    responses = [SubscriptionUsageResponse.model_validate(u) for u in items]
    return PaginatedResponse.create(
        items=responses,
        total=len(responses),
        page=1,
        size=len(responses) or 1,
    )


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


@router.post(
    "/{subscription_id}/undo-confirm",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Undo a payment confirmation (teacher only, 24h window) — #426",
)
async def undo_confirm_payment(
    subscription_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionResponse:
    """Roll back a manual deposit confirmation within 24h, before first lesson is consumed."""
    service = SubscriptionService(db)
    return await service.undo_confirm_payment(subscription_id, current_user)


@router.patch(
    "/{subscription_id}/notify-payment",
    response_model=SubscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Notify external tuition deposit",
)
async def notify_payment(
    subscription_id: str,
    body: NotifyPaymentRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SubscriptionResponse:
    """Record a student or parent external deposit notification."""
    service = SubscriptionService(db)
    return await service.notify_payment(subscription_id, body, current_user)


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


@router.get(
    "-templates/{template_id}",
    response_model=SubscriptionTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Get template detail",
)
async def get_template(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionTemplateResponse:
    """Return one subscription template."""
    service = SubscriptionService(db)
    return await service.get_template_by_id(template_id, current_user)


@router.patch(
    "-templates/reorder",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Reorder templates",
)
async def reorder_templates(
    body: TemplateReorderRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Update template display order."""
    service = SubscriptionService(db)
    await service.reorder_templates(body.ordered_ids, current_user)


@router.patch(
    "-templates/{template_id}/toggle-active",
    response_model=SubscriptionTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Toggle template active",
)
async def toggle_template_active(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionTemplateResponse:
    """Toggle template active state."""
    service = SubscriptionService(db)
    return await service.toggle_template_active(template_id, current_user)


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


@router.get(
    "-proposals/{proposal_id}",
    response_model=SubscriptionProposalResponse,
    status_code=status.HTTP_200_OK,
    summary="Get proposal detail",
)
async def get_proposal(
    proposal_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SubscriptionProposalResponse:
    """Return one subscription proposal."""
    service = SubscriptionService(db)
    return await service.get_proposal_by_id(proposal_id, current_user)


@router.post(
    "-proposals/expire",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Expire old proposals",
)
async def expire_old_proposals(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SuccessResponse:
    """Mark stale proposals as expired."""
    service = SubscriptionService(db)
    count = await service.expire_old_proposals()
    return SuccessResponse(message=f"Processed {count} expired proposals")


@router.post(
    "-proposals/{proposal_id}/resend",
    status_code=status.HTTP_200_OK,
    summary="Resend payment reminder to student (teacher only, 30-min cooldown) — #424",
)
async def resend_proposal_reminder(
    proposal_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> dict:
    service = PaymentTrackingService(db)
    return await service.resend(proposal_id, current_user)


@router.post(
    "-proposals/{proposal_id}/revoke",
    response_model=SubscriptionProposalResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke a pending proposal (teacher only) — #424",
)
async def revoke_proposal(
    proposal_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionProposalResponse:
    service = PaymentTrackingService(db)
    return await service.revoke(proposal_id, current_user)


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
    current_user: Annotated[User, Depends(require_phone_verified_teacher)],
) -> SubscriptionProposalResponse:
    """Confirm a proposal after payment verification.

    Phone verification (E3 hard gate) is enforced at the dependency layer per
    docs/specs/user/phone_verification_policy.md §4.2 / §5.3. The service still
    re-checks defensively so programmatic callers cannot bypass the gate.
    """
    service = SubscriptionService(db)
    return await service.confirm_proposal(proposal_id, current_user)
