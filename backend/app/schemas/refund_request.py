"""Subscription refund request schemas — issue #1271."""

from __future__ import annotations

import datetime as _dt

from pydantic import BaseModel, ConfigDict, Field


class RefundRequestCreate(BaseModel):
    """Student-submitted refund request payload."""

    subscription_id: str
    bank_name: str = Field(..., min_length=1, max_length=50)
    account_number: str = Field(..., min_length=1, max_length=50)
    account_holder: str = Field(..., min_length=1, max_length=50)
    reason: str | None = None


class RefundRequestCompleteRequest(BaseModel):
    """Teacher payload confirming the external bank transfer was completed."""

    processed_amount: int = Field(..., gt=0)


class RefundRequestRejectRequest(BaseModel):
    """Teacher payload rejecting a refund request."""

    reject_reason: str = Field(..., min_length=1)


class RefundRequestResponse(BaseModel):
    """Refund request representation.

    Account fields are role/time-gated by the service layer before this
    model is populated (data-privacy.md Level 1) — a student always sees a
    masked ``account_number``, and both roles see ``None`` for all three
    account fields once the 30-day post-processing retention window has
    passed. ``estimated_refund_amount`` is a reference-only figure; the
    teacher's ``processed_amount`` input on completion is authoritative.
    """

    model_config = ConfigDict(from_attributes=True)

    id: str
    subscription_id: str
    student_id: str
    teacher_id: str
    bank_name: str | None = None
    account_number: str | None = None
    account_holder: str | None = None
    reason: str | None = None
    status: str
    processed_amount: int | None = None
    reject_reason: str | None = None
    requested_at: _dt.datetime
    processed_at: _dt.datetime | None = None
    estimated_refund_amount: int | None = None
