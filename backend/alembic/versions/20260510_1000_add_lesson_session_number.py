"""add_lesson_session_number

Persist the subscription session number directly on generated lesson rows.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_lesson_session_number"
down_revision: str | None = "add_student_teacher_fk"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("lessons") as batch_op:
        batch_op.add_column(sa.Column("session_number", sa.Integer(), nullable=True))
        batch_op.create_index("idx_lesson_subscription_session", ["subscription_id", "session_number"])
        batch_op.create_check_constraint(
            "ck_lessons_session_number_positive",
            "session_number IS NULL OR session_number >= 1",
        )

    op.execute(
        """
        WITH ordered_lessons AS (
            SELECT
                id,
                ROW_NUMBER() OVER (
                    PARTITION BY subscription_id
                    ORDER BY date ASC, start_time ASC, id ASC
                ) AS row_number
            FROM lessons
            WHERE subscription_id IS NOT NULL
        )
        UPDATE lessons
        SET session_number = ordered_lessons.row_number
        FROM ordered_lessons
        WHERE lessons.id = ordered_lessons.id
        """
    )


def downgrade() -> None:
    with op.batch_alter_table("lessons") as batch_op:
        batch_op.drop_constraint("ck_lessons_session_number_positive", type_="check")
        batch_op.drop_index("idx_lesson_subscription_session")
        batch_op.drop_column("session_number")
