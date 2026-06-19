import enum
from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Enum, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class TeacherSettings(UUIDMixin, TimestampMixin, Base):
    """Teacher-level settings (instruments, durations, etc.)."""

    __tablename__ = "teacher_settings"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    instruments: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=list)
    default_lesson_duration: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    custom_lesson_durations: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=list)
    disabled_durations: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=list)
    break_time_between_lessons: Mapped[int] = mapped_column(Integer, nullable=False, default=10)
    min_booking_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    # Lesson pricing: {"바이올린": {"beginner": 40000, "intermediate": 50000, "advanced": 70000}}
    lesson_price_table: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    # Trial lesson free toggle
    trial_lesson_free: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    booking_guidance_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Issue #606 — 가용시간 SSOT 마이그레이션 단계 1 (dual-write 역호환).
    # [{day_of_week, start_time, end_time}, ...] — TeacherAvailability 와 동일 데이터.
    available_slots: Mapped[list | None] = mapped_column(JSON, nullable=True, default=list)

    __table_args__ = (Index("uk_teacher_settings", "teacher_id", unique=True),)


class SubscriptionSettings(UUIDMixin, TimestampMixin, Base):
    """Subscription alert and discount settings per teacher."""

    __tablename__ = "subscription_settings"

    teacher_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    organization_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    renewal_alert_threshold: Mapped[int] = mapped_column(Integer, nullable=False, default=2)
    renewal_alert_days: Mapped[int] = mapped_column(Integer, nullable=False, default=7)
    renewal_alert_days_set: Mapped[list | None] = mapped_column(
        JSON,
        nullable=True,
        default=lambda: [14, 7, 1, 0],
    )
    discount_policies: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=list)
    enable_push_notification: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    enable_badge: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    notify_parent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (Index("uk_sub_settings_teacher", "teacher_id", unique=True),)


class ProposalSettings(UUIDMixin, Base):
    """Auto-proposal configuration per teacher."""

    __tablename__ = "proposal_settings"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    auto_proposal_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    auto_proposal_template_ids: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=list)
    recommended_template_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    golden_time_discount_percent: Mapped[int] = mapped_column(Integer, nullable=False, default=10)
    golden_time_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=72)
    auto_reminder_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    reminder_hours: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=lambda: [24, 48])
    auto_renewal_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (Index("uk_proposal_settings_teacher", "teacher_id", unique=True),)


class NotificationSettings(UUIDMixin, TimestampMixin, Base):
    """Per-relationship notification settings."""

    __tablename__ = "notification_settings"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    target_user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    push_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    practice_share_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    lesson_reminder_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    payment_reminder_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (Index("uk_notif_settings", "user_id", "target_user_id", unique=True),)


class ParentNotificationSettings(UUIDMixin, TimestampMixin, Base):
    """Parent notification preferences."""

    __tablename__ = "parent_notification_settings"

    parent_id: Mapped[str] = mapped_column(String(36), nullable=False)
    payment_request: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    payment_complete: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    payment_due_soon: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    lesson_change: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    lesson_cancel: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    lesson_start: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    lesson_end: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    new_assignment: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    assignment_incomplete: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    practice_complete: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    streak_achievement: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    teacher_message: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    lesson_note_update: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    weekly_report: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    monthly_report: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    # spec parent_system.md §12.7 — 4개 카테고리 추가 (수강권 잔여 / 만료 임박 / 등록 완료 / 레슨 장소 변경).
    subscription_low_remaining: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    subscription_expiring_soon: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    subscription_registered: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    lesson_location_change: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (Index("uk_parent_notif_settings", "parent_id", unique=True),)


class FeedbackPreset(UUIDMixin, Base):
    """Reusable feedback text preset per teacher."""

    __tablename__ = "feedback_presets"

    teacher_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    is_default: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_hidden: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (Index("idx_feedback_preset_teacher", "teacher_id"),)


class FeedbackCategory(str, enum.Enum):
    technique = "technique"
    musicality = "musicality"
    practice = "practice"
    attitude = "attitude"
    general = "general"


class FeedbackTemplate(UUIDMixin, TimestampMixin, Base):
    """Reusable long-form lesson feedback template per teacher."""

    __tablename__ = "feedback_templates"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[FeedbackCategory] = mapped_column(
        Enum(FeedbackCategory, native_enum=True),
        nullable=False,
        default=FeedbackCategory.general,
    )
    usage_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_feedback_template_teacher", "teacher_id"),
        Index("idx_feedback_template_category", "teacher_id", "category"),
        Index("idx_feedback_template_usage", "teacher_id", "usage_count"),
    )


class FeedbackTemplateTag(UUIDMixin, Base):
    """Normalized tag row for feedback template search/filter."""

    __tablename__ = "feedback_template_tags"

    template_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("feedback_templates.id", ondelete="CASCADE"),
        nullable=False,
    )
    tag: Mapped[str] = mapped_column(String(80), nullable=False)

    __table_args__ = (
        Index("uk_feedback_template_tag", "template_id", "tag", unique=True),
        Index("idx_feedback_template_tag_tag", "tag"),
    )


class TeachingResource(UUIDMixin, TimestampMixin, Base):
    """Teaching resource (YouTube, audio, external link)."""

    __tablename__ = "teaching_resources"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    type: Mapped[str] = mapped_column(String(30), nullable=False)  # teacherRecording, youtube, externalLink
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    youtube_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    youtube_video_id: Mapped[str | None] = mapped_column(String(20), nullable=True)
    youtube_thumbnail: Mapped[str | None] = mapped_column(Text, nullable=True)
    youtube_start_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    youtube_end_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    audio_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    audio_duration_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    external_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)

    __table_args__ = (Index("idx_resource_teacher", "teacher_id"),)


class TeachingResourceTag(UUIDMixin, Base):
    """Normalized tag row for teaching resource search/filter."""

    __tablename__ = "teaching_resource_tags"

    resource_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("teaching_resources.id", ondelete="CASCADE"),
        nullable=False,
    )
    tag: Mapped[str] = mapped_column(String(80), nullable=False)

    __table_args__ = (
        Index("uk_teaching_resource_tag", "resource_id", "tag", unique=True),
        Index("idx_teaching_resource_tag_tag", "tag"),
    )
