"""Alimtalk send log — #423.

One row per (proposal/subscription, template) attempt. Used to:
  * Enforce idempotency (same `(proposal_id|subscription_id, template_id)` → single send)
  * Power retry of failed sends (`retry_count < 3` and recent)
  * Provide an audit trail of student/parent-facing notifications

Storage is provider-agnostic: the carrier's `message_id` is recorded for traceability
but is not used as a primary key.
"""

from datetime import datetime
from enum import Enum

from sqlalchemy import JSON, Boolean, DateTime, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin

# ruff: noqa: N815, UP042


class AlimTalkTemplate(str, Enum):
    invoice = "LNZ_INVOICE"
    reminder_d1 = "LNZ_PAYMENT_REMINDER_D1"
    reminder_d3 = "LNZ_PAYMENT_REMINDER_D3"
    reminder_d7 = "LNZ_PAYMENT_REMINDER_D7"
    payment_confirm = "LNZ_PAYMENT_CONFIRM"
    # spec: docs/specs/schedule/teacher_vacation_mode.md §6.1 — sent right after
    # a teacher registers a vacation period that impacts the student.
    teacher_vacation = "LNZ_TEACHER_VACATION"
    # spec: §7.3 Recovery — sent when a teacher cancels a vacation within the
    # 24h window. Students whose lessons were restored need to know.
    teacher_vacation_cancelled = "LNZ_TEACHER_VACATION_CANCELLED"
    # spec: §6.3 — daily cron at KST 08:05 announces the teacher's return for
    # vacations whose end_date was yesterday. One send per (vacation, phone).
    teacher_vacation_returned = "LNZ_TEACHER_VACATION_RETURNED"


class AlimTalkLog(UUIDMixin, Base):
    """Audit log of every alimtalk send attempt (success or failure)."""

    __tablename__ = "alimtalk_logs"

    template_id: Mapped[str] = mapped_column(String(64), nullable=False)
    # Identify the originating object — exactly one of these is populated.
    proposal_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    subscription_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    # spec: H-001 §6.1 — vacation periods fan out one row per student, keyed by
    # (vacation_period_id, recipient_phone, template_id) for idempotency.
    vacation_period_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    recipient_phone: Mapped[str] = mapped_column(String(32), nullable=False)
    variables: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)

    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    success: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    message_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)
    retry_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    # Fallback channel used when alimtalk itself failed (e.g. "push" / "sms").
    fallback_channel: Mapped[str | None] = mapped_column(String(32), nullable=True)

    __table_args__ = (
        Index("idx_alimtalk_proposal_template", "proposal_id", "template_id"),
        Index("idx_alimtalk_subscription_template", "subscription_id", "template_id"),
        Index(
            "idx_alimtalk_vacation_phone_template",
            "vacation_period_id",
            "recipient_phone",
            "template_id",
        ),
        Index("idx_alimtalk_sent_at", "sent_at"),
        Index("idx_alimtalk_retry", "success", "retry_count"),
    )
