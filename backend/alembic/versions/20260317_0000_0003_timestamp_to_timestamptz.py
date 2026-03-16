"""convert all timestamp columns to timestamptz

Revision ID: 0003
Revises: 0002
Create Date: 2026-03-17 00:00:00.000000+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0003'
down_revision: Union[str, None] = '0002'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# All tables and their timestamp columns that need migration
TABLES_COLUMNS = [
    ("users", ["created_at", "updated_at"]),
    ("oauth_accounts", ["created_at"]),
    ("token_blacklist", ["created_at", "expires_at"]),
    ("teachers", ["created_at", "updated_at", "phone_verified_at"]),
    ("teacher_educations", ["created_at", "updated_at"]),
    ("teacher_careers", ["created_at", "updated_at"]),
    ("teacher_certificates", ["created_at", "updated_at", "issue_date", "submitted_at", "reviewed_at"]),
    ("students", ["created_at", "updated_at", "connected_at"]),
    ("lesson_classes", ["created_at", "updated_at"]),
    ("class_memberships", ["created_at", "updated_at"]),
    ("lesson_locations", ["created_at", "updated_at"]),
    ("lessons", ["created_at", "updated_at"]),
    ("lesson_recordings", ["recorded_at"]),
    ("subscriptions", ["created_at", "updated_at", "paid_at", "payment_confirmed_at"]),
    ("subscription_usages", ["created_at", "used_at"]),
    ("subscription_templates", ["created_at", "updated_at"]),
    ("subscription_proposals", ["created_at", "updated_at", "expires_at", "payment_notified_at", "confirmed_at", "rejected_at"]),
    ("payments", ["created_at", "updated_at", "student_confirmed_at", "paid_at", "confirmed_at", "parent_notified_at"]),
    ("tuition_settings", ["created_at", "updated_at"]),
    ("practice_repertoires", ["created_at", "updated_at", "archived_at"]),
    ("practice_sections", ["created_at", "updated_at", "last_practiced_at", "completed_at"]),
    ("daily_practice_statuses", ["completed_at"]),
    ("practice_recordings", ["created_at"]),
    ("practice_notes", ["created_at", "updated_at"]),
    ("practice_goals", ["created_at", "updated_at"]),
    ("practice_streaks", ["created_at", "updated_at"]),
    ("practice_items", ["created_at", "updated_at", "completed_at", "liked_at"]),
    ("teacher_student_relations", ["created_at", "connected_at", "disconnected_at"]),
    ("follows", ["created_at"]),
    ("teacher_availabilities", ["created_at", "updated_at"]),
    ("lesson_bookings", ["created_at", "updated_at"]),
    ("lesson_requests", ["created_at", "expires_at", "status_updated_at"]),
    ("group_classes", ["created_at", "updated_at"]),
    ("notifications", ["created_at", "scheduled_at", "sent_at", "read_at"]),
    ("parents", ["created_at", "updated_at"]),
    ("parent_child_relations", ["linked_at", "unlinked_at"]),
    ("parent_teacher_connections", ["connected_at", "updated_at"]),
    ("lesson_policies", ["created_at", "updated_at"]),
    ("makeup_lessons", ["created_at", "updated_at"]),
    ("schedule_confirmation_cards", ["created_at", "responded_at", "expires_at"]),
    ("i18n_translations", ["created_at", "updated_at"]),
    ("supported_locales", ["created_at", "updated_at"]),
    ("tip_templates", ["created_at", "updated_at", "last_used_at"]),
    # Migration 0002 tables
    ("invites", ["created_at", "expires_at"]),
    ("connection_requests", ["created_at", "responded_at", "expires_at"]),
    ("connections", ["connected_at", "deactivated_at"]),
    ("gamification_points", ["earned_at"]),
    ("gamification_badges", ["earned_at"]),
    ("teacher_settings", ["created_at", "updated_at"]),
    ("subscription_settings", ["created_at", "updated_at"]),
    ("proposal_settings", ["updated_at"]),
    ("notification_settings", ["created_at", "updated_at"]),
    ("parent_notification_settings", ["created_at", "updated_at"]),
    ("feedback_presets", ["created_at"]),
    ("teaching_resources", ["created_at", "updated_at"]),
    ("teacher_reviews", ["created_at", "updated_at"]),
    ("schedule_exceptions", ["created_at"]),
    ("group_class_schedules", ["created_at", "updated_at", "start_time", "end_time"]),
    ("group_class_bookings", ["created_at", "updated_at", "attended_at", "cancelled_at", "promoted_at"]),
    ("no_show_records", ["created_at"]),
    ("lesson_schedule_changes", ["requested_at", "processed_at"]),
    ("practice_logs", ["created_at", "updated_at"]),
]


def upgrade() -> None:
    for table, columns in TABLES_COLUMNS:
        for col in columns:
            op.execute(
                f"ALTER TABLE {table} ALTER COLUMN {col} TYPE TIMESTAMPTZ USING {col} AT TIME ZONE 'UTC'"
            )


def downgrade() -> None:
    for table, columns in TABLES_COLUMNS:
        for col in columns:
            op.execute(
                f"ALTER TABLE {table} ALTER COLUMN {col} TYPE TIMESTAMP WITHOUT TIME ZONE"
            )
