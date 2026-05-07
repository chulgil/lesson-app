"""Track lesson booking origin (manual vs subscription-generated).

Revision ID: add_booking_subscription_origin
Revises: add_schedule_availability_time_constraints
Create Date: 2026-05-08 09:00:00.000000
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "add_booking_subscription_origin"
down_revision: str | None = "add_schedule_availability_time_constraints"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("lesson_bookings") as batch_op:
        batch_op.add_column(sa.Column("subscription_id", sa.String(36), nullable=True))
        batch_op.create_index("idx_booking_subscription", ["subscription_id"])
        batch_op.create_foreign_key(
            "fk_lesson_bookings_subscription_id_subscriptions",
            "subscriptions",
            ["subscription_id"],
            ["id"],
            ondelete="SET NULL",
        )


def downgrade() -> None:
    with op.batch_alter_table("lesson_bookings") as batch_op:
        batch_op.drop_constraint(
            "fk_lesson_bookings_subscription_id_subscriptions",
            type_="foreignkey",
        )
        batch_op.drop_index("idx_booking_subscription")
        batch_op.drop_column("subscription_id")
