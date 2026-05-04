"""Subscription, template, and proposal schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict, computed_field, field_validator

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
    lessons_per_month: int | None = None
    bonus_count: int = 0
    billing_type: str | None = None
    billing_day: int | None = None
    fifth_week_policy: str | None = None
    bonus_reason: str | None = None
    total_reschedule_allowance: int = 2
    used_reschedule_count: int = 0
    payment_confirmed: bool = True
    payment_status: str | None = None
    payment_method: str | None = None
    paid_at: _dt.datetime | None = None
    payment_confirmed_at: _dt.datetime | None = None
    discount_amount: int | None = None
    discount_reason: str | None = None
    original_amount: int | None = None
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
    payment_confirmed: bool = True
    payment_method: str | None = None

    @field_validator("payment_method")
    @classmethod
    def validate_current_payment_method(cls, value: str | None) -> str | None:
        if value == "card":
            raise ValueError("card/PG payments are not supported for current tuition deposits")
        return value


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
    used_at: _dt.datetime | None = None
    teacher_name: str | None = None
    instrument: str | None = None
    note: str | None = None
    deducted: bool = True
    created_at: _dt.datetime | None = None


class SubscriptionUsageCreate(BaseModel):
    """Create a subscription usage record."""

    lesson_id: str | None = None
    type: str = "lesson"
    note: str | None = None
    deducted: bool = True


class ConfirmPaymentRequest(BaseModel):
    """Confirm a manual tuition deposit on a subscription."""

    payment_method: str | None = None

    @field_validator("payment_method")
    @classmethod
    def validate_current_payment_method(cls, value: str | None) -> str | None:
        if value == "card":
            raise ValueError("card/PG payments are not supported for current tuition deposits")
        return value


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
    lessons_per_month: int | None = None
    duration_months: int | None = None
    lesson_duration_minutes: int = 60
    validity_days: int | None = None
    amount: int | None = None
    description: str | None = None
    display_order: int = 0
    reschedule_allowance: int = 2
    is_active: bool = True
    is_auto_proposal_enabled: bool = False
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class SubscriptionTemplateCreate(BaseModel):
    """Create a template."""

    name: str
    type: str | None = None
    lessons_count: int | None = None
    lessons_per_month: int | None = None
    duration_months: int | None = None
    lesson_duration_minutes: int = 60
    validity_days: int | None = None
    amount: int | None = None
    description: str | None = None
    display_order: int = 0
    reschedule_allowance: int = 2
    is_auto_proposal_enabled: bool = False


class SubscriptionTemplateUpdate(BaseModel):
    """Update a template."""

    name: str | None = None
    type: str | None = None
    lessons_count: int | None = None
    lessons_per_month: int | None = None
    duration_months: int | None = None
    lesson_duration_minutes: int | None = None
    validity_days: int | None = None
    amount: int | None = None
    description: str | None = None
    display_order: int | None = None
    reschedule_allowance: int | None = None
    is_auto_proposal_enabled: bool | None = None


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
    lesson_request_id: str | None = None
    payment_status: str | None = None
    payment_notified_at: _dt.datetime | None = None
    confirmed_at: _dt.datetime | None = None
    subscription_id: str | None = None
    rejection_reason: str | None = None
    proposal_type: str = "proposal"
    is_renewal: bool = False
    previous_subscription_id: str | None = None
    renewal_initiator: str | None = None
    is_auto_proposal: bool = False
    is_app_transition: bool = False
    discount_amount: int | None = None
    discount_reason: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class SubscriptionProposalCreate(BaseModel):
    """Create a proposal."""

    student_id: str
    template_id: str | None = None
    message: str | None = None
    template_ids: list[str] = []
    recommended_template_id: str | None = None
    lesson_request_id: str | None = None


class ProposalRespondRequest(BaseModel):
    """Student response to a proposal (accept or reject)."""

    action: str  # "notify_payment" | "accept" | "reject"
    selected_template_id: str | None = None
    rejection_reason: str | None = None


class ProposalConfirmRequest(BaseModel):
    """Teacher confirms the proposal after payment."""

    pass
