"""Support teacher-scoped schedule exceptions (teacher-level or availability-level)."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_schedule_exception_owner_scope"
down_revision: str | None = "add_booking_subscription_origin"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("schedule_exceptions") as batch_op:
        batch_op.alter_column(
            "teacher_availability_id",
            existing_type=sa.String(36),
            nullable=True,
        )
        batch_op.add_column(
            sa.Column("teacher_id", sa.String(36), nullable=True),
        )
        batch_op.create_index("idx_sched_exc_teacher", ["teacher_id"])
        batch_op.create_check_constraint(
            "ck_sched_exc_owner_scope",
            "teacher_availability_id IS NOT NULL OR teacher_id IS NOT NULL",
        )

    # Normalize legacy empty strings and backfill teacher_id from linked availability scope.
    op.execute(
        sa.text("UPDATE schedule_exceptions SET teacher_availability_id = NULL WHERE teacher_availability_id = ''")
    )
    op.execute(
        sa.text(
            """
            UPDATE schedule_exceptions
            SET teacher_id = (
                SELECT ta.teacher_id
                FROM teacher_availabilities ta
                WHERE ta.id = schedule_exceptions.teacher_availability_id
            )
            WHERE teacher_id IS NULL
              AND teacher_availability_id IS NOT NULL
            """
        )
    )


def downgrade() -> None:
    op.execute(
        sa.text(
            """
            UPDATE schedule_exceptions
            SET teacher_availability_id = (
                SELECT ta.id
                FROM teacher_availabilities ta
                WHERE ta.teacher_id = schedule_exceptions.teacher_id
                LIMIT 1
            )
            WHERE teacher_availability_id IS NULL
              AND teacher_id IS NOT NULL
            """
        )
    )
    op.execute(
        sa.text(
            "UPDATE schedule_exceptions SET teacher_availability_id = '' "
            "WHERE teacher_availability_id IS NULL"
        )
    )

    with op.batch_alter_table("schedule_exceptions") as batch_op:
        batch_op.drop_constraint("ck_sched_exc_owner_scope", type_="check")
        batch_op.drop_index("idx_sched_exc_teacher")
        batch_op.drop_column("teacher_id")
        batch_op.alter_column(
            "teacher_availability_id",
            existing_type=sa.String(36),
            nullable=False,
        )
