"""Academy billing API schemas — AC-M1 그룹 C.

Spec: docs/specs/web/academy/billing_settlement_spec.md.
"""

from __future__ import annotations

import datetime as _dt
import enum

from pydantic import BaseModel, ConfigDict, Field


class TeacherDistributionType(str, enum.Enum):
    hourly = "hourly"
    revenue_share = "revenue_share"
    per_student = "per_student"


class SubscriptionOwnership(str, enum.Enum):
    academy = "academy"
    teacher = "teacher"


class SettlementBase(str, enum.Enum):
    attendance = "attendance"
    invoiced = "invoiced"
    completed_invoice = "completed_invoice"


class InvoiceStatus(str, enum.Enum):
    draft = "draft"
    sent = "sent"
    paid = "paid"
    overdue = "overdue"
    cancelled = "cancelled"


class PaymentMethod(str, enum.Enum):
    transfer = "transfer"
    cash = "cash"
    card = "card"


class PaymentSource(str, enum.Enum):
    manual = "manual"
    csv_import = "csv_import"
    fuzzy_match = "fuzzy_match"


class SettlementStatus(str, enum.Enum):
    draft = "draft"
    confirmed = "confirmed"
    transferred = "transferred"


# ---------------------------------------------------------------------------
# BillingRule
# ---------------------------------------------------------------------------


class AcademyBillingRuleCreate(BaseModel):
    """학원 단위 청구·배분 규칙 등록 (학원 생성 직후 1회)."""

    invoice_issue_day: int = Field(default=25, ge=1, le=28)
    payment_due_days: int = Field(default=7, ge=0, le=60)
    payment_methods: list[str] = Field(default_factory=lambda: ["transfer", "cash"])
    bank_account_name: str | None = None
    bank_account_number: str | None = None
    teacher_distribution_type: TeacherDistributionType = TeacherDistributionType.revenue_share
    teacher_distribution_config: dict = Field(default_factory=dict)
    settlement_base: SettlementBase = SettlementBase.attendance
    tax_invoice_enabled: bool = False
    cash_receipt_enabled: bool = True
    absent_teacher_pay_pct: float = Field(default=0.4, ge=0.0, le=1.0)
    substitute_pay_pct: float = Field(default=0.6, ge=0.0, le=1.0)
    no_show_penalty_amount: int = Field(default=0, ge=0)
    no_show_penalty_strikes: int = Field(default=3, ge=1, le=10)


class AcademyBillingRuleUpdate(BaseModel):
    invoice_issue_day: int | None = Field(default=None, ge=1, le=28)
    payment_due_days: int | None = Field(default=None, ge=0, le=60)
    payment_methods: list[str] | None = None
    bank_account_name: str | None = None
    bank_account_number: str | None = None
    teacher_distribution_type: TeacherDistributionType | None = None
    teacher_distribution_config: dict | None = None
    settlement_base: SettlementBase | None = None
    tax_invoice_enabled: bool | None = None
    cash_receipt_enabled: bool | None = None
    absent_teacher_pay_pct: float | None = Field(default=None, ge=0.0, le=1.0)
    substitute_pay_pct: float | None = Field(default=None, ge=0.0, le=1.0)
    no_show_penalty_amount: int | None = Field(default=None, ge=0)
    no_show_penalty_strikes: int | None = Field(default=None, ge=1, le=10)


class AcademyBillingRuleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    invoice_issue_day: int
    payment_due_days: int
    payment_methods: list[str]
    bank_account_name: str | None = None
    bank_account_number: str | None = None
    teacher_distribution_type: TeacherDistributionType
    teacher_distribution_config: dict
    settlement_base: SettlementBase
    tax_invoice_enabled: bool
    cash_receipt_enabled: bool
    absent_teacher_pay_pct: float
    substitute_pay_pct: float
    no_show_penalty_amount: int
    no_show_penalty_strikes: int
    created_at: _dt.datetime
    updated_at: _dt.datetime


# ---------------------------------------------------------------------------
# TeacherPayoutOverride
# ---------------------------------------------------------------------------


class AcademyTeacherPayoutOverrideCreate(BaseModel):
    teacher_member_id: str
    distribution_type: TeacherDistributionType
    distribution_config: dict = Field(default_factory=dict)
    effective_from: _dt.date
    note: str | None = None


class AcademyTeacherPayoutOverrideResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    teacher_member_id: str
    distribution_type: TeacherDistributionType
    distribution_config: dict
    effective_from: _dt.date
    effective_until: _dt.date | None = None
    note: str | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime


# ---------------------------------------------------------------------------
# Invoice
# ---------------------------------------------------------------------------


class AcademyInvoiceLineItem(BaseModel):
    """청구서 line item — line_items JSON 의 1개 행."""

    date: _dt.date | None = None
    type: str  # lesson / extra / discount
    description: str | None = None
    amount: int


class AcademyInvoiceCreate(BaseModel):
    """수기 청구서 생성. 자동 cron 도 같은 schema 사용."""

    academy_student_id: str
    period_year: int = Field(ge=2020, le=2100)
    period_month: int = Field(ge=1, le=12)
    base_amount: int = Field(ge=0)
    extra_amount: int = Field(default=0, ge=0)
    discount_amount: int = Field(default=0, ge=0)
    line_items: list[AcademyInvoiceLineItem] = Field(default_factory=list)
    due_date: _dt.date | None = None


class AcademyInvoiceUpdate(BaseModel):
    """학원장이 발송 전 수정 가능."""

    base_amount: int | None = Field(default=None, ge=0)
    extra_amount: int | None = Field(default=None, ge=0)
    discount_amount: int | None = Field(default=None, ge=0)
    line_items: list[AcademyInvoiceLineItem] | None = None
    due_date: _dt.date | None = None


class AcademyInvoiceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    academy_student_id: str
    period_year: int
    period_month: int
    issued_at: _dt.datetime | None = None
    sent_at: _dt.datetime | None = None
    base_amount: int
    extra_amount: int
    discount_amount: int
    total_amount: int
    status: InvoiceStatus
    due_date: _dt.date | None = None
    pdf_url: str | None = None
    line_items: list[AcademyInvoiceLineItem] = []
    tax_invoice_issued: bool
    cash_receipt_issued: bool
    cash_receipt_issued_at: _dt.datetime | None = None
    cash_receipt_ref: str | None = None
    cash_receipt_target_no: str | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime


class AcademyInvoiceListResponse(BaseModel):
    invoices: list[AcademyInvoiceResponse] = []
    total_count: int


class AcademyInvoiceBulkSendRequest(BaseModel):
    """UX: 한 달 청구서 전체 발송 1탭."""

    invoice_ids: list[str] = Field(min_length=1)


# ---------------------------------------------------------------------------
# Payment
# ---------------------------------------------------------------------------


class AcademyPaymentCreate(BaseModel):
    invoice_id: str
    paid_amount: int = Field(gt=0)
    paid_at: _dt.datetime
    method: PaymentMethod = PaymentMethod.transfer
    source: PaymentSource = PaymentSource.manual
    bank_tx_ref: str | None = None
    depositor_raw: str | None = None
    note: str | None = None


class AcademyPaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    invoice_id: str
    paid_amount: int
    paid_at: _dt.datetime
    method: PaymentMethod
    confirmed_by_user_id: str
    source: PaymentSource
    bank_tx_ref: str | None = None
    depositor_raw: str | None = None
    note: str | None = None
    created_at: _dt.datetime


class AcademyPaymentListResponse(BaseModel):
    payments: list[AcademyPaymentResponse] = []
    total_count: int


# ---------------------------------------------------------------------------
# Settlement
# ---------------------------------------------------------------------------


class SettlementBreakdownItem(BaseModel):
    """강사 명세서의 학생별 기여 내역."""

    academy_student_id: str
    student_name: str
    lesson_count: int
    amount: int


class AcademySettlementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    teacher_member_id: str
    period_year: int
    period_month: int
    calculated_amount: int
    adjusted_amount: int | None = None
    final_amount: int
    status: SettlementStatus
    confirmed_at: _dt.datetime | None = None
    transferred_at: _dt.datetime | None = None
    pdf_url: str | None = None
    breakdown: list[SettlementBreakdownItem] = []
    teacher_acknowledged_at: _dt.datetime | None = None
    teacher_dispute_note: str | None = None
    adjustment_log: list[dict] = []
    note: str | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime


class AcademySettlementListResponse(BaseModel):
    settlements: list[AcademySettlementResponse] = []
    total_count: int


class AcademySettlementAdjustRequest(BaseModel):
    """학원장이 강사 정산 금액 수정 (audit trail)."""

    final_amount: int = Field(ge=0)
    reason: str | None = None


class AcademySettlementTransferRequest(BaseModel):
    """학원장이 외부 송금 후 '송금 완료' 마킹."""

    note: str | None = None


class AcademySettlementAcknowledgeRequest(BaseModel):
    """강사가 정산서를 확인/이의 제기.

    dispute_note 는 자유 텍스트 (민감 가능성) 이므로 query 가 아닌 body 로 받는다.
    """

    dispute_note: str | None = Field(default=None, max_length=2000)


# ---------------------------------------------------------------------------
# Billing Progress (대시보드 위젯)
# ---------------------------------------------------------------------------


class BillingProgressResponse(BaseModel):
    """이번 달 청구→수금→정산 진행률 (대시보드 §3.3)."""

    period_year: int
    period_month: int
    invoice_total: int  # active 학생 수
    invoice_sent: int
    invoice_paid: int
    invoice_overdue: int
    payment_collected_pct: float  # paid / sent
    settlement_status: str  # not_started / partial / completed


# ---------------------------------------------------------------------------
# AcademySubscription — 학원 귀속 수강권 정책 (FE 1:1 매핑)
# ---------------------------------------------------------------------------


class AcademySubscriptionCreate(BaseModel):
    """학원 귀속 수강권 정책 행 생성. subscriptions 본체는 기존 흐름으로 별도 생성."""

    subscription_id: str
    academy_student_id: str
    teacher_member_id: str
    ownership: SubscriptionOwnership = SubscriptionOwnership.academy
    cancellation_deadline_hours: int = Field(default=12, ge=0, le=168)
    student_compensation_extra_minutes_enabled: bool = True
    include_extra_minutes_text_on_late_cancel: bool = True
    student_compensation_extra_minutes_message: str | None = Field(default=None, max_length=500)
    notify_owner_on_late_cancel: bool = True


class AcademySubscriptionResponse(BaseModel):
    """FE `AcademySubscription` (frontend academy_subscription.dart) 와 1:1 매핑."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    subscription_id: str
    academy_student_id: str
    teacher_member_id: str
    ownership: SubscriptionOwnership
    cancellation_deadline_hours: int
    student_compensation_extra_minutes_enabled: bool
    include_extra_minutes_text_on_late_cancel: bool
    student_compensation_extra_minutes_message: str | None = None
    notify_owner_on_late_cancel: bool
    created_at: _dt.datetime
    created_by_user_id: str | None = None


class AcademySubscriptionListResponse(BaseModel):
    subscriptions: list[AcademySubscriptionResponse] = []
    total_count: int
