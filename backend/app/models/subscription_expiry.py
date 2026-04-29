"""Subscription expiry dispatch log — Plan C Phase 6a.

Dedup table for D-14/D-7/D-1/D-0 expiry notifications.
UNIQUE(subscription_id, milestone, sent_date, recipient_user_id) prevents duplicates
across multi-instance APScheduler firings (paired with PG advisory lock).
"""

from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Date, DateTime, Index, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class SubscriptionExpiryDispatchLog(UUIDMixin, Base):
    """One row per (subscription, milestone, recipient, sent_date) dispatch."""

    __tablename__ = "subscription_expiry_dispatch_log"

    subscription_id: Mapped[str] = mapped_column(String(36), nullable=False)
    milestone: Mapped[int] = mapped_column(Integer, nullable=False)
    recipient_user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    recipient_role: Mapped[str] = mapped_column(String(20), nullable=False)
    sent_date: Mapped[date] = mapped_column(Date, nullable=False)
    sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        UniqueConstraint(
            "subscription_id",
            "milestone",
            "sent_date",
            "recipient_user_id",
            name="uq_sub_expiry_dispatch",
        ),
        Index("idx_sub_expiry_dispatch_sub", "subscription_id"),
        Index("idx_sub_expiry_dispatch_sent_date", "sent_date"),
    )
