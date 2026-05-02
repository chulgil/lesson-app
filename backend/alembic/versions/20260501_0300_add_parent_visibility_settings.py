"""Add parent visibility settings.

Revision ID: add_parent_visibility_settings
Revises: add_relation_practice_permissions
Create Date: 2026-05-01 03:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_parent_visibility_settings"
down_revision: str | None = "add_relation_practice_permissions"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "parent_visibility_settings",
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("student_id", sa.String(length=36), nullable=False),
        sa.Column("can_view_schedule", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("can_view_assignments", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("can_view_practice", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("can_view_lesson_notes", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("can_view_recordings", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("can_view_detailed_feedback", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("can_view_chat", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "uk_parent_visibility_teacher_student",
        "parent_visibility_settings",
        ["teacher_id", "student_id"],
        unique=True,
    )
    op.create_index(
        "idx_parent_visibility_student",
        "parent_visibility_settings",
        ["student_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("idx_parent_visibility_student", table_name="parent_visibility_settings")
    op.drop_index("uk_parent_visibility_teacher_student", table_name="parent_visibility_settings")
    op.drop_table("parent_visibility_settings")
