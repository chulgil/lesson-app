"""Phase 27 — reschedule check constraint 에 bonus_reschedule_count 합산.

spec subscription_edit_spec.md §7.1 — effective allowance = total + bonus.
이전 constraint: used <= total. 신규: used <= total + bonus.

Revision ID: reschedule_check_bonus
Revises: subscription_edit_phase24
Create Date: 2026-06-09 05:00:00
"""

from __future__ import annotations

from alembic import op

revision: str = "reschedule_check_bonus"
down_revision: str | None = "subscription_edit_phase24"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.drop_constraint("ck_subscriptions_reschedule_counter_capacity", type_="check")
        batch_op.create_check_constraint(
            "ck_subscriptions_reschedule_counter_capacity",
            "used_reschedule_count <= total_reschedule_allowance + bonus_reschedule_count",
        )


def downgrade() -> None:
    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.drop_constraint("ck_subscriptions_reschedule_counter_capacity", type_="check")
        batch_op.create_check_constraint(
            "ck_subscriptions_reschedule_counter_capacity",
            "used_reschedule_count <= total_reschedule_allowance",
        )
