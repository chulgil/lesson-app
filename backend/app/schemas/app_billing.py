"""App billing schema definitions."""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class BillingPlanResponse(BaseModel):
    """Current user app billing plan."""

    id: str
    user_id: str
    tier: Literal["free", "pro", "studio"]
    status: Literal["active", "trial", "expired", "cancelled"]
    started_at: datetime
    expires_at: datetime | None
    source: str
    original_transaction_id: str | None
    trial_used: bool

    class Config:
        from_attributes = True


class IapValidateRequest(BaseModel):
    """In-app purchase receipt validation request."""

    platform: Literal["apple", "google"] = Field(
        ...,
        description="IAP platform (apple or google)",
    )
    receipt: str = Field(
        ...,
        description="Base64-encoded receipt data (raw receipt for Apple, purchase token for Google)",
    )
    product_id: str = Field(
        ...,
        description="Product ID (SKU) purchased",
    )


class IapValidateResponse(BaseModel):
    """IAP receipt validation response."""

    success: bool
    message: str
    plan_id: str | None = None
    tier: str | None = None
    expires_at: datetime | None = None

    class Config:
        from_attributes = True


class TrialStartResponse(BaseModel):
    """Pro trial activation response."""

    success: bool
    message: str
    plan_id: str | None = None
    expires_at: datetime | None = None

    class Config:
        from_attributes = True
