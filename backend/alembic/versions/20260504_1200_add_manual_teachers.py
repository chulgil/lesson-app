"""add_manual_teachers

Create manual teacher records for student-owned offline teacher profiles.

Revision ID: add_manual_teachers
Revises: 18e537a2c493
Create Date: 2026-05-04 12:00:00.000000+00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "add_manual_teachers"
down_revision: str | None = "18e537a2c493"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "manual_teachers",
        sa.Column("owner_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("instrument", sa.String(length=80), nullable=True),
        sa.Column("phone", sa.String(length=40), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("profile_color_value", sa.Integer(), nullable=True),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_manual_teachers_owner_id"), "manual_teachers", ["owner_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_manual_teachers_owner_id"), table_name="manual_teachers")
    op.drop_table("manual_teachers")
