"""add_membership_travel_time

Revision ID: add_membership_travel_time
Revises: beta_backend_contract_fixes
Create Date: 2026-05-31 18:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_membership_travel_time"
down_revision: str | None = "beta_backend_contract_fixes"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def upgrade() -> None:
    if "travel_time_minutes" in _columns("class_memberships"):
        return

    op.add_column(
        "class_memberships",
        sa.Column("travel_time_minutes", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    if "travel_time_minutes" not in _columns("class_memberships"):
        return

    op.drop_column("class_memberships", "travel_time_minutes")
