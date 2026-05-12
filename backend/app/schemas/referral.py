"""Schemas for referral API contracts."""

from __future__ import annotations

from pydantic import BaseModel


class ReferralCodeResponse(BaseModel):
    """Current teacher referral code."""

    code: str


class ReferralStatsResponse(BaseModel):
    """Referral statistics."""

    total_referrals: int
    completed_referrals: int
    rewarded_count: int


class ApplyReferralRequest(BaseModel):
    """Apply a referral code."""

    code: str


class ReferralHistoryItem(BaseModel):
    """Referral history item."""

    id: str
    code: str
    referred_teacher_id: str | None
    status: str
    reward_type: str | None
    rewarded_at: str | None
    created_at: str


class ReferralHistoryResponse(BaseModel):
    """Referral history list."""

    history: list[ReferralHistoryItem]
    total: int
