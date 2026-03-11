import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, Index, Integer, JSON, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


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

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    membership_id: Mapped[str] = mapped_column(String(36), nullable=False)
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

    # Payment
    payment_confirmed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    payment_method: Mapped[PaymentMethod | None] = mapped_column(
        Enum(PaymentMethod, native_enum=True),
        nullable=True,
    )
    paid_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    payment_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    # Discount
    discount_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    discount_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    original_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)

    __table_args__ = (
        Index("idx_sub_student", "student_id"),
        Index("idx_sub_membership", "membership_id"),
        Index("idx_sub_status", "status"),
        Index("idx_sub_end_date", "end_date"),
    )


class SubscriptionUsage(UUIDMixin, Base):
    """Record of subscription usage (lesson deduction, etc.)."""

    __tablename__ = "subscription_usages"

    subscription_id: Mapped[str] = mapped_column(String(36), nullable=False)
    lesson_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    used_at: Mapped[datetime] = mapped_column(
        DateTime,
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

    __table_args__ = (
        Index("idx_usage_subscription", "subscription_id"),
        Index("idx_usage_date", "used_at"),
    )


class SubscriptionTemplate(UUIDMixin, TimestampMixin, Base):
    """Reusable subscription template created by a teacher."""

    __tablename__ = "subscription_templates"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    type: Mapped[SubscriptionType] = mapped_column(
        Enum(SubscriptionType, native_enum=True),
        nullable=False,
    )
    lessons_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    lessons_per_month: Mapped[int | None] = mapped_column(Integer, nullable=True)
    duration_months: Mapped[int | None] = mapped_column(Integer, nullable=True)
    amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_template_teacher", "teacher_id"),
    )


class SubscriptionProposal(UUIDMixin, Base):
    """Subscription proposal from teacher to student."""

    __tablename__ = "subscription_proposals"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    template_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
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
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    payment_notified_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    rejected_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    subscription_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    academy_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    discount_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    discount_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    template_ids: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    recommended_template_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    selected_template_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    is_auto_proposal: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_app_transition: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    lesson_request_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_proposal_teacher", "teacher_id"),
        Index("idx_proposal_student", "student_id"),
        Index("idx_proposal_status", "status"),
        Index("idx_proposal_expires", "expires_at"),
    )
