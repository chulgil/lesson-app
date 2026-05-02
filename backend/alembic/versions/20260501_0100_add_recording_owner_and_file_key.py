"""Add owner and object key columns to practice recordings.

Revision ID: add_recording_owner_file_key
Revises: drop_pg_fields
Create Date: 2026-05-01 01:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_recording_owner_file_key"
down_revision: str | None = "drop_pg_fields"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("practice_recordings", sa.Column("student_id", sa.String(length=36), nullable=True))
    op.add_column("practice_recordings", sa.Column("file_key", sa.Text(), nullable=True))
    op.create_index("idx_practice_rec_student", "practice_recordings", ["student_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_practice_rec_student", table_name="practice_recordings")
    op.drop_column("practice_recordings", "file_key")
    op.drop_column("practice_recordings", "student_id")
