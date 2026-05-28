"""Add share_tokens table for R2 public sharing feature.

Revision ID: add_share_token
Revises: add_vacation_mode_to_availability
Create Date: 2026-05-28 10:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_share_token"
down_revision: str | None = "add_vacation_mode_to_availability"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "share_tokens",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("token", sa.String(length=64), nullable=False, unique=True),
        sa.Column("scope", sa.String(length=50), nullable=False),
        sa.Column("target_id", sa.String(length=36), nullable=False),
        sa.Column("created_by_user_id", sa.String(length=36), nullable=True),
        sa.Column(
            "expires_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_share_token_token", "share_tokens", ["token"])
    op.create_index("idx_share_token_expires", "share_tokens", ["expires_at"])
    op.create_index(
        "idx_share_token_scope_target",
        "share_tokens",
        ["scope", "target_id"],
    )


def downgrade() -> None:
    op.drop_index("idx_share_token_scope_target", table_name="share_tokens")
    op.drop_index("idx_share_token_expires", table_name="share_tokens")
    op.drop_index("idx_share_token_token", table_name="share_tokens")
    op.drop_table("share_tokens")
