"""Schemas for app billing API contracts."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class BillingStatusResponse(BaseModel):
    """Current billing plan status."""

    plan: str
    is_active: bool
    student_limit: int | None
    expires_at: datetime | None
    trial_ends_at: datetime | None
    days_remaining: int | None
    features: dict[str, bool]


class TrialStartResponse(BaseModel):
    """Trial start result."""

    plan: str
    trial_ends_at: datetime


class VerifyPurchaseRequest(BaseModel):
    """Store receipt verification request."""

    store_platform: str
    product_id: str
    transaction_id: str
    receipt_data: str


class VerifyPurchaseResponse(BaseModel):
    """Store receipt verification result."""

    plan: str
    is_active: bool
    expires_at: datetime | None


class ProductInfo(BaseModel):
    """Available app billing product metadata."""

    product_id: str
    plan: str
    description: str
