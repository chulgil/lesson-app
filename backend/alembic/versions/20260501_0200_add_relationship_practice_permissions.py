"""Add practice visibility permissions to teacher-student relations.

Revision ID: add_relation_practice_permissions
Revises: add_recording_owner_file_key
Create Date: 2026-05-01 02:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_relation_practice_permissions"
down_revision: str | None = "add_recording_owner_file_key"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "teacher_student_relations",
        sa.Column("can_view_practice", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "teacher_student_relations",
        sa.Column("can_comment", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "teacher_student_relations",
        sa.Column("can_suggest_assignments", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    bind = op.get_bind()
    if bind.dialect.name != "sqlite":
        op.alter_column("teacher_student_relations", "can_view_practice", server_default=None)
        op.alter_column("teacher_student_relations", "can_comment", server_default=None)
        op.alter_column("teacher_student_relations", "can_suggest_assignments", server_default=None)


def downgrade() -> None:
    op.drop_column("teacher_student_relations", "can_suggest_assignments")
    op.drop_column("teacher_student_relations", "can_comment")
    op.drop_column("teacher_student_relations", "can_view_practice")
