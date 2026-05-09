"""add_lesson_summary_share_tokens

Add token storage for Ghost-rendered public lesson summary pages.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_lesson_summary_share_tokens"
down_revision: str | None = "add_app_version_tables"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "lesson_summary_share_tokens",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("lesson_id", sa.String(length=36), nullable=False),
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("student_id", sa.String(length=36), nullable=True),
        sa.Column("token_hash", sa.String(length=128), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_accessed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("access_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint(
            "access_count >= 0",
            name="ck_lesson_summary_share_tokens_access_count_non_negative",
        ),
        sa.ForeignKeyConstraint(
            ["lesson_id"],
            ["lessons.id"],
            name="fk_lesson_summary_share_tokens_lesson_id_lessons",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["teacher_id"],
            ["users.id"],
            name="fk_lesson_summary_share_tokens_teacher_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["student_id"],
            ["students.id"],
            name="fk_lesson_summary_share_tokens_student_id_students",
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash", name="uq_lesson_summary_share_tokens_token_hash"),
    )
    op.create_index(
        "idx_lesson_summary_share_tokens_lesson",
        "lesson_summary_share_tokens",
        ["lesson_id"],
    )
    op.create_index(
        "idx_lesson_summary_share_tokens_teacher",
        "lesson_summary_share_tokens",
        ["teacher_id"],
    )
    op.create_index(
        "idx_lesson_summary_share_tokens_expires",
        "lesson_summary_share_tokens",
        ["expires_at"],
    )


def downgrade() -> None:
    op.drop_index("idx_lesson_summary_share_tokens_expires", table_name="lesson_summary_share_tokens")
    op.drop_index("idx_lesson_summary_share_tokens_teacher", table_name="lesson_summary_share_tokens")
    op.drop_index("idx_lesson_summary_share_tokens_lesson", table_name="lesson_summary_share_tokens")
    op.drop_table("lesson_summary_share_tokens")
