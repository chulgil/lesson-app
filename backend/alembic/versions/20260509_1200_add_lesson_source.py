"""add_lesson_source_and_subscription_fk_to_lessons

Track lesson origin source and strengthen lessons-subscriptions FK/index contract.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op


revision: str = "add_lesson_source"
down_revision: str | None = "add_schedule_exception_owner_scope"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    lesson_source = sa.Enum("manual", "subscriptionGenerated", name="lessonsource")
    if op.get_context().dialect.name == "postgresql":
        lesson_source.create(op.get_bind(), checkfirst=True)

    with op.batch_alter_table("lessons") as batch_op:
        batch_op.add_column(
            sa.Column(
                "lesson_source",
                lesson_source,
                nullable=False,
                server_default="manual",
            )
        )
        batch_op.create_index("idx_lesson_source", ["lesson_source"])
        batch_op.create_index("idx_lesson_subscription", ["subscription_id"])
        batch_op.create_foreign_key(
            "fk_lessons_subscription_id_subscriptions",
            "subscriptions",
            ["subscription_id"],
            ["id"],
            ondelete="SET NULL",
        )


def downgrade() -> None:
    with op.batch_alter_table("lessons") as batch_op:
        batch_op.drop_constraint(
            "fk_lessons_subscription_id_subscriptions", type_="foreignkey"
        )
        batch_op.drop_index("idx_lesson_subscription")
        batch_op.drop_index("idx_lesson_source")
        batch_op.drop_column("lesson_source")

    lesson_source = sa.Enum("manual", "subscriptionGenerated", name="lessonsource")
    if op.get_context().dialect.name == "postgresql":
        lesson_source.drop(op.get_bind(), checkfirst=True)
