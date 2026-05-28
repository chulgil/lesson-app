"""App billing plan and IAP receipt models."""

import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class BillingTier(str, enum.Enum):
    """App subscription tier."""

    free = "free"
    pro = "pro"
    studio = "studio"


class BillingPlanStatus(str, enum.Enum):
    """Subscription plan status."""

    active = "active"
    trial = "trial"
    expired = "expired"
    cancelled = "cancelled"


class IapPlatform(str, enum.Enum):
    """In-app purchase platform."""

    apple = "apple"
    google = "google"


class IapReceiptStatus(str, enum.Enum):
    """IAP receipt validation status."""

    pending_verification = "pending_verification"
    verified = "verified"
    invalid = "invalid"
    expired = "expired"


class AppBillingPlan(UUIDMixin, TimestampMixin, Base):
    """App usage tier and subscription management.

    Separate from Payment model (legacy tuition). This model tracks
    app feature access (free limit: 5 students, pro limit: unlimited).
    """

    __tablename__ = "app_billing_plans"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    tier: Mapped[BillingTier] = mapped_column(
        Enum(BillingTier, native_enum=True),
        nullable=False,
        default=BillingTier.free,
    )
    status: Mapped[BillingPlanStatus] = mapped_column(
        Enum(BillingPlanStatus, native_enum=True),
        nullable=False,
        default=BillingPlanStatus.active,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    source: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="admin_grant",
    )
    original_transaction_id: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )
    trial_used: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    __table_args__ = (
        Index("uk_app_billing_user", "user_id", unique=True),
        Index("idx_app_billing_expires", "expires_at"),
        Index("idx_app_billing_status", "status"),
    )


class IapReceipt(UUIDMixin, TimestampMixin, Base):
    """In-app purchase receipt validation log.

    Stores raw receipt data for audit trail and handles both
    Apple App Store and Google Play Store receipts.
    """

    __tablename__ = "iap_receipts"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    platform: Mapped[IapPlatform] = mapped_column(
        Enum(IapPlatform, native_enum=True),
        nullable=False,
    )
    raw_receipt: Mapped[str] = mapped_column(Text, nullable=False)
    transaction_id: Mapped[str] = mapped_column(String(255), nullable=False)
    product_id: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[IapReceiptStatus] = mapped_column(
        Enum(IapReceiptStatus, native_enum=True),
        nullable=False,
        default=IapReceiptStatus.pending_verification,
    )
    validated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    __table_args__ = (
        Index("idx_iap_receipt_user", "user_id"),
        Index("idx_iap_receipt_platform", "platform"),
        Index("idx_iap_receipt_transaction", "transaction_id"),
        Index("idx_iap_receipt_status", "status"),
    )
