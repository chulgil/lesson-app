"""App billing plan and receipt models for IAP monetization (R4)."""

from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class AppBillingPlan(Base, UUIDMixin, TimestampMixin):
    """Per-teacher app subscription plan (Free/TrialPro/Pro/Studio/Lifetime)."""

    __tablename__ = "app_billing_plans"

    teacher_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("teachers.id"), nullable=False, index=True
    )
    plan: Mapped[str] = mapped_column(
        String(20), nullable=False, default="free"
    )
    store_platform: Mapped[str | None] = mapped_column(
        String(20), nullable=True
    )
    original_transaction_id: Mapped[str | None] = mapped_column(
        String(100), nullable=True
    )
    trial_ends_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )


class AppBillingReceipt(Base, UUIDMixin, TimestampMixin):
    """Store receipt verification history."""

    __tablename__ = "app_billing_receipts"

    billing_plan_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("app_billing_plans.id"), nullable=False, index=True
    )
    store_platform: Mapped[str] = mapped_column(String(20), nullable=False)
    transaction_id: Mapped[str] = mapped_column(String(100), nullable=False)
    product_id: Mapped[str] = mapped_column(String(50), nullable=False)
    receipt_data: Mapped[str] = mapped_column(Text, nullable=False)
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    verification_status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending"
    )
