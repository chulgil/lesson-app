"""Add onboarding quest progress.

Revision ID: add_onboarding_quest_progress
Revises: add_recording_feedbacks
Create Date: 2026-05-07 05:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_onboarding_quest_progress"
down_revision: str | None = "add_recording_feedbacks"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "user_onboarding_progress",
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("current_phase", sa.String(length=40), nullable=False),
        sa.Column("profile_completeness", sa.Integer(), nullable=False),
        sa.Column("walkthrough_skipped", sa.Boolean(), nullable=False),
        sa.Column("coach_marks_seen", sa.JSON(), nullable=False),
        sa.Column("coach_marks_dismissed", sa.JSON(), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "uk_user_onboarding_progress_user",
        "user_onboarding_progress",
        ["user_id"],
        unique=True,
    )

    op.create_table(
        "user_onboarding_quest_progress",
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("quest_id", sa.String(length=100), nullable=False),
        sa.Column("status", sa.String(length=40), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "uk_user_onboarding_quest_user_quest",
        "user_onboarding_quest_progress",
        ["user_id", "quest_id"],
        unique=True,
    )
    op.create_index(
        "idx_user_onboarding_quest_user",
        "user_onboarding_quest_progress",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("idx_user_onboarding_quest_user", table_name="user_onboarding_quest_progress")
    op.drop_index("uk_user_onboarding_quest_user_quest", table_name="user_onboarding_quest_progress")
    op.drop_table("user_onboarding_quest_progress")
    op.drop_index("uk_user_onboarding_progress_user", table_name="user_onboarding_progress")
    op.drop_table("user_onboarding_progress")
