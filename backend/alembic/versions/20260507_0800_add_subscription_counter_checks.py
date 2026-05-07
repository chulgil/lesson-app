"""Add subscription counter check constraints.

Revision ID: add_subscription_counter_checks
Revises: add_bulk_teacher_action_event_types
Create Date: 2026-05-07 08:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_subscription_counter_checks"
down_revision: str | None = "add_bulk_teacher_action_event_types"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.create_check_constraint(
            "ck_subscriptions_non_negative_counters",
            "used_lessons >= 0 "
            "AND bonus_count >= 0 "
            "AND total_reschedule_allowance >= 0 "
            "AND used_reschedule_count >= 0",
        )
        batch_op.create_check_constraint(
            "ck_subscriptions_lesson_counter_capacity",
            "((type = 'trial' AND used_lessons <= 1 + bonus_count) "
            "OR (type != 'trial' AND total_lessons IS NOT NULL AND used_lessons <= total_lessons + bonus_count) "
            "OR (type != 'trial' AND total_lessons IS NULL AND lessons_per_month IS NOT NULL "
            "AND used_lessons <= lessons_per_month + bonus_count) "
            "OR (type != 'trial' AND total_lessons IS NULL AND lessons_per_month IS NULL))",
        )
        batch_op.create_check_constraint(
            "ck_subscriptions_reschedule_counter_capacity",
            "used_reschedule_count <= total_reschedule_allowance",
        )


def downgrade() -> None:
    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.drop_constraint("ck_subscriptions_reschedule_counter_capacity", type_="check")
        batch_op.drop_constraint("ck_subscriptions_lesson_counter_capacity", type_="check")
        batch_op.drop_constraint("ck_subscriptions_non_negative_counters", type_="check")
