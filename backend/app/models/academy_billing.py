"""Academy billing models — AC-M1 그룹 C 수강료 청구/수금/정산.

Spec: docs/specs/web/academy/billing_settlement_spec.md (전체)
- AcademyBillingRule: 학원 단위 청구·배분 규칙 (1 학원 = 1 행)
- AcademyInvoice: 월간 학생 청구서 (1 학생 × 월 = 1 행)
- AcademyPayment: 수금 1건 (1 수금 거래 = 1 행)
- AcademySettlement: 월간 강사 배분 명세 (1 강사 × 월 = 1 행)
- AcademyTeacherPayoutOverride: 강사별 정산 모드 override (혼합 모드 지원)

Policy:
- 자동 결제/송금 X — 모든 수금/송금은 학원장 수기 마킹
- /payments/* 라우터 신규 금지 (backend_spec §결제 경계 정책)
- AcademySubscription 신규 테이블 만들지 않음 — subscriptions 에 academy_id 추가
- 강사 페이 비율 (절대값 아닌 비율 사용) — billing_settlement §6
"""

from __future__ import annotations

import enum
from datetime import date, datetime

from sqlalchemy import (
    JSON,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815


class TeacherDistributionType(str, enum.Enum):
    """강사 배분 모드 (billing_settlement §6.1)."""

    hourly = "hourly"  # 시간당 단가
    revenue_share = "revenue_share"  # 수강료 % 비율
    per_student = "per_student"  # 학생별 단가


class SubscriptionOwnership(str, enum.Enum):
    """수강권 귀속 (academy_schedule_authority §2.2).

    academy: 학원 귀속 — 정책 결정자는 학원장 (작성 시점 스냅샷)
    teacher: 강사 귀속 — 정책 결정자는 강사
    """

    academy = "academy"
    teacher = "teacher"


class SettlementBase(str, enum.Enum):
    """정산 계산 베이스 (billing_settlement §6.6)."""

    attendance = "attendance"  # 실제 출석 완료된 레슨만
    invoiced = "invoiced"  # 학생 청구액 기준 (출결 무관)
    completed_invoice = "completed_invoice"  # 교집합 (보수적)


class InvoiceStatus(str, enum.Enum):
    """청구서 상태."""

    draft = "draft"
    sent = "sent"
    paid = "paid"
    overdue = "overdue"
    cancelled = "cancelled"


class PaymentMethod(str, enum.Enum):
    """수금 방법."""

    transfer = "transfer"  # 무통장입금
    cash = "cash"
    card = "card"  # 카드 (앱 외부 결제)


class PaymentSource(str, enum.Enum):
    """수금 입력 경로."""

    manual = "manual"  # 1클릭 마킹
    csv_import = "csv_import"  # 은행 CSV 임포트
    fuzzy_match = "fuzzy_match"  # payment_matching_spec fuzzy 매칭 확정


class SettlementStatus(str, enum.Enum):
    """강사 배분 상태."""

    draft = "draft"  # 자동 계산 직후
    confirmed = "confirmed"  # 학원장 확정 + 명세서 발송
    transferred = "transferred"  # 학원장 송금 완료 마킹


class AcademyBillingRule(UUIDMixin, TimestampMixin, Base):
    """학원 단위 청구·배분 규칙 (1 학원 = 1 행). billing_settlement §2."""

    __tablename__ = "academy_billing_rules"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    invoice_issue_day: Mapped[int] = mapped_column(Integer, nullable=False, default=25)
    payment_due_days: Mapped[int] = mapped_column(Integer, nullable=False, default=7)
    payment_methods: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    bank_account_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    bank_account_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    # 학원 단위 기본 배분 모드 (강사별 override 는 AcademyTeacherPayoutOverride).
    teacher_distribution_type: Mapped[TeacherDistributionType] = mapped_column(
        Enum(TeacherDistributionType, native_enum=True),
        nullable=False,
        default=TeacherDistributionType.revenue_share,
    )
    teacher_distribution_config: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    # 정산 베이스 (billing_settlement §6.6).
    settlement_base: Mapped[SettlementBase] = mapped_column(
        Enum(SettlementBase, native_enum=True),
        nullable=False,
        default=SettlementBase.attendance,
    )
    # 세금 발급 정책.
    tax_invoice_enabled: Mapped[bool] = mapped_column("tax_invoice_enabled", Integer, nullable=False, default=0)
    cash_receipt_enabled: Mapped[bool] = mapped_column("cash_receipt_enabled", Integer, nullable=False, default=1)
    # 휴가 페이 정책 (teacher_absence_and_substitute §6.1).
    absent_teacher_pay_pct: Mapped[float] = mapped_column(Float, nullable=False, default=0.4)
    substitute_pay_pct: Mapped[float] = mapped_column(Float, nullable=False, default=0.6)
    # 무단 결근 페널티 (teacher_absence §7.2).
    no_show_penalty_amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    no_show_penalty_strikes: Mapped[int] = mapped_column(Integer, nullable=False, default=3)

    __table_args__ = (
        CheckConstraint("invoice_issue_day BETWEEN 1 AND 28", name="ck_billing_rule_issue_day"),
        CheckConstraint("payment_due_days BETWEEN 0 AND 60", name="ck_billing_rule_due_days"),
        CheckConstraint(
            "absent_teacher_pay_pct >= 0 AND absent_teacher_pay_pct <= 1",
            name="ck_billing_rule_absent_pct",
        ),
        CheckConstraint(
            "substitute_pay_pct >= 0 AND substitute_pay_pct <= 1",
            name="ck_billing_rule_sub_pct",
        ),
    )


class AcademyTeacherPayoutOverride(UUIDMixin, TimestampMixin, Base):
    """강사별 정산 모드 override (billing_settlement §6.5).

    학원 기본값과 다른 강사가 있을 때만 행 생성. 정책 변경 시 새 행 + 이전 행
    effective_until 설정 (히스토리 보존).
    """

    __tablename__ = "academy_teacher_payout_overrides"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    teacher_member_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_members.id", ondelete="CASCADE"),
        nullable=False,
    )
    distribution_type: Mapped[TeacherDistributionType] = mapped_column(
        Enum(TeacherDistributionType, native_enum=True),
        nullable=False,
    )
    distribution_config: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    effective_from: Mapped[date] = mapped_column(Date, nullable=False)
    effective_until: Mapped[date | None] = mapped_column(Date, nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index(
            "idx_payout_override_teacher_effective",
            "teacher_member_id",
            "effective_from",
        ),
        Index("idx_payout_override_academy", "academy_id"),
    )


class AcademyInvoice(UUIDMixin, TimestampMixin, Base):
    """월간 학생 청구서 (1 학생 × 월 = 1 행). billing_settlement §3."""

    __tablename__ = "academy_invoices"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    academy_student_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_students.id", ondelete="CASCADE"),
        nullable=False,
    )
    period_year: Mapped[int] = mapped_column(Integer, nullable=False)
    period_month: Mapped[int] = mapped_column(Integer, nullable=False)
    issued_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    base_amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    extra_amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    discount_amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[InvoiceStatus] = mapped_column(
        Enum(InvoiceStatus, native_enum=True),
        nullable=False,
        default=InvoiceStatus.draft,
    )
    due_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    pdf_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    line_items: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    # 영수증 발급 추적 (billing_settlement §7.3 Year 1 수기 보조).
    tax_invoice_issued: Mapped[bool] = mapped_column("tax_invoice_issued", Integer, nullable=False, default=0)
    cash_receipt_issued: Mapped[bool] = mapped_column("cash_receipt_issued", Integer, nullable=False, default=0)
    cash_receipt_issued_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cash_receipt_ref: Mapped[str | None] = mapped_column(String(100), nullable=True)
    cash_receipt_target_no: Mapped[str | None] = mapped_column(String(50), nullable=True)

    __table_args__ = (
        Index(
            "idx_academy_invoice_unique_period",
            "academy_id",
            "academy_student_id",
            "period_year",
            "period_month",
            unique=True,
        ),
        Index("idx_academy_invoice_academy_status", "academy_id", "status"),
        Index("idx_academy_invoice_due_date", "due_date"),
        CheckConstraint("period_month BETWEEN 1 AND 12", name="ck_invoice_period_month"),
        CheckConstraint("total_amount >= 0", name="ck_invoice_total_amount"),
    )


class AcademyPayment(UUIDMixin, TimestampMixin, Base):
    """수금 1건 (1 청구서 × N 수금 — 부분 수금 지원). billing_settlement §4."""

    __tablename__ = "academy_payments"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    invoice_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_invoices.id", ondelete="CASCADE"),
        nullable=False,
    )
    paid_amount: Mapped[int] = mapped_column(Integer, nullable=False)
    paid_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    method: Mapped[PaymentMethod] = mapped_column(
        Enum(PaymentMethod, native_enum=True),
        nullable=False,
        default=PaymentMethod.transfer,
    )
    confirmed_by_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    source: Mapped[PaymentSource] = mapped_column(
        Enum(PaymentSource, native_enum=True),
        nullable=False,
        default=PaymentSource.manual,
    )
    # 은행 CSV 임포트 시 거래번호 (audit).
    bank_tx_ref: Mapped[str | None] = mapped_column(String(100), nullable=True)
    # 입금자 원문 (fuzzy 매칭 audit, payment_matching_spec).
    depositor_raw: Mapped[str | None] = mapped_column(String(200), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_academy_payment_invoice", "invoice_id"),
        Index("idx_academy_payment_academy_paid_at", "academy_id", "paid_at"),
        CheckConstraint("paid_amount > 0", name="ck_payment_paid_amount"),
    )


class AcademySettlement(UUIDMixin, TimestampMixin, Base):
    """월간 강사 배분 명세 (1 강사 × 월 = 1 행). billing_settlement §6.

    audit trail (billing_settlement §6.7):
    - teacher_acknowledged_at: 강사 확인 시각
    - teacher_dispute_note: 강사 이의 메모
    - adjustment_log: 학원장 수정 이력 (영구 보존)
    """

    __tablename__ = "academy_settlements"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    teacher_member_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_members.id", ondelete="RESTRICT"),
        nullable=False,
    )
    period_year: Mapped[int] = mapped_column(Integer, nullable=False)
    period_month: Mapped[int] = mapped_column(Integer, nullable=False)
    calculated_amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    adjusted_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    final_amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[SettlementStatus] = mapped_column(
        Enum(SettlementStatus, native_enum=True),
        nullable=False,
        default=SettlementStatus.draft,
    )
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    transferred_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    pdf_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # 학생별 기여 내역 (강사 명세서용).
    breakdown: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    # billing_settlement §6.7 audit.
    teacher_acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    teacher_dispute_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    adjustment_log: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index(
            "idx_academy_settlement_unique_period",
            "academy_id",
            "teacher_member_id",
            "period_year",
            "period_month",
            unique=True,
        ),
        Index("idx_academy_settlement_academy_period", "academy_id", "period_year", "period_month"),
        CheckConstraint("period_month BETWEEN 1 AND 12", name="ck_settlement_period_month"),
        CheckConstraint("calculated_amount >= 0", name="ck_settlement_calculated_amount"),
        CheckConstraint("final_amount >= 0", name="ck_settlement_final_amount"),
    )


class AcademySubscription(UUIDMixin, Base):
    """학원 귀속 수강권 정책 (academy_schedule_authority §2.2).

    spec §2.2: "일반 수강권 필드 (sessions_remaining, fee 등)는 기존 subscriptions
    재사용." 본 테이블은 정책 변수 + 학원 컨텍스트만 보유. subscription_id 로
    본체 연결.

    FE: frontend/lib/features/academy/domain/entities/academy_subscription.dart
    와 1:1 매핑.

    작성 시점에 학원/강사 기본 정책을 스냅샷 — 이후 학원 정책 변경 시 기존
    수강권 영향 없음 (계약 시점 기준).
    """

    __tablename__ = "academy_subscriptions"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    subscription_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("subscriptions.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,  # 1 subscription = 1 academy_subscription policy row
    )
    # FE 호환: AcademySubscription.studentId / teacherMemberId.
    # 수강권 본체에도 student_id 가 있지만 빠른 조회 + audit 용 denormalization.
    academy_student_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_students.id", ondelete="RESTRICT"),
        nullable=False,
    )
    teacher_member_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_members.id", ondelete="RESTRICT"),
        nullable=False,
    )
    ownership: Mapped[SubscriptionOwnership] = mapped_column(
        Enum(SubscriptionOwnership, native_enum=True),
        nullable=False,
        default=SubscriptionOwnership.academy,
    )
    # 정책 변수 — 작성 시점 스냅샷. teacher_cancellation_policy_spec §2.3 + §5.5.
    cancellation_deadline_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=12)
    student_compensation_extra_minutes_enabled: Mapped[bool] = mapped_column(
        "student_compensation_extra_minutes_enabled",
        Integer,
        nullable=False,
        default=1,
    )
    include_extra_minutes_text_on_late_cancel: Mapped[bool] = mapped_column(
        "include_extra_minutes_text_on_late_cancel",
        Integer,
        nullable=False,
        default=1,
    )
    student_compensation_extra_minutes_message: Mapped[str | None] = mapped_column(String(500), nullable=True)
    notify_owner_on_late_cancel: Mapped[bool] = mapped_column(
        "notify_owner_on_late_cancel", Integer, nullable=False, default=1
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    created_by_user_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    __table_args__ = (
        Index("idx_academy_subscription_academy", "academy_id"),
        Index("idx_academy_subscription_student", "academy_student_id"),
        Index("idx_academy_subscription_teacher", "teacher_member_id"),
        CheckConstraint(
            "cancellation_deadline_hours >= 0 AND cancellation_deadline_hours <= 168",
            name="ck_academy_subscription_deadline_hours",
        ),
    )


__all__ = [
    "AcademyBillingRule",
    "AcademyInvoice",
    "AcademyPayment",
    "AcademySettlement",
    "AcademySubscription",
    "AcademyTeacherPayoutOverride",
    "InvoiceStatus",
    "PaymentMethod",
    "PaymentSource",
    "SettlementBase",
    "SettlementStatus",
    "SubscriptionOwnership",
    "TeacherDistributionType",
]
