"""Makeup Credit (Make-up Bank) — #432 G3.

Spec: docs/specs/subscription/makeup_credit_spec.md
- Separate entity from Subscription. Tracks earned/used/expired credits.
- 4 accrual sources: teacherVacation / noShowExempt / bulkChangeLoss / manualGrant
- 30-day default expiry (createdAt + 30d)

Note: spec §3.1 lists reason names (teacherVacation, noShowExempt, bulkChangeLoss,
manualGrant). Task brief uses synonyms (vacation/no_show_exempt/bulk_change_loss/
fifth_week_bonus). We follow the **spec** as SSOT and add fifthWeekBonus too,
since spec §10 mentions 5주차 bonus and the task brief includes it.
"""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815, UP042


class MakeupCreditReason(str, enum.Enum):
    """Source of credit accrual.

    Spec §3.1 — 4 canonical reasons + fifthWeekBonus (task brief #432).
    """

    teacherVacation = "teacherVacation"
    noShowExempt = "noShowExempt"
    bulkChangeLoss = "bulkChangeLoss"
    manualGrant = "manualGrant"
    fifthWeekBonus = "fifthWeekBonus"


class MakeupCredit(UUIDMixin, TimestampMixin, Base):
    """One earned credit. Becomes 'used' when a future lesson consumes it.

    Lifecycle:
        active (created) → used (usedAt != null) | expired (expiresAt < now AND usedAt is null)
    """

    __tablename__ = "makeup_credits"

    student_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    teacher_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("teachers.id", ondelete="CASCADE"),
        nullable=False,
    )
    reason: Mapped[MakeupCreditReason] = mapped_column(
        Enum(MakeupCreditReason, native_enum=True),
        nullable=False,
    )
    # The subscription that originated this credit (if any).
    source_subscription_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("subscriptions.id", ondelete="SET NULL"),
        nullable=True,
    )
    # Optional FK to the originating event (lesson id / vacation id / bulk-change id).
    # No FK constraint — heterogeneous targets.
    source_event_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    # The lesson booking this credit was used on (if used).
    source_lesson_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    used_lesson_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    __table_args__ = (
        CheckConstraint(
            "(used_at IS NULL AND used_lesson_id IS NULL) OR (used_at IS NOT NULL AND used_lesson_id IS NOT NULL)",
            name="ck_makeup_credits_used_pair",
        ),
        Index("idx_makeup_credit_student", "student_id"),
        Index("idx_makeup_credit_teacher", "teacher_id"),
        Index("idx_makeup_credit_expires", "expires_at"),
        Index("idx_makeup_credit_active", "student_id", "used_at", "expires_at"),
    )
