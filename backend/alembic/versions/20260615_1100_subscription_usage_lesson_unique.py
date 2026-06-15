"""#742 — unique index on subscription_usages.lesson_id to prevent double-deduction race.

Adds a unique index so that two concurrent calls to deduct_for_completed_lesson
for the same lesson_id hit an IntegrityError on the second INSERT rather than
silently double-counting. SQLite and Postgres both allow multiple NULLs in a
unique index, so non-lesson usages (lesson_id IS NULL) are unaffected.

Revision ID: sub_usage_lesson_unique
Revises: ac_m3_student_parent_name
Create Date: 2026-06-15 11:00:00
"""

from __future__ import annotations

from alembic import op

revision: str = "sub_usage_lesson_unique"
down_revision: str | None = "ac_m3_student_parent_name"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_index(
        "uq_subscription_usage_lesson_id",
        "subscription_usages",
        ["lesson_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("uq_subscription_usage_lesson_id", table_name="subscription_usages")
