"""Add group_class_members table — cohort roster (J4, spec §2 P2-4).

Teacher-assigned fixed roster for regular (cohort) group classes. Capacity is
enforced in the service layer against ``group_classes.max_capacity``; the
unique index blocks duplicate assignment at the DB level.

Revision ID: add_group_class_members
Revises: add_refund_requests
Create Date: 2026-08-18 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_group_class_members"
down_revision: str | None = "add_refund_requests"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "group_class_members",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("group_class_id", sa.String(36), nullable=False),
        sa.Column("student_id", sa.String(36), nullable=False),
        sa.Column("added_by", sa.String(36), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("uk_gcm_class_student", "group_class_members", ["group_class_id", "student_id"], unique=True)
    op.create_index("idx_gcm_student", "group_class_members", ["student_id"])


def downgrade() -> None:
    op.drop_index("idx_gcm_student", table_name="group_class_members")
    op.drop_index("uk_gcm_class_student", table_name="group_class_members")
    op.drop_table("group_class_members")
