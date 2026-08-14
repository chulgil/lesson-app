"""Subscription refund request model.

Issue #1271 — a student can request a refund for a subscription's unused
remainder by submitting bank account details; the teacher transfers the
money externally and marks the request completed (or rejects it). No
in-app payment / PG refund is involved.

``status`` is a plain string column, not a native PostgreSQL enum — this
project has been repeatedly bitten by forgotten ``ALTER TYPE ... ADD
VALUE`` migrations for native enums (see
``alembic/versions/20260814_1000_add_invite_target_role.py``), and this
3-value lifecycle has no reason to grow.
"""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin

REFUND_REQUEST_STATUSES = ("requested", "completed", "rejected")


class RefundRequest(UUIDMixin, Base):
    """Student-initiated refund request for a subscription, teacher-processed."""

    __tablename__ = "refund_requests"

    subscription_id: Mapped[str] = mapped_column(String(36), ForeignKey("subscriptions.id"), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), ForeignKey("students.id"), nullable=False)
    # No FK — mirrors ``LessonClass.teacher_id``, which historical rows may
    # hold as either a Teacher.id or a legacy User.id.
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    bank_name: Mapped[str] = mapped_column(String(50), nullable=False)
    account_number: Mapped[str] = mapped_column(String(50), nullable=False)
    account_holder: Mapped[str] = mapped_column(String(50), nullable=False)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="requested")
    processed_amount: Mapped[int | None] = mapped_column(Integer, nullable=True)
    reject_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    requested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint(
            "status IN ('requested', 'completed', 'rejected')",
            name="ck_refund_requests_status",
        ),
        Index("idx_refund_requests_subscription", "subscription_id"),
        Index("idx_refund_requests_student", "student_id"),
        Index("idx_refund_requests_teacher", "teacher_id"),
        Index("idx_refund_requests_status", "status"),
    )
