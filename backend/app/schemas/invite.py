"""Invite, connection request, and connection schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, field_validator

# ---------------------------------------------------------------------------
# Invite
# ---------------------------------------------------------------------------

# #1267 — target role prebinding. Kept in sync with app.models.user.UserRole.
VALID_INVITE_TARGET_ROLES = {"teacher", "student", "parent"}


class InviteCreate(BaseModel):
    """Create a new invite."""

    is_single_use: bool = False
    max_uses: int | None = None
    note: str | None = None
    expires_in_hours: int = 48
    target_role: str | None = None

    @field_validator("target_role")
    @classmethod
    def _validate_target_role(cls, value: str | None) -> str | None:
        if value is not None and value not in VALID_INVITE_TARGET_ROLES:
            raise ValueError(f"target_role must be one of {sorted(VALID_INVITE_TARGET_ROLES)}")
        return value


class InviteResponse(BaseModel):
    """Invite record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    creator_id: str
    creator_name: str | None = None
    creator_role: str
    target_role: str | None = None
    invite_code: str
    invite_url: str
    qr_code_data: str
    status: str
    is_single_use: bool
    max_uses: int | None = None
    use_count: int
    note: str | None = None
    expires_at: _dt.datetime
    created_at: _dt.datetime


class PublicInviteLandingTeacher(BaseModel):
    """Public teacher data for invite landing pages."""

    id: str | None = None
    name: str
    instrument: str
    profile_image_url: str | None = None


class PublicInviteLandingShare(BaseModel):
    """Share metadata for invite landing pages."""

    title: str
    description: str
    url: str
    app_deep_link: str


class PublicInviteLandingResponse(BaseModel):
    """Public JSON consumed by Ghost invite landing pages."""

    code: str
    status: str
    teacher: PublicInviteLandingTeacher
    share: PublicInviteLandingShare
    expires_at: _dt.datetime


# ---------------------------------------------------------------------------
# Connection Request
# ---------------------------------------------------------------------------


class ConnectionRequestCreate(BaseModel):
    """Create a connection request."""

    target_id: str
    method: str  # qrCode, urlLink, inviteCode, inAppSearch
    invite_id: str | None = None
    invite_code: str | None = None
    message: str | None = None


class ConnectionRequestResponse(BaseModel):
    """Connection request record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    requester_id: str
    requester_role: str
    requester_name: str | None = None
    requester_profile_image: str | None = None
    target_id: str
    target_role: str
    target_name: str | None = None
    target_profile_image: str | None = None
    method: str
    invite_id: str | None = None
    message: str | None = None
    status: str
    responded_at: _dt.datetime | None = None
    rejection_reason: str | None = None
    expires_at: _dt.datetime
    created_at: _dt.datetime


class ConnectionRequestRespondRequest(BaseModel):
    """Accept or reject a connection request."""

    action: str  # accept, reject
    rejection_reason: str | None = None


# ---------------------------------------------------------------------------
# Connection
# ---------------------------------------------------------------------------


class ConnectionResponse(BaseModel):
    """Established connection."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    teacher_name: str
    teacher_profile_image: str | None = None
    student_id: str
    student_name: str
    student_profile_image: str | None = None
    connection_request_id: str | None = None
    is_active: bool
    deactivated_at: _dt.datetime | None = None
    connected_at: _dt.datetime
