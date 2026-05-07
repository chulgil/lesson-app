"""Add foreign keys for notification user ownership.

Revision ID: add_notification_user_fks
Revises: add_teacher_announcements
Create Date: 2026-05-07 10:05:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_notification_user_fks"
down_revision: str | None = "add_teacher_announcements"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("notifications") as batch_op:
        batch_op.create_foreign_key(
            "fk_notifications_user_id_users",
            "users",
            ["user_id"],
            ["id"],
        )

    with op.batch_alter_table("user_notification_preferences") as batch_op:
        batch_op.create_foreign_key(
            "fk_user_notification_preferences_user_id_users",
            "users",
            ["user_id"],
            ["id"],
        )


def downgrade() -> None:
    with op.batch_alter_table("user_notification_preferences") as batch_op:
        batch_op.drop_constraint("fk_user_notification_preferences_user_id_users", type_="foreignkey")

    with op.batch_alter_table("notifications") as batch_op:
        batch_op.drop_constraint("fk_notifications_user_id_users", type_="foreignkey")
