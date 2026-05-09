"""Teacher referral system models."""

import enum
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class ReferralStatus(str, enum.Enum):
    """Status of a teacher referral."""

    PENDING = "pending"
    COMPLETED = "completed"
    REWARDED = "rewarded"
    EXPIRED = "expired"


class TeacherReferral(UUIDMixin, Base):
    """Teacher-to-teacher referral tracking."""

    __tablename__ = "teacher_referrals"

    referrer_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id"), nullable=False)
    referred_teacher_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("teachers.id"), nullable=True
    )
    referral_code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default=ReferralStatus.PENDING)
    reward_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    rewarded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
