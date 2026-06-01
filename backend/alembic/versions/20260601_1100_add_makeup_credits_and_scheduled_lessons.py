"""add_makeup_credits_and_scheduled_lessons

#432 G3 — Make-up Bank + scheduledLessons track.

Two changes in one revision:
1. New `makeup_credits` table — separate credit entity (per spec §3.1).
2. New `subscriptions.scheduled_lessons` column — count of active LessonBookings
   (per spec §3.2). Default 0; non-negative constraint updated.

Spec: docs/specs/subscription/makeup_credit_spec.md
Branched off origin/main HEAD (undo_confirm_payment_support).
The vacation worktree (#431) adds `subscriptions.auto_extended_days` independently —
no overlap with this revision.

Revision ID: makeup_credits_and_scheduled_lessons
Revises: undo_confirm_payment_support
Create Date: 2026-06-01 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "makeup_credits_and_scheduled_lessons"
down_revision: str | None = "undo_confirm_payment_support"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# ruff: noqa: E501


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def _has_table(table_name: str) -> bool:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return inspector.has_table(table_name)


def _existing_check_constraint(table_name: str, constraint_name: str) -> bool:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    try:
        for cc in inspector.get_check_constraints(table_name):
            if cc.get("name") == constraint_name:
                return True
    except NotImplementedError:
        return False
    return False


def upgrade() -> None:
    # ------------------------------------------------------------------
    # 1) makeup_credits table
    # ------------------------------------------------------------------
    if not _has_table("makeup_credits"):
        op.create_table(
            "makeup_credits",
            sa.Column("id", sa.String(length=36), primary_key=True),
            sa.Column(
                "student_id",
                sa.String(length=36),
                sa.ForeignKey("students.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column(
                "teacher_id",
                sa.String(length=36),
                sa.ForeignKey("teachers.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column(
                "reason",
                sa.Enum(
                    "teacherVacation",
                    "noShowExempt",
                    "bulkChangeLoss",
                    "manualGrant",
                    "fifthWeekBonus",
                    name="makeupcreditreason",
                ),
                nullable=False,
            ),
            sa.Column(
                "source_subscription_id",
                sa.String(length=36),
                sa.ForeignKey("subscriptions.id", ondelete="SET NULL"),
                nullable=True,
            ),
            sa.Column("source_event_id", sa.String(length=36), nullable=True),
            sa.Column("source_lesson_id", sa.String(length=36), nullable=True),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("used_lesson_id", sa.String(length=36), nullable=True),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                nullable=False,
                server_default=sa.func.now(),
            ),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                nullable=False,
                server_default=sa.func.now(),
            ),
            sa.CheckConstraint(
                "(used_at IS NULL AND used_lesson_id IS NULL) OR (used_at IS NOT NULL AND used_lesson_id IS NOT NULL)",
                name="ck_makeup_credits_used_pair",
            ),
        )
        op.create_index("idx_makeup_credit_student", "makeup_credits", ["student_id"])
        op.create_index("idx_makeup_credit_teacher", "makeup_credits", ["teacher_id"])
        op.create_index("idx_makeup_credit_expires", "makeup_credits", ["expires_at"])
        op.create_index(
            "idx_makeup_credit_active",
            "makeup_credits",
            ["student_id", "used_at", "expires_at"],
        )

    # ------------------------------------------------------------------
    # 2) subscriptions.scheduled_lessons column
    # ------------------------------------------------------------------
    if "scheduled_lessons" not in _columns("subscriptions"):
        op.add_column(
            "subscriptions",
            sa.Column(
                "scheduled_lessons",
                sa.Integer(),
                nullable=False,
                server_default="0",
            ),
        )

    # Update non-negative-counters CHECK to include scheduled_lessons.
    # Use batch mode for SQLite (CHECK constraint redefinition).
    new_check = (
        "used_lessons >= 0 AND bonus_count >= 0 "
        "AND total_reschedule_allowance >= 0 AND used_reschedule_count >= 0 "
        "AND scheduled_lessons >= 0"
    )
    with op.batch_alter_table("subscriptions") as batch_op:
        if _existing_check_constraint("subscriptions", "ck_subscriptions_non_negative_counters"):
            batch_op.drop_constraint(
                "ck_subscriptions_non_negative_counters",
                type_="check",
            )
        batch_op.create_check_constraint(
            "ck_subscriptions_non_negative_counters",
            new_check,
        )


def downgrade() -> None:
    # Restore old non-negative-counters CHECK first.
    old_check = (
        "used_lessons >= 0 AND bonus_count >= 0 AND total_reschedule_allowance >= 0 AND used_reschedule_count >= 0"
    )
    with op.batch_alter_table("subscriptions") as batch_op:
        if _existing_check_constraint("subscriptions", "ck_subscriptions_non_negative_counters"):
            batch_op.drop_constraint(
                "ck_subscriptions_non_negative_counters",
                type_="check",
            )
        batch_op.create_check_constraint(
            "ck_subscriptions_non_negative_counters",
            old_check,
        )

    if "scheduled_lessons" in _columns("subscriptions"):
        op.drop_column("subscriptions", "scheduled_lessons")

    if _has_table("makeup_credits"):
        op.drop_index("idx_makeup_credit_active", table_name="makeup_credits")
        op.drop_index("idx_makeup_credit_expires", table_name="makeup_credits")
        op.drop_index("idx_makeup_credit_teacher", table_name="makeup_credits")
        op.drop_index("idx_makeup_credit_student", table_name="makeup_credits")
        op.drop_table("makeup_credits")

    # Drop the Postgres enum type if present.
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("DROP TYPE IF EXISTS makeupcreditreason")
