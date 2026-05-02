"""Add subscription renewal alert days set.

Revision ID: add_subscription_alert_days_set
Revises: align_parent_api_spec
Create Date: 2026-05-03 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_subscription_alert_days_set"
down_revision: str | None = "align_parent_api_spec"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "subscription_settings",
        sa.Column("renewal_alert_days_set", sa.JSON(), nullable=True),
    )
    op.execute(
        sa.text(
            "UPDATE subscription_settings "
            "SET renewal_alert_days_set = '[14, 7, 1, 0]' "
            "WHERE renewal_alert_days_set IS NULL"
        )
    )


def downgrade() -> None:
    op.drop_column("subscription_settings", "renewal_alert_days_set")
