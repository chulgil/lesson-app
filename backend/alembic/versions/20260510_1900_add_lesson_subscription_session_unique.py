"""add_lesson_subscription_session_unique

Prevent duplicate lesson session numbers within one subscription.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_lesson_subscription_session_unique"
down_revision: str | None = "add_app_billing_tables"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()
    dialect_name = bind.dialect.name

    if dialect_name == "postgresql":
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
    else:
        lessons = bind.execute(
            sa.text(
                """
                SELECT id, subscription_id
                FROM lessons
                WHERE subscription_id IS NOT NULL
                ORDER BY subscription_id ASC, date ASC, start_time ASC, id ASC
                """
            )
        ).mappings()
        counters: dict[str, int] = {}
        for lesson in lessons:
            subscription_id = lesson["subscription_id"]
            counters[subscription_id] = counters.get(subscription_id, 0) + 1
            bind.execute(
                sa.text("UPDATE lessons SET session_number = :session_number WHERE id = :lesson_id"),
                {"session_number": counters[subscription_id], "lesson_id": lesson["id"]},
            )

    op.create_index(
        "uk_lesson_subscription_session",
        "lessons",
        ["subscription_id", "session_number"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("uk_lesson_subscription_session", table_name="lessons")
