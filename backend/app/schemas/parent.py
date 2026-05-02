"""Parent-related schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict

from app.schemas.student import StudentResponse


class ParentResponse(BaseModel):
    """Parent profile."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    name: str | None = None
    phone: str | None = None
    email: str | None = None
    profile_image_url: str | None = None
    profile_color: str | None = None
    status: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class ParentUpdate(BaseModel):
    """Update parent profile."""

    name: str | None = None
    phone: str | None = None
    email: str | None = None
    profile_image_url: str | None = None
    profile_color: str | None = None


class ParentCreate(BaseModel):
    """Create a parent profile."""

    user_id: str | None = None
    name: str
    phone: str | None = None
    email: str | None = None
    profile_image_url: str | None = None
    profile_color: str | None = None


class ParentChildResponse(BaseModel):
    """A child linked to a parent."""

    model_config = ConfigDict(from_attributes=True)

    student: StudentResponse
    linked_at: _dt.datetime | None = None


class ParentChildRelationResponse(BaseModel):
    """Parent-child relation response used by the frontend parent repository."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    parent_id: str
    student_id: str
    is_primary_guardian: bool = True
    is_billing_target: bool = True
    status: str = "active"
    linked_at: _dt.datetime | None = None
    unlinked_at: _dt.datetime | None = None


class ParentChildRelationUpdate(BaseModel):
    """Update a parent-child relation."""

    parent_id: str | None = None
    student_id: str | None = None
    is_primary_guardian: bool | None = None
    is_billing_target: bool | None = None
    status: str | None = None


class ParentConnectChildRequest(BaseModel):
    """Link a child via invite code."""

    invite_code: str


class ParentInvitationCreate(BaseModel):
    """Create a parent invitation."""

    student_id: str
    teacher_id: str | None = None
    source: str
    parent_phone: str
    parent_email: str | None = None


class ParentInvitationResponse(BaseModel):
    """Parent invitation response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str | None = None
    source: str
    parent_phone: str
    parent_email: str | None = None
    invitation_code: str
    expires_at: _dt.datetime
    is_used: bool
    created_at: _dt.datetime | None = None


class ParentVisibilitySettingsResponse(BaseModel):
    """Teacher-controlled parent visibility settings for a student."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    student_id: str
    can_view_schedule: bool = True
    can_view_assignments: bool = True
    can_view_practice: bool = True
    can_view_lesson_notes: bool = True
    can_view_recordings: bool = False
    can_view_detailed_feedback: bool = False
    can_view_chat: bool = False
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class ParentVisibilitySettingsUpdate(BaseModel):
    """Create or update parent visibility settings."""

    teacher_id: str
    student_id: str
    can_view_schedule: bool | None = None
    can_view_assignments: bool | None = None
    can_view_practice: bool | None = None
    can_view_lesson_notes: bool | None = None
    can_view_recordings: bool | None = None
    can_view_detailed_feedback: bool | None = None
    can_view_chat: bool | None = None


class ParentNotificationSettingsResponse(BaseModel):
    """Parent notification settings response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    parent_id: str
    payment_request: bool = True
    payment_complete: bool = True
    payment_due_soon: bool = True
    lesson_change: bool = True
    lesson_cancel: bool = True
    lesson_start: bool = False
    lesson_end: bool = False
    new_assignment: bool = True
    assignment_incomplete: bool = True
    practice_complete: bool = False
    streak_achievement: bool = False
    teacher_message: bool = True
    lesson_note_update: bool = False
    weekly_report: bool = True
    monthly_report: bool = True
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class ParentNotificationSettingsUpdate(BaseModel):
    """Update parent notification settings."""

    parent_id: str
    payment_request: bool | None = None
    payment_complete: bool | None = None
    payment_due_soon: bool | None = None
    lesson_change: bool | None = None
    lesson_cancel: bool | None = None
    lesson_start: bool | None = None
    lesson_end: bool | None = None
    new_assignment: bool | None = None
    assignment_incomplete: bool | None = None
    practice_complete: bool | None = None
    streak_achievement: bool | None = None
    teacher_message: bool | None = None
    lesson_note_update: bool | None = None
    weekly_report: bool | None = None
    monthly_report: bool | None = None
