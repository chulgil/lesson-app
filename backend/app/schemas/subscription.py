"""Subscription, template, and proposal schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict, computed_field

# ---------------------------------------------------------------------------
# Subscription
# ---------------------------------------------------------------------------

class SubscriptionResponse(BaseModel):
    """Subscription representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    membership_id: str | None = None
    type: str | None = None
    status: str | None = None
    total_lessons: int | None = None
    used_lessons: int = 0

    @computed_field  # type: ignore[prop-decorator]
    @property
    def remaining_lessons(self) -> int | None:
        if self.total_lessons is None:
            return None
        return self.total_lessons - self.used_lessons

    amount: int | None = None
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    payment_status: str | None = None
    payment_method: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class SubscriptionCreate(BaseModel):
    """Create a subscription."""

    student_id: str
    membership_id: str | None = None
    type: str | None = None
    total_lessons: int | None = None
    amount: int | None = None
    start_date: _dt.date | None = None


class SubscriptionUpdate(BaseModel):
    """Update a subscription."""

    type: str | None = None
    total_lessons: int | None = None
    amount: int | None = None
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    status: str | None = None


class UseLessonRequest(BaseModel):
    """Deduct a lesson from a subscription."""

    lesson_id: str
    type: str = "lesson"


class UseRescheduleRequest(BaseModel):
    """Use a reschedule credit from a subscription."""

    lesson_id: str | None = None


class UpdateStatusRequest(BaseModel):
    """Update subscription status."""

    status: str


class SubscriptionUsageResponse(BaseModel):
    """Subscription usage record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    subscription_id: str
    lesson_id: str | None = None
    type: str | None = None
    created_at: _dt.datetime | None = None


class SubscriptionUsageCreate(BaseModel):
    """Create a subscription usage record."""

    lesson_id: str | None = None
    type: str = "lesson"


class ConfirmPaymentRequest(BaseModel):
    """Confirm payment on a subscription."""

    payment_method: str | None = None


# ---------------------------------------------------------------------------
# Subscription template
# ---------------------------------------------------------------------------

class SubscriptionTemplateResponse(BaseModel):
    """Subscription template (reusable preset)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    name: str
    type: str | None = None
    lessons_count: int | None = None
    amount: int | None = None
    description: str | None = None
    is_active: bool = True
    created_at: _dt.datetime | None = None


class SubscriptionTemplateCreate(BaseModel):
    """Create a template."""

    name: str
    type: str | None = None
    lessons_count: int | None = None
    amount: int | None = None
    description: str | None = None


class SubscriptionTemplateUpdate(BaseModel):
    """Update a template."""

    name: str | None = None
    type: str | None = None
    lessons_count: int | None = None
    amount: int | None = None
    description: str | None = None


# ---------------------------------------------------------------------------
# Subscription proposal
# ---------------------------------------------------------------------------

class SubscriptionProposalResponse(BaseModel):
    """Proposal sent from teacher to student."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    student_id: str
    status: str | None = None
    message: str | None = None
    template_ids: list[str] | None = None
    recommended_template_id: str | None = None
    selected_template_id: str | None = None
    rejection_reason: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class SubscriptionProposalCreate(BaseModel):
    """Create a proposal."""

    student_id: str
    template_id: str | None = None
    message: str | None = None
    template_ids: list[str] = []
    recommended_template_id: str | None = None


class ProposalRespondRequest(BaseModel):
    """Student response to a proposal (accept or reject)."""

    action: str  # "accept" | "reject"
    selected_template_id: str | None = None
    rejection_reason: str | None = None


class ProposalConfirmRequest(BaseModel):
    """Teacher confirms the proposal after payment."""

    pass
