"""Add recording feedbacks.

Revision ID: add_recording_feedbacks
Revises: add_class_scoped_lesson_policies
Create Date: 2026-05-07 04:10:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_recording_feedbacks"
down_revision: str | None = "add_class_scoped_lesson_policies"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "recording_feedbacks",
        sa.Column("recording_id", sa.String(length=36), nullable=False),
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(
            ["recording_id"],
            ["practice_recordings.id"],
            name="fk_recording_feedbacks_recording_id_practice_recordings",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["teacher_id"],
            ["teachers.id"],
            name="fk_recording_feedbacks_teacher_id_teachers",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_recording_feedback_recording",
        "recording_feedbacks",
        ["recording_id"],
        unique=False,
    )
    op.create_index(
        "idx_recording_feedback_teacher",
        "recording_feedbacks",
        ["teacher_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("idx_recording_feedback_teacher", table_name="recording_feedbacks")
    op.drop_index("idx_recording_feedback_recording", table_name="recording_feedbacks")
    op.drop_table("recording_feedbacks")
