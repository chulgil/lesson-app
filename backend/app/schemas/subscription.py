"""Subscription, template, and proposal schemas."""

import datetime as _dt

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, computed_field, field_validator, model_validator

# ---------------------------------------------------------------------------
# Subscription
# ---------------------------------------------------------------------------


class SubscriptionResponse(BaseModel):
    """Subscription representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    membership_id: str | None = None
    # Instrument inherited from the subscription's membership (SSOT for the
    # lesson instrument). Empty membership instrument is mapped to null so the
    # frontend falls back to the student value. spec §2.5.
    instrument: str | None = None
    lesson_location_id: str | None = None
    travel_time_minutes: int | None = None
    type: str | None = None
    status: str | None = None

    total_lessons: int | None = None
    used_lessons: int = 0

    @computed_field  # type: ignore[prop-decorator]
    @property
    def remaining_lessons(self) -> int | None:
        if self.type == "trial":
            return 1 + self.bonus_count - self.used_lessons
        base = self.total_lessons
        if base is None and self.type == "monthly":
            base = self.lessons_per_month
        if base is None:
            return None
        return base + self.bonus_count - self.used_lessons

    amount: int | None = None
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    # Vacation-extended actual expiry (end_date + auto_extended_days).
    # Exposed so the frontend can show the correct expiration date without
    # recomputing auto_extended_days client-side.
    effective_end_date: _dt.date | None = None
    auto_extended_days: int = 0
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
    reschedule_deadline_hours: int = 12
    # spec subscription_edit_spec.md §7.1 — 추가 변경권 / 개별 취소 기준시간 / 장소.
    bonus_reschedule_count: int = 0
    override_cancel_deadline_hours: int | None = None
    lesson_location_type: str | None = None
    lesson_location_id: str | None = None
    travel_time_minutes: int | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


def _camel_alias(field_name: str) -> str:
    return "".join(word.capitalize() if index else word for index, word in enumerate(field_name.split("_")))


class SubscriptionDepositSummaryResponse(BaseModel):
    """Manual tuition deposit summary derived from Subscription payment state."""

    model_config = ConfigDict(populate_by_name=True, alias_generator=_camel_alias)

    year: int | None = None
    month: int | None = None
    total_count: int = 0
    total_amount: int = 0
    student_count: int = 0
    unpaid_count: int = 0
    unpaid_amount: int = 0
    needs_confirmation_count: int = 0
    needs_confirmation_amount: int = 0
    confirmed_count: int = 0
    confirmed_amount: int = 0


class SubscriptionCreate(BaseModel):
    """Create a subscription."""

    student_id: str
    membership_id: str | None = None
    type: str | None = None
    status: str | None = None
    total_lessons: int | None = None
    used_lessons: int = 0
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
    payment_method: str | None = None
    paid_at: _dt.datetime | None = None
    payment_confirmed_at: _dt.datetime | None = None
    discount_amount: int | None = None
    discount_reason: str | None = None
    original_amount: int | None = None
    reschedule_deadline_hours: int = 12

    @field_validator("payment_method")
    @classmethod
    def validate_current_payment_method(cls, value: str | None) -> str | None:
        if value == "card":
            raise ValueError("card/PG payments are not supported for current tuition deposits")
        return value

    @model_validator(mode="after")
    def validate_business_invariants(self) -> "SubscriptionCreate":
        _validate_subscription_counter_state(
            subscription_type=self.type,
            total_lessons=self.total_lessons,
            lessons_per_month=self.lessons_per_month,
            bonus_count=self.bonus_count,
            used_lessons=self.used_lessons,
            total_reschedule_allowance=self.total_reschedule_allowance,
            used_reschedule_count=self.used_reschedule_count,
        )
        _validate_manual_deposit_state(
            payment_confirmed=self.payment_confirmed,
            payment_confirmed_at=self.payment_confirmed_at,
        )
        return self


class SubscriptionUpdate(BaseModel):
    """Update a subscription."""

    type: str | None = None
    total_lessons: int | None = None
    used_lessons: int | None = None
    amount: int | None = None
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    status: str | None = None
    lessons_per_month: int | None = None
    bonus_count: int | None = None
    billing_type: str | None = None
    billing_day: int | None = None
    fifth_week_policy: str | None = None
    bonus_reason: str | None = None
    total_reschedule_allowance: int | None = None
    used_reschedule_count: int | None = None
    payment_confirmed: bool | None = None
    payment_method: str | None = None
    paid_at: _dt.datetime | None = None
    payment_confirmed_at: _dt.datetime | None = None
    discount_amount: int | None = None
    discount_reason: str | None = None
    original_amount: int | None = None
    reschedule_deadline_hours: int | None = None

    @field_validator("payment_method")
    @classmethod
    def validate_current_payment_method(cls, value: str | None) -> str | None:
        if value == "card":
            raise ValueError("card/PG payments are not supported for current tuition deposits")
        return value

    @model_validator(mode="after")
    def validate_partial_deposit_state(self) -> "SubscriptionUpdate":
        if self.payment_confirmed is False and self.payment_confirmed_at is not None:
            raise ValueError("payment_confirmed_at is not allowed when payment_confirmed is false")
        return self


def _effective_lesson_capacity(
    *,
    subscription_type: str | None,
    total_lessons: int | None,
    lessons_per_month: int | None,
    bonus_count: int,
) -> int | None:
    if subscription_type == "trial":
        return 1 + bonus_count
    base = total_lessons if total_lessons is not None else lessons_per_month
    if base is None:
        return None
    return base + bonus_count


def _validate_subscription_counter_state(
    *,
    subscription_type: str | None,
    total_lessons: int | None,
    lessons_per_month: int | None,
    bonus_count: int,
    used_lessons: int,
    total_reschedule_allowance: int,
    used_reschedule_count: int,
) -> None:
    counters = {
        "total_lessons": total_lessons,
        "lessons_per_month": lessons_per_month,
        "bonus_count": bonus_count,
        "used_lessons": used_lessons,
        "total_reschedule_allowance": total_reschedule_allowance,
        "used_reschedule_count": used_reschedule_count,
    }
    for field_name, value in counters.items():
        if value is not None and value < 0:
            raise ValueError(f"{field_name} must be greater than or equal to 0")

    lesson_capacity = _effective_lesson_capacity(
        subscription_type=subscription_type,
        total_lessons=total_lessons,
        lessons_per_month=lessons_per_month,
        bonus_count=bonus_count,
    )
    if lesson_capacity is not None and used_lessons > lesson_capacity:
        raise ValueError("used_lessons must not exceed effective lesson capacity")
    if used_reschedule_count > total_reschedule_allowance:
        raise ValueError("used_reschedule_count must not exceed total_reschedule_allowance")


def _validate_manual_deposit_state(
    *,
    payment_confirmed: bool,
    payment_confirmed_at: _dt.datetime | None,
) -> None:
    if not payment_confirmed and payment_confirmed_at is not None:
        raise ValueError("payment_confirmed_at is not allowed when payment_confirmed is false")


class UseLessonRequest(BaseModel):
    """Deduct a lesson from a subscription."""

    lesson_id: str
    type: str = "lesson"
    teacher_name: str | None = None
    instrument: str | None = None
    note: str | None = None
    deducted: bool = True


class UseRescheduleRequest(BaseModel):
    """Use a reschedule credit from a subscription."""

    lesson_id: str | None = None


# spec makeup_credit_spec.md §8.2 — 일괄변경 요청/응답.
class SubscriptionBulkChangeRequest(BaseModel):
    """새 요일/시간으로 미래 미체결 레슨 모두 재배치."""

    new_day_of_week: int  # 0=Mon ... 6=Sun
    new_time: str  # HH:MM


class SubscriptionBulkChangeResponse(BaseModel):
    """spec §8.2 응답 — 처리 결과 요약."""

    rescheduled_count: int
    lost_count: int
    credits_accrued: int
    new_expires_at: _dt.date | None = None


# spec subscription_edit_spec.md §6.1 — 4 가지 PATCH endpoint 요청 스키마.
class RescheduleCreditsPatchRequest(BaseModel):
    """수강권 변경권 추가."""

    additional_count: int
    reason: str | None = None


class LessonLocationPatchRequest(BaseModel):
    """수강권 레슨 장소 변경."""

    location_type: str
    location_id: str | None = None
    travel_time_minutes: int | None = None


class TravelTimePatchRequest(BaseModel):
    """수강권 이동시간 단독 수정."""

    travel_time_minutes: int


class CancelDeadlinePatchRequest(BaseModel):
    """수강권 개별 취소 기준시간 수정 (null = 기본 정책 복귀)."""

    override_cancel_deadline_hours: int | None = None


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
    usage_type: str | None = None
    used_at: _dt.datetime | None = None
    teacher_name: str | None = None
    instrument: str | None = None
    note: str | None = None
    deducted: bool = True
    created_at: _dt.datetime | None = None

    @model_validator(mode="after")
    def fill_frontend_compat_fields(self) -> "SubscriptionUsageResponse":
        type_to_usage_type = {
            "lesson": "normal",
            "cancellationPenalty": "lateCancellation",
            "noShow": "studentAbsent",
            "reschedule": "rescheduled",
        }
        if self.usage_type is None and self.type is not None:
            self.usage_type = type_to_usage_type.get(self.type, self.type)
        if self.created_at is None:
            self.created_at = self.used_at
        return self


class SubscriptionUsageCreate(BaseModel):
    """Create a subscription usage record."""

    lesson_id: str | None = None
    type: str | None = None
    usage_type: str | None = None
    teacher_name: str | None = None
    instrument: str | None = None
    note: str | None = None
    deducted: bool = True

    @model_validator(mode="after")
    def normalize_usage_type(self) -> "SubscriptionUsageCreate":
        usage_type_to_type = {
            "normal": "lesson",
            "lateCancellation": "cancellationPenalty",
            "studentAbsent": "noShow",
            "rescheduled": "reschedule",
        }
        if self.type is None:
            self.type = usage_type_to_type.get(self.usage_type or "normal", self.usage_type or "lesson")
        return self


class ConfirmPaymentRequest(BaseModel):
    """Confirm a manual tuition deposit on a subscription."""

    payment_method: str | None = None

    @field_validator("payment_method")
    @classmethod
    def validate_current_payment_method(cls, value: str | None) -> str | None:
        if value == "card":
            raise ValueError("card/PG payments are not supported for current tuition deposits")
        return value


class NotifyPaymentRequest(BaseModel):
    """Notify that an external tuition deposit was made."""

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
    owner_id: str | None = None
    owner_type: str = "teacher"
    name: str
    type: str | None = None
    lessons_count: int | None = None
    total_lessons: int | None = None
    lessons_per_month: int | None = None
    duration_months: int | None = None
    lesson_duration_minutes: int = 60
    validity_days: int | None = None
    amount: int | None = None
    price: int | None = None
    description: str | None = None
    display_order: int = 0
    reschedule_allowance: int = 2
    is_active: bool = True
    is_auto_proposal_enabled: bool = False
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None

    @model_validator(mode="after")
    def fill_frontend_aliases(self) -> "SubscriptionTemplateResponse":
        self.owner_id = self.owner_id or self.teacher_id
        self.total_lessons = self.total_lessons if self.total_lessons is not None else self.lessons_count
        self.price = self.price if self.price is not None else self.amount
        return self


class SubscriptionTemplateCreate(BaseModel):
    """Create a template."""

    model_config = ConfigDict(populate_by_name=True)

    owner_id: str | None = None
    owner_type: str = "teacher"
    name: str
    type: str | None = None
    lessons_count: int | None = Field(
        default=None,
        validation_alias=AliasChoices("lessons_count", "total_lessons"),
    )
    lessons_per_month: int | None = None
    duration_months: int | None = None
    lesson_duration_minutes: int = 60
    validity_days: int | None = None
    amount: int | None = Field(
        default=None,
        validation_alias=AliasChoices("amount", "price"),
    )
    description: str | None = None
    display_order: int = 0
    reschedule_allowance: int = 2
    is_auto_proposal_enabled: bool = False


class SubscriptionTemplateUpdate(BaseModel):
    """Update a template."""

    model_config = ConfigDict(populate_by_name=True)

    owner_id: str | None = None
    owner_type: str | None = None
    name: str | None = None
    type: str | None = None
    lessons_count: int | None = Field(
        default=None,
        validation_alias=AliasChoices("lessons_count", "total_lessons"),
    )
    lessons_per_month: int | None = None
    duration_months: int | None = None
    lesson_duration_minutes: int | None = None
    validity_days: int | None = None
    amount: int | None = Field(
        default=None,
        validation_alias=AliasChoices("amount", "price"),
    )
    description: str | None = None
    display_order: int | None = None
    reschedule_allowance: int | None = None
    is_auto_proposal_enabled: bool | None = None


# ---------------------------------------------------------------------------
# Subscription proposal
# ---------------------------------------------------------------------------


class PendingPaymentRow(BaseModel):
    """One row of the teacher's pending-payment dashboard — #424."""

    model_config = ConfigDict(from_attributes=True)

    proposal_id: str
    student_id: str
    student_name: str
    amount: int
    lesson_count: int | None = None
    days_since_sent: int
    expires_at: _dt.datetime
    last_reminder_sent_at: _dt.datetime | None = None
    can_resend: bool
    status: str  # pending | paymentNotified


class PendingPaymentResponse(BaseModel):
    """Teacher's pending-payment list — #424."""

    pending: list[PendingPaymentRow]
    total_count: int


class PendingPaymentCountResponse(BaseModel):
    """Lightweight count for the home card — #424."""

    count: int


class SubscriptionProposalResponse(BaseModel):
    """Proposal sent from teacher to student."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    student_id: str
    template_id: str | None = None
    status: str | None = None
    message: str | None = None
    template_ids: list[str] | None = None
    recommended_template_id: str | None = None
    selected_template_id: str | None = None
    lesson_request_id: str | None = None
    payment_status: str | None = None
    expires_at: _dt.datetime | None = None
    payment_notified_at: _dt.datetime | None = None
    confirmed_at: _dt.datetime | None = None
    rejected_at: _dt.datetime | None = None
    subscription_id: str | None = None
    rejection_reason: str | None = None
    academy_id: str | None = None
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
    academy_id: str | None = None
    discount_amount: int | None = None
    discount_reason: str | None = None
    proposal_type: str = "proposal"
    is_renewal: bool = False
    previous_subscription_id: str | None = None
    renewal_initiator: str | None = None
    is_auto_proposal: bool = False
    is_app_transition: bool = False


class ProposalRespondRequest(BaseModel):
    """Student response to a proposal (accept or reject)."""

    action: str  # "notify_payment" | "accept" | "reject" | "select_template" | "cancel"
    selected_template_id: str | None = None
    template_id: str | None = None
    rejection_reason: str | None = None
    reason: str | None = None

    @model_validator(mode="after")
    def normalize_frontend_aliases(self) -> "ProposalRespondRequest":
        """Accept frontend aliases from RemoteSubscriptionProposalRepository."""
        if self.template_id and not self.selected_template_id:
            self.selected_template_id = self.template_id
        if self.reason and not self.rejection_reason:
            self.rejection_reason = self.reason
        return self


class ProposalConfirmRequest(BaseModel):
    """Teacher confirms the proposal after payment.

    FE 가 특정 기존 subscription 에 link 하려는 경우 subscription_id 명시.
    명시되면 BE 가 ownership 검증 후 proposal 에 link (새로 mint 하지 않음).
    """

    subscription_id: str | None = None
