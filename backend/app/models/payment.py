import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class PaymentType(str, enum.Enum):
    trial = "trial"
    regular = "regular"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    paid = "paid"
    confirmed = "confirmed"
    overdue = "overdue"
    cancelled = "cancelled"
    refunded = "refunded"


class PaymentMethodEnum(str, enum.Enum):
    cash = "cash"
    bankTransfer = "bankTransfer"
    card = "card"
    other = "other"


class BillingTargetType(str, enum.Enum):
    student = "student"
    parent = "parent"


class Payment(UUIDMixin, TimestampMixin, Base):
    """Payment record for lessons."""

    __tablename__ = "payments"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_name: Mapped[str] = mapped_column(String(100), nullable=False)
    type: Mapped[PaymentType] = mapped_column(
        Enum(PaymentType, native_enum=True),
        nullable=False,
        default=PaymentType.regular,
    )
    amount: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, native_enum=True),
        nullable=False,
        default=PaymentStatus.pending,
    )
    method: Mapped[PaymentMethodEnum | None] = mapped_column(
        Enum(PaymentMethodEnum, native_enum=True),
        nullable=True,
    )
    payment_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    due_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    receipt_number: Mapped[str | None] = mapped_column(String(100), nullable=True)
    lesson_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    period_start: Mapped[date | None] = mapped_column(Date, nullable=True)
    period_end: Mapped[date | None] = mapped_column(Date, nullable=True)
    week_start: Mapped[int | None] = mapped_column(Integer, nullable=True)
    week_end: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Student confirmation
    student_confirmed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    student_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    # Billing target
    billing_target_type: Mapped[BillingTargetType] = mapped_column(
        Enum(BillingTargetType, native_enum=True),
        nullable=False,
        default=BillingTargetType.student,
    )
    billing_target_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    billing_target_name: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # Payment tracking
    paid_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    paid_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    confirmed_by: Mapped[str | None] = mapped_column(String(36), nullable=True)

    # Parent notification
    parent_notified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    parent_notified_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    __table_args__ = (
        Index("idx_payment_student", "student_id"),
        Index("idx_payment_status", "status"),
        Index("idx_payment_due_date", "due_date"),
        Index("idx_payment_period", "period_start", "period_end"),
    )


class TuitionSettings(UUIDMixin, TimestampMixin, Base):
    """Per-student tuition configuration."""

    __tablename__ = "tuition_settings"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    monthly_fee: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    lesson_fee: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    is_monthly_billing: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    lessons_per_month: Mapped[int] = mapped_column(Integer, nullable=False, default=4)
    billing_day: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    preferred_method: Mapped[PaymentMethodEnum | None] = mapped_column(
        Enum(PaymentMethodEnum, native_enum=True),
        nullable=True,
    )
    bank_account: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    last_payment_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    next_due_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    default_billing_target: Mapped[BillingTargetType] = mapped_column(
        Enum(BillingTargetType, native_enum=True),
        nullable=False,
        default=BillingTargetType.student,
    )
    default_billing_parent_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    __table_args__ = (
        Index("uk_tuition_student", "student_id", unique=True),
    )
