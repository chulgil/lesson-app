"""Add basic integrity constraints for schedule availability data.

Revision ID: add_schedule_availability_time_constraints
Revises: add_notification_user_fks
Create Date: 2026-05-07 11:10:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_schedule_availability_time_constraints"
down_revision: str | None = "add_notification_user_fks"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("teacher_availabilities") as batch_op:
        batch_op.create_check_constraint(
            "ck_teacher_availabilities_day_of_week",
            "day_of_week BETWEEN 0 AND 6",
        )

    with op.batch_alter_table("availability_time_slots") as batch_op:
        batch_op.create_check_constraint(
            "ck_availability_time_slots_temporal_order",
            "end_time > start_time",
        )


def downgrade() -> None:
    with op.batch_alter_table("availability_time_slots") as batch_op:
        batch_op.drop_constraint(
            "ck_availability_time_slots_temporal_order",
            type_="check",
        )

    with op.batch_alter_table("teacher_availabilities") as batch_op:
        batch_op.drop_constraint(
            "ck_teacher_availabilities_day_of_week",
            type_="check",
        )
