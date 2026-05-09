"""Add app_versions, app_news, app_roadmap tables for R6 trust-building.

Revision ID: add_app_version_tables
Revises: add_parent_user_fk
Create Date: 2026-05-10 14:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_app_version_tables"
down_revision: str | None = "add_parent_user_fk"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "app_versions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("platform", sa.String(length=20), nullable=False),
        sa.Column("latest_version", sa.String(length=20), nullable=False),
        sa.Column("min_version", sa.String(length=20), nullable=False),
        sa.Column("release_notes", sa.Text(), nullable=True),
        sa.Column(
            "published_at", sa.DateTime(timezone=True), nullable=False
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
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_app_versions_platform", "app_versions", ["platform"])

    op.create_table(
        "app_news",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("link", sa.String(length=500), nullable=True),
        sa.Column(
            "published_at", sa.DateTime(timezone=True), nullable=False
        ),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
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
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_app_news_published", "app_news", ["published_at"])

    op.create_table(
        "app_roadmap",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column(
            "status", sa.String(length=20), nullable=False, server_default="planned"
        ),
        sa.Column(
            "display_order", sa.Integer(), nullable=False, server_default="0"
        ),
        sa.Column("target_date", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
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
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_app_roadmap_order", "app_roadmap", ["display_order"]
    )


def downgrade() -> None:
    op.drop_index("idx_app_roadmap_order", table_name="app_roadmap")
    op.drop_table("app_roadmap")
    op.drop_index("idx_app_news_published", table_name="app_news")
    op.drop_table("app_news")
    op.drop_index("idx_app_versions_platform", table_name="app_versions")
    op.drop_table("app_versions")
