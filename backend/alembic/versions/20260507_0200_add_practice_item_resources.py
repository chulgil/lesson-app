"""Add normalized practice item resources.

Revision ID: add_practice_item_resources
Revises: normalize_teaching_resource_tags
Create Date: 2026-05-07 02:00:00.000000
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "add_practice_item_resources"
down_revision: str | None = "normalize_teaching_resource_tags"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "practice_item_resources",
        sa.Column("item_id", sa.String(length=36), nullable=False),
        sa.Column("resource_id", sa.String(length=36), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.ForeignKeyConstraint(
            ["item_id"],
            ["practice_items.id"],
            name="fk_practice_item_resources_item_id_practice_items",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["resource_id"],
            ["teaching_resources.id"],
            name="fk_practice_item_resources_resource_id_teaching_resources",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "uk_practice_item_resource",
        "practice_item_resources",
        ["item_id", "resource_id"],
        unique=True,
    )
    op.create_index(
        "idx_practice_item_resource_resource",
        "practice_item_resources",
        ["resource_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("idx_practice_item_resource_resource", table_name="practice_item_resources")
    op.drop_index("uk_practice_item_resource", table_name="practice_item_resources")
    op.drop_table("practice_item_resources")
