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


class ChildProfileResponse(BaseModel):
    """Child profile response matching the Flutter ChildProfile contract."""

    id: str
    parent_id: str
    name: str
    birth_year: int
    instrument: str
    level: str
    teacher_id: str | None = None
    teacher_name: str | None = None
    linked_student_id: str
    profile_color: str
    status: str = "active"
    connection_status: str = "unconnected"
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None

    model_config = ConfigDict(
        alias_generator=lambda field_name: "".join(
            word.capitalize() if index else word for index, word in enumerate(field_name.split("_"))
        ),
        populate_by_name=True,
    )


class ChildProfileCreate(BaseModel):
    """Create a parent-owned child profile backed by Student."""

    parent_id: str
    name: str
    birth_year: int
    instrument: str = ""
    level: str = "beginner"
    profile_color: str | None = None

    model_config = ConfigDict(
        alias_generator=lambda field_name: "".join(
            word.capitalize() if index else word for index, word in enumerate(field_name.split("_"))
        ),
        populate_by_name=True,
    )


class ChildProfileUpdate(BaseModel):
    """Update a child profile."""

    name: str | None = None
    birth_year: int | None = None
    instrument: str | None = None
    level: str | None = None
    profile_color: str | None = None
    status: str | None = None

    model_config = ConfigDict(
        alias_generator=lambda field_name: "".join(
            word.capitalize() if index else word for index, word in enumerate(field_name.split("_"))
        ),
        populate_by_name=True,
    )


class ChildTeacherConnectRequest(BaseModel):
    """Connect a teacher to a parent-owned child profile."""

    teacher_id: str
    teacher_name: str | None = None

    model_config = ConfigDict(
        alias_generator=lambda field_name: "".join(
            word.capitalize() if index else word for index, word in enumerate(field_name.split("_"))
        ),
        populate_by_name=True,
    )


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
    # spec parent_system.md §12.7 — 추가 4 카테고리.
    subscription_low_remaining: bool = True
    subscription_expiring_soon: bool = True
    subscription_registered: bool = True
    lesson_location_change: bool = True
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
    # spec parent_system.md §12.7 — 추가 4 카테고리.
    subscription_low_remaining: bool | None = None
    subscription_expiring_soon: bool | None = None
    subscription_registered: bool | None = None
    lesson_location_change: bool | None = None
