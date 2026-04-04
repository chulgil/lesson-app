"""Add reschedule_deadline_hours to subscriptions

Revision ID: add_reschedule_deadline_hours
Revises: add_bank_account_change_logs
Create Date: 2026-04-04 11:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "add_reschedule_deadline_hours"
down_revision: Union[str, None] = "add_bank_account_change_logs"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "subscriptions",
        sa.Column("reschedule_deadline_hours", sa.Integer(), nullable=False, server_default="12"),
    )


def downgrade() -> None:
    op.drop_column("subscriptions", "reschedule_deadline_hours")
