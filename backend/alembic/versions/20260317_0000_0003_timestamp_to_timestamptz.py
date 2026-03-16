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


# Generated from actual DB: SELECT table_name, column_name FROM information_schema.columns
# WHERE table_schema='public' AND data_type='timestamp without time zone'
TABLES_COLUMNS = [
    ("class_memberships", ["created_at", "updated_at"]),
    ("connection_requests", ["created_at", "expires_at", "responded_at"]),
    ("connections", ["connected_at", "deactivated_at"]),
    ("daily_practice_statuses", ["completed_at"]),
    ("feedback_presets", ["created_at"]),
    ("follows", ["created_at"]),
    ("gamification_badges", ["earned_at"]),
    ("gamification_points", ["earned_at"]),
    ("group_class_bookings", ["attended_at", "cancelled_at", "created_at", "promoted_at", "updated_at"]),
    ("group_class_schedules", ["created_at", "end_time", "start_time", "updated_at"]),
    ("group_classes", ["created_at", "updated_at"]),
    ("i18n_translations", ["created_at", "updated_at"]),
    ("invites", ["created_at", "expires_at"]),
    ("lesson_bookings", ["created_at", "updated_at"]),
    ("lesson_classes", ["created_at", "updated_at"]),
    ("lesson_policies", ["created_at", "updated_at"]),
    ("lesson_recordings", ["recorded_at"]),
    ("lesson_requests", ["created_at", "expires_at", "status_updated_at"]),
    ("lesson_schedule_changes", ["processed_at", "requested_at"]),
    ("lessons", ["created_at", "updated_at"]),
    ("makeup_lessons", ["created_at", "updated_at"]),
    ("no_show_records", ["created_at"]),
    ("notification_settings", ["created_at", "updated_at"]),
    ("notifications", ["created_at", "read_at", "scheduled_at", "sent_at"]),
    ("oauth_accounts", ["created_at"]),
    ("parent_child_relations", ["connected_at", "updated_at"]),
    ("parent_notification_settings", ["created_at", "updated_at"]),
    ("parent_teacher_connections", ["connected_at", "updated_at"]),
    ("parents", ["created_at", "updated_at"]),
    ("payments", ["confirmed_at", "created_at", "paid_at", "parent_notified_at", "student_confirmed_at", "updated_at"]),
    ("practice_goals", ["created_at", "updated_at"]),
    ("practice_items", ["completed_at", "created_at", "liked_at", "updated_at"]),
    ("practice_logs", ["created_at", "updated_at"]),
    ("practice_notes", ["created_at", "updated_at"]),
    ("practice_recordings", ["created_at"]),
    ("practice_repertoires", ["archived_at", "created_at", "updated_at"]),
    ("practice_sections", ["completed_at", "created_at", "last_practiced_at", "updated_at"]),
    ("practice_streaks", ["created_at", "updated_at"]),
    ("proposal_settings", ["updated_at"]),
    ("schedule_confirmation_cards", ["created_at", "expires_at", "responded_at"]),
    ("schedule_exceptions", ["created_at"]),
    ("students", ["connected_at", "created_at", "updated_at"]),
    ("subscription_proposals", ["confirmed_at", "created_at", "expires_at", "payment_notified_at", "rejected_at"]),
    ("subscription_settings", ["created_at", "updated_at"]),
    ("subscription_templates", ["created_at", "updated_at"]),
    ("subscription_usages", ["used_at"]),
    ("subscriptions", ["created_at", "paid_at", "payment_confirmed_at", "updated_at"]),
    ("teacher_availabilities", ["created_at", "updated_at"]),
    ("teacher_certificates", ["issue_date", "reviewed_at", "submitted_at"]),
    ("teacher_reviews", ["created_at", "updated_at"]),
    ("teacher_settings", ["created_at", "updated_at"]),
    ("teacher_student_relations", ["connected_at", "created_at", "disconnected_at"]),
    ("teachers", ["created_at", "phone_verified_at", "updated_at"]),
    ("teaching_resources", ["created_at", "updated_at"]),
    ("tip_templates", ["created_at", "last_used_at"]),
    ("token_blacklist", ["created_at", "expires_at"]),
    ("tuition_settings", ["created_at", "updated_at"]),
    ("users", ["created_at", "updated_at"]),
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
