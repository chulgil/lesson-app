"""Add bulk teacher action request event types.

Revision ID: add_bulk_teacher_action_event_types
Revises: add_user_notification_preferences
Create Date: 2026-05-07 07:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_bulk_teacher_action_event_types"
down_revision: str | None = "add_user_notification_preferences"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return

    op.execute("ALTER TYPE requesteventtype ADD VALUE IF NOT EXISTS 'lessonCancelledByTeacher'")
    op.execute("ALTER TYPE requesteventtype ADD VALUE IF NOT EXISTS 'teacherAnnouncement'")


def downgrade() -> None:
    # PostgreSQL cannot drop enum values without recreating the type and rewriting data.
    pass
