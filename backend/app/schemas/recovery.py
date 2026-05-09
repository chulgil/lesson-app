"""Schemas for account recovery and session management."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class RecoveryCodesGenerateRequest(BaseModel):
    """Request to generate recovery codes."""

    pass


class RecoveryCodesGenerateResponse(BaseModel):
    """Response with generated recovery codes."""

    codes: list[str]
    message: str = "Recovery codes generated. Save them in a secure location."


class RecoveryCodesVerifyRequest(BaseModel):
    """Request to verify a recovery code."""

    code: str


class UserSessionResponse(BaseModel):
    """Response model for a user session."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    device_name: str | None
    device_type: str | None
    ip_address: str | None
    last_active_at: datetime
    is_active: bool
    created_at: datetime


class UserSessionListResponse(BaseModel):
    """Response with list of active sessions."""

    sessions: list[UserSessionResponse]
    count: int
