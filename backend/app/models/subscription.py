import enum
from datetime import date, datetime

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815, UP042


class SubscriptionType(str, enum.Enum):
    trial = "trial"
    monthly = "monthly"
    package = "package"


class SubscriptionStatus(str, enum.Enum):
    active = "active"
    expiringSoon = "expiringSoon"
    expired = "expired"
    paused = "paused"


class BillingType(str, enum.Enum):
    perPackage = "perPackage"
    monthly = "monthly"


class FifthWeekPolicy(str, enum.Enum):
    skip = "skip"
    bonus = "bonus"
    deduct = "deduct"
    optional = "optional"


class PaymentMethod(str, enum.Enum):
    cash = "cash"
    bankTransfer = "bankTransfer"
    card = "card"
    other = "other"


class UsageType(str, enum.Enum):
    lesson = "lesson"
    noShow = "noShow"
    cancellationPenalty = "cancellationPenalty"
    reschedule = "reschedule"
    bonus = "bonus"
    manual = "manual"


class ProposalStatus(str, enum.Enum):
    pending = "pending"
    paymentNotified = "paymentNotified"
    confirmed = "confirmed"
    rejected = "rejected"
    expired = "expired"
    cancelled = "cancelled"


class ProposalPaymentStatus(str, enum.Enum):
    pending = "pending"
    completed = "completed"


class Subscription(UUIDMixin, TimestampMixin, Base):
    """Lesson subscription / package."""

    __tablename__ = "subscriptions"

    student_id: Mapped[str] = mapped_column(String(36), ForeignKey("students.id"), nullable=False)
    membership_id: Mapped[str] = mapped_column(String(36), ForeignKey("class_memberships.id"), nullable=False)
    type: Mapped[SubscriptionType] = mapped_column(
        Enum(SubscriptionType, native_enum=True),
        nullable=False,
    )
    total_lessons: Mapped[int | None] = mapped_column(Integer, nullable=True)
    used_lessons: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[SubscriptionStatus] = mapped_column(
        Enum(SubscriptionStatus, native_enum=True),
        nullable=False,
        default=SubscriptionStatus.active,
    )
    lessons_per_month: Mapped[int | None] = mapped_column(Integer, nullable=True)
    bonus_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    billing_type: Mapped[BillingType | None] = mapped_column(
        Enum(BillingType, native_enum=True),
        nullable=True,
    )
    billing_day: Mapped[int | None] = mapped_column(Integer, nullable=True)
    fifth_week_policy: Mapped[FifthWeekPolicy | None] = mapped_column(
        Enum(FifthWeekPolicy, native_enum=True),
        nullable=True,
    )
    bonus_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    total_reschedule_allowance: Mapped[int] = mapped_column(Integer, nullable=False, default=2)
    used_reschedule_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    reschedule_deadline_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=12)

    # Payment
    payment_confirmed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    payment_method: Mapped[PaymentMethod | None] = mapped_column(
        Enum(PaymentMethod, native_enum=True),
        nullable=True,
    )
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    payment_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # 첫 레슨 차감 시각. Undo 차단 기준 — None 일 때만 입금 확인 되돌리기 가능 (#426)
    first_lesson_consumed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    # 휴가 모드 자동 연장 누적 일수 (#431). 만료일 계산 시 end_date + auto_extended_days.
    # Spec: docs/specs/subscription/subscription_master.md §2.2.3,
    #       docs/specs/schedule/teacher_vacation_mode.md §5.3.
    auto_extended_days: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    @property
    def payment_status(self) -> str:
        """Current tuition deposit status for API responses."""
        if self.payment_confirmed:
            return "completed"
        if self.paid_at is not None:
            return "needsConfirmation"
        return "pending"

    @property
    def effective_end_date(self) -> date | None:
        """End date including vacation auto-extension days (#431).

        Spec: docs/specs/schedule/teacher_vacation_mode.md §5.3.
        Returns None if end_date is None (open-ended subscription).
        """
        from datetime import timedelta

        if self.end_date is None:
            return None
        if self.auto_extended_days <= 0:
            return self.end_date
        return self.end_date + timedelta(days=self.auto_extended_days)

    # Discount
    discount_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    discount_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    original_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)

    __table_args__ = (
        CheckConstraint(
            "used_lessons >= 0 AND bonus_count >= 0 AND total_reschedule_allowance >= 0 AND used_reschedule_count >= 0",
            name="ck_subscriptions_non_negative_counters",
        ),
        CheckConstraint(
            "((type = 'trial' AND used_lessons <= 1 + bonus_count) "
            "OR (type != 'trial' AND total_lessons IS NOT NULL AND used_lessons <= total_lessons + bonus_count) "
            "OR (type != 'trial' AND total_lessons IS NULL AND lessons_per_month IS NOT NULL "
            "AND used_lessons <= lessons_per_month + bonus_count) "
            "OR (type != 'trial' AND total_lessons IS NULL AND lessons_per_month IS NULL))",
            name="ck_subscriptions_lesson_counter_capacity",
        ),
        CheckConstraint(
            "used_reschedule_count <= total_reschedule_allowance",
            name="ck_subscriptions_reschedule_counter_capacity",
        ),
        Index("idx_sub_student", "student_id"),
        Index("idx_sub_membership", "membership_id"),
        Index("idx_sub_status", "status"),
        Index("idx_sub_end_date", "end_date"),
    )


class SubscriptionUsage(UUIDMixin, Base):
    """Record of subscription usage (lesson deduction, etc.)."""

    __tablename__ = "subscription_usages"

    subscription_id: Mapped[str] = mapped_column(String(36), ForeignKey("subscriptions.id"), nullable=False)
    lesson_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    used_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    teacher_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
    type: Mapped[UsageType] = mapped_column(
        Enum(UsageType, native_enum=True),
        nullable=False,
        default=UsageType.lesson,
    )
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    deducted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_usage_subscription", "subscription_id"),
        Index("idx_usage_date", "used_at"),
    )


class SubscriptionTemplate(UUIDMixin, TimestampMixin, Base):
    """Reusable subscription template created by a teacher."""

    __tablename__ = "subscription_templates"

    teacher_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    type: Mapped[SubscriptionType] = mapped_column(
        Enum(SubscriptionType, native_enum=True),
        nullable=False,
    )
    lessons_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    lessons_per_month: Mapped[int | None] = mapped_column(Integer, nullable=True)
    duration_months: Mapped[int | None] = mapped_column(Integer, nullable=True)
    lesson_duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    validity_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    display_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    reschedule_allowance: Mapped[int] = mapped_column(Integer, nullable=False, default=2)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_auto_proposal_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    __table_args__ = (Index("idx_template_teacher", "teacher_id"),)


class SubscriptionProposal(UUIDMixin, Base):
    """Subscription proposal from teacher to student."""

    __tablename__ = "subscription_proposals"

    teacher_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id"), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), ForeignKey("students.id"), nullable=False)
    template_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("subscription_templates.id"), nullable=True)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[ProposalStatus] = mapped_column(
        Enum(ProposalStatus, native_enum=True),
        nullable=False,
        default=ProposalStatus.pending,
    )
    payment_status: Mapped[ProposalPaymentStatus] = mapped_column(
        Enum(ProposalPaymentStatus, native_enum=True),
        nullable=False,
        default=ProposalPaymentStatus.pending,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    payment_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    rejected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    subscription_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("subscriptions.id"), nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    academy_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    discount_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    discount_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    template_ids: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    recommended_template_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("subscription_templates.id"), nullable=True
    )
    selected_template_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("subscription_templates.id"), nullable=True
    )
    is_auto_proposal: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_app_transition: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    lesson_request_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    proposal_type: Mapped[str] = mapped_column(String(20), nullable=False, default="proposal")
    is_renewal: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    previous_subscription_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("subscriptions.id"), nullable=True
    )
    renewal_initiator: Mapped[str | None] = mapped_column(String(20), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_proposal_teacher", "teacher_id"),
        Index("idx_proposal_student", "student_id"),
        Index("idx_proposal_status", "status"),
        Index("idx_proposal_expires", "expires_at"),
    )
