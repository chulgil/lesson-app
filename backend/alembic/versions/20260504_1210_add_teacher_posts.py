"""add_teacher_posts

Create teacher_posts for follow feed announcements.

Revision ID: add_teacher_posts
Revises: add_manual_teachers
Create Date: 2026-05-04 12:10:00.000000+00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "add_teacher_posts"
down_revision: str | None = "add_manual_teachers"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "teacher_posts",
        sa.Column("author_id", sa.String(length=36), nullable=False),
        sa.Column("author_name", sa.String(length=120), nullable=False),
        sa.Column("post_type", sa.Enum("performance", "event", "notice", name="posttype"), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_teacher_posts_author", "teacher_posts", ["author_id"], unique=False)
    op.create_index("idx_teacher_posts_created", "teacher_posts", ["created_at"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_teacher_posts_created", table_name="teacher_posts")
    op.drop_index("idx_teacher_posts_author", table_name="teacher_posts")
    op.drop_table("teacher_posts")
    if op.get_context().dialect.name == "postgresql":
        sa.Enum("performance", "event", "notice", name="posttype").drop(op.get_bind(), checkfirst=True)
