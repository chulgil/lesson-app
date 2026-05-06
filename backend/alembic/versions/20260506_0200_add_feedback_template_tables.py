"""Add normalized feedback template tables.

Revision ID: add_feedback_template_tables
Revises: align_schedule_confirmation_status_enum
Create Date: 2026-05-06 02:00:00.000000
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "add_feedback_template_tables"
down_revision: str | None = "align_schedule_confirmation_status_enum"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


feedback_category_enum = sa.Enum(
    "technique",
    "musicality",
    "practice",
    "attitude",
    "general",
    name="feedbackcategory",
)


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        feedback_category_enum.create(bind, checkfirst=True)

    op.create_table(
        "feedback_templates",
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("category", feedback_category_enum, nullable=False),
        sa.Column("usage_count", sa.Integer(), nullable=False),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_feedback_template_teacher", "feedback_templates", ["teacher_id"], unique=False)
    op.create_index(
        "idx_feedback_template_category",
        "feedback_templates",
        ["teacher_id", "category"],
        unique=False,
    )
    op.create_index(
        "idx_feedback_template_usage",
        "feedback_templates",
        ["teacher_id", "usage_count"],
        unique=False,
    )

    op.create_table(
        "feedback_template_tags",
        sa.Column("template_id", sa.String(length=36), nullable=False),
        sa.Column("tag", sa.String(length=80), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.ForeignKeyConstraint(
            ["template_id"],
            ["feedback_templates.id"],
            name="fk_feedback_template_tags_template_id_feedback_templates",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "uk_feedback_template_tag",
        "feedback_template_tags",
        ["template_id", "tag"],
        unique=True,
    )
    op.create_index(
        "idx_feedback_template_tag_tag",
        "feedback_template_tags",
        ["tag"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("idx_feedback_template_tag_tag", table_name="feedback_template_tags")
    op.drop_index("uk_feedback_template_tag", table_name="feedback_template_tags")
    op.drop_table("feedback_template_tags")

    op.drop_index("idx_feedback_template_usage", table_name="feedback_templates")
    op.drop_index("idx_feedback_template_category", table_name="feedback_templates")
    op.drop_index("idx_feedback_template_teacher", table_name="feedback_templates")
    op.drop_table("feedback_templates")

    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        feedback_category_enum.drop(bind, checkfirst=True)
