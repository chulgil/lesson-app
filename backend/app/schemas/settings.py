"""Settings schemas (teacher, subscription, proposal, notification, feedback, resource)."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, Field

# ---------------------------------------------------------------------------
# Teacher Settings
# ---------------------------------------------------------------------------

class TeacherSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    instruments: list[str] = []
    default_lesson_duration: int = 60
    custom_lesson_durations: list[int] = []
    disabled_durations: list[int] = []
    break_time_between_lessons: int = 10
    min_booking_hours: int = 0
    lesson_price_table: dict | None = None
    trial_lesson_free: bool = False
    booking_guidance_message: str | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime


class TeacherSettingsUpdate(BaseModel):
    instruments: list[str] | None = None
    default_lesson_duration: int | None = None
    custom_lesson_durations: list[int] | None = None
    disabled_durations: list[int] | None = None
    break_time_between_lessons: int | None = None
    min_booking_hours: int | None = None
    lesson_price_table: dict | None = None
    trial_lesson_free: bool | None = None
    booking_guidance_message: str | None = None


# ---------------------------------------------------------------------------
# Subscription Settings
# ---------------------------------------------------------------------------

class SubscriptionSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str | None = None
    organization_id: str | None = None
    renewal_alert_threshold: int
    renewal_alert_days: int
    renewal_alert_days_set: list[int] = [14, 7, 1, 0]
    discount_policies: list[dict] = []
    enable_push_notification: bool
    enable_badge: bool
    notify_parent: bool
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class SubscriptionSettingsUpdate(BaseModel):
    teacher_id: str | None = None
    organization_id: str | None = None
    renewal_alert_threshold: int | None = None
    renewal_alert_days: int | None = None
    renewal_alert_days_set: list[int] | None = None
    discount_policies: list[dict] | None = None
    enable_push_notification: bool | None = None
    enable_badge: bool | None = None
    notify_parent: bool | None = None


# ---------------------------------------------------------------------------
# Proposal Settings
# ---------------------------------------------------------------------------

class ProposalSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    auto_proposal_enabled: bool
    auto_proposal_template_ids: list[str] = []
    recommended_template_id: str | None = None
    golden_time_discount_percent: int
    golden_time_hours: int
    auto_reminder_enabled: bool
    reminder_hours: list[int] = []
    auto_renewal_enabled: bool


class ProposalSettingsUpdate(BaseModel):
    auto_proposal_enabled: bool | None = None
    auto_proposal_template_ids: list[str] | None = None
    recommended_template_id: str | None = None
    golden_time_discount_percent: int | None = None
    golden_time_hours: int | None = None
    auto_reminder_enabled: bool | None = None
    reminder_hours: list[int] | None = None
    auto_renewal_enabled: bool | None = None


# ---------------------------------------------------------------------------
# Notification Settings (per-relationship)
# ---------------------------------------------------------------------------

class NotificationSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    target_user_id: str
    push_enabled: bool
    practice_share_enabled: bool
    lesson_reminder_enabled: bool
    payment_reminder_enabled: bool


class NotificationSettingsUpdate(BaseModel):
    push_enabled: bool | None = None
    practice_share_enabled: bool | None = None
    lesson_reminder_enabled: bool | None = None
    payment_reminder_enabled: bool | None = None


# ---------------------------------------------------------------------------
# Parent Notification Settings
# ---------------------------------------------------------------------------

class ParentNotificationSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    parent_id: str
    payment_request: bool
    payment_complete: bool
    payment_due_soon: bool
    lesson_change: bool
    lesson_cancel: bool
    lesson_start: bool
    lesson_end: bool
    new_assignment: bool
    assignment_incomplete: bool
    practice_complete: bool
    streak_achievement: bool
    teacher_message: bool
    lesson_note_update: bool
    weekly_report: bool
    monthly_report: bool


class ParentNotificationSettingsUpdate(BaseModel):
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


# ---------------------------------------------------------------------------
# Feedback Presets
# ---------------------------------------------------------------------------

class FeedbackPresetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str | None = None
    text: str
    sort_order: int
    is_default: bool
    is_hidden: bool
    created_at: _dt.datetime


class FeedbackPresetCreate(BaseModel):
    text: str
    sort_order: int = 0


class FeedbackPresetUpdate(BaseModel):
    text: str | None = None
    sort_order: int | None = None
    is_hidden: bool | None = None


# ---------------------------------------------------------------------------
# Feedback Templates
# ---------------------------------------------------------------------------

class FeedbackTemplateResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    title: str
    body: str
    tags: list[str] = []
    category: str
    usage_count: int
    created_at: _dt.datetime
    last_used_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class FeedbackTemplateCreate(BaseModel):
    title: str
    body: str
    tags: list[str] = []
    category: str = "general"


class FeedbackTemplateUpdate(BaseModel):
    title: str | None = None
    body: str | None = None
    tags: list[str] | None = None
    category: str | None = None


# ---------------------------------------------------------------------------
# Tip Templates
# ---------------------------------------------------------------------------

class TipTemplateResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    content: str
    category: str
    instrument: str | None = None
    usage_count: int
    last_used_at: _dt.datetime | None = None
    created_at: _dt.datetime


class TipTemplateCreate(BaseModel):
    content: str
    category: str = "general"
    instrument: str | None = None


class TipTemplateUpdate(BaseModel):
    content: str | None = None
    category: str | None = None
    instrument: str | None = None


# ---------------------------------------------------------------------------
# Teaching Resources
# ---------------------------------------------------------------------------

class TeachingResourceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    type: str
    title: str
    description: str | None = None
    youtube_url: str | None = None
    youtube_video_id: str | None = None
    youtube_thumbnail: str | None = None
    youtube_start_seconds: int | None = None
    youtube_end_seconds: int | None = None
    audio_url: str | None = None
    audio_duration_seconds: int | None = None
    external_url: str | None = None
    instrument: str | None = None
    tags: list[str] = []
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class TeachingResourceCreate(BaseModel):
    type: str  # teacherRecording, youtube, externalLink
    title: str
    description: str | None = None
    youtube_url: str | None = None
    youtube_video_id: str | None = None
    youtube_thumbnail: str | None = None
    youtube_start_seconds: int | None = None
    youtube_end_seconds: int | None = None
    audio_url: str | None = None
    audio_duration_seconds: int | None = None
    external_url: str | None = None
    instrument: str | None = None
    tags: list[str] = []


class TeachingResourceUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    youtube_url: str | None = None
    youtube_video_id: str | None = None
    youtube_thumbnail: str | None = None
    youtube_start_seconds: int | None = None
    youtube_end_seconds: int | None = None
    audio_url: str | None = None
    audio_duration_seconds: int | None = None
    external_url: str | None = None
    instrument: str | None = None
    tags: list[str] | None = None


# ---------------------------------------------------------------------------
# Cancellation Defaults (#1178)
# ---------------------------------------------------------------------------


class CancellationDefaultsResponse(BaseModel):
    """Wire shape mirrors the FE CancellationDefaults entity (snake_case keys)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    cancellation_deadline_hours: int
    student_compensation_extra_minutes_enabled: bool
    include_extra_minutes_text_on_late_cancel: bool
    student_compensation_extra_minutes_message: str | None = None
    notify_owner_on_late_cancel: bool
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class CancellationDefaultsUpdate(BaseModel):
    """Partial update; explicit null clears the custom message (exclude_unset)."""

    cancellation_deadline_hours: int | None = Field(default=None, ge=0, le=168)
    student_compensation_extra_minutes_enabled: bool | None = None
    include_extra_minutes_text_on_late_cancel: bool | None = None
    student_compensation_extra_minutes_message: str | None = Field(default=None, max_length=200)
    notify_owner_on_late_cancel: bool | None = None
