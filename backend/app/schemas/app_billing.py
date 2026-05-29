"""App billing schema definitions."""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class BillingPlanResponse(BaseModel):
    """Current user app billing plan."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    tier: Literal["free", "pro", "studio"]
    status: Literal["active", "trial", "expired", "cancelled"]
    started_at: datetime
    expires_at: datetime | None
    source: str
    original_transaction_id: str | None
    trial_used: bool


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

    model_config = ConfigDict(from_attributes=True)

    success: bool
    message: str
    plan_id: str | None = None
    tier: str | None = None
    expires_at: datetime | None = None


class TrialStartResponse(BaseModel):
    """Pro trial activation response."""

    model_config = ConfigDict(from_attributes=True)

    success: bool
    message: str
    plan_id: str | None = None
    expires_at: datetime | None = None


class BillingCancelResponse(BaseModel):
    """Cancellation response."""

    success: bool
    message: str


class IapReceiptResponse(BaseModel):
    """IAP receipt audit row."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    platform: str
    product_id: str
    status: str
    validated_at: datetime | None = None
    created_at: datetime
