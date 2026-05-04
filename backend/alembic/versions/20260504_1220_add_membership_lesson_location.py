"""add_membership_lesson_location

Revision ID: add_membership_lesson_location
Revises: add_teacher_posts
Create Date: 2026-05-04 12:20:00.000000+00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "add_membership_lesson_location"
down_revision: str | None = "add_teacher_posts"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("class_memberships", sa.Column("lesson_location_id", sa.String(length=36), nullable=True))
    op.create_index("idx_membership_location", "class_memberships", ["lesson_location_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_membership_location", table_name="class_memberships")
    op.drop_column("class_memberships", "lesson_location_id")
