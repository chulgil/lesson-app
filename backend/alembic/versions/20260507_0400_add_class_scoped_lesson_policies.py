"""Add class-scoped lesson policy fields.

Revision ID: add_class_scoped_lesson_policies
Revises: add_request_event_cancellation_types
Create Date: 2026-05-07 04:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_class_scoped_lesson_policies"
down_revision: str | None = "add_request_event_cancellation_types"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.drop_index("uk_policy_teacher", table_name="lesson_policies")
    op.add_column("lesson_policies", sa.Column("lesson_class_id", sa.String(length=36), nullable=True))
    op.add_column(
        "lesson_policies",
        sa.Column("allow_same_day_cancel", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column("lesson_policies", sa.Column("late_cancel_deadline", sa.String(length=5), nullable=True))
    op.add_column(
        "lesson_policies",
        sa.Column("grace_period_minutes", sa.Integer(), nullable=False, server_default="15"),
    )
    op.add_column(
        "lesson_policies",
        sa.Column("allow_carryover", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "lesson_policies",
        sa.Column("max_carryover_lessons", sa.Integer(), nullable=False, server_default="1"),
    )
    op.add_column(
        "lesson_policies",
        sa.Column("carryover_period_months", sa.Integer(), nullable=False, server_default="1"),
    )
    op.add_column("lesson_policies", sa.Column("full_refund_days", sa.Integer(), nullable=False, server_default="1"))
    op.add_column(
        "lesson_policies",
        sa.Column("partial_refund_ratio", sa.Integer(), nullable=False, server_default="67"),
    )
    op.add_column(
        "lesson_policies",
        sa.Column("halfway_refund_ratio", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "lesson_policies",
        sa.Column("no_show_refund_ratio", sa.Integer(), nullable=False, server_default="67"),
    )

    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.create_index(
            "uk_policy_teacher_default",
            "lesson_policies",
            ["teacher_id"],
            unique=True,
            postgresql_where=sa.text("lesson_class_id IS NULL"),
        )
    elif bind.dialect.name == "sqlite":
        op.create_index(
            "uk_policy_teacher_default",
            "lesson_policies",
            ["teacher_id"],
            unique=True,
            sqlite_where=sa.text("lesson_class_id IS NULL"),
        )
    else:
        op.create_index("uk_policy_teacher_default", "lesson_policies", ["teacher_id"], unique=False)

    op.create_index("uk_policy_lesson_class", "lesson_policies", ["lesson_class_id"], unique=True)
    op.create_index("idx_policy_teacher_class", "lesson_policies", ["teacher_id", "lesson_class_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_policy_teacher_class", table_name="lesson_policies")
    op.drop_index("uk_policy_lesson_class", table_name="lesson_policies")
    op.drop_index("uk_policy_teacher_default", table_name="lesson_policies")
    op.drop_column("lesson_policies", "no_show_refund_ratio")
    op.drop_column("lesson_policies", "halfway_refund_ratio")
    op.drop_column("lesson_policies", "partial_refund_ratio")
    op.drop_column("lesson_policies", "full_refund_days")
    op.drop_column("lesson_policies", "carryover_period_months")
    op.drop_column("lesson_policies", "max_carryover_lessons")
    op.drop_column("lesson_policies", "allow_carryover")
    op.drop_column("lesson_policies", "grace_period_minutes")
    op.drop_column("lesson_policies", "late_cancel_deadline")
    op.drop_column("lesson_policies", "allow_same_day_cancel")
    op.drop_column("lesson_policies", "lesson_class_id")
    op.create_index("uk_policy_teacher", "lesson_policies", ["teacher_id"], unique=True)
