"""Issue #1217 — add resource_type discriminator to share_tokens for growth-report previews.

Adds ``resource_type`` (default ``lesson_summary``, backfills existing rows)
and relaxes ``lesson_id`` to nullable so a share token can also scope a
student's growth-report preview (no single lesson). Plain string column with
a CheckConstraint — not a native PG enum — to avoid the ALTER TYPE ADD VALUE
migration risk documented for other native enums in this codebase.

Revision ID: add_growth_report_share
Revises: add_cancellation_defaults
Create Date: 2026-07-30 10:00:00.000000
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_growth_report_share"
down_revision: str | None = "add_cancellation_defaults"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def upgrade() -> None:
    share_columns = _columns("share_tokens")
    with op.batch_alter_table("share_tokens") as batch_op:
        if "resource_type" not in share_columns:
            batch_op.add_column(
                sa.Column(
                    "resource_type",
                    sa.String(length=30),
                    nullable=False,
                    server_default="lesson_summary",
                ),
            )
        batch_op.alter_column("lesson_id", existing_type=sa.String(length=36), nullable=True)
        batch_op.create_check_constraint(
            "ck_share_tokens_resource_type_valid",
            "resource_type IN ('lesson_summary', 'growth_report')",
        )
        batch_op.create_check_constraint(
            "ck_share_tokens_growth_report_requires_student",
            "resource_type != 'growth_report' OR student_id IS NOT NULL",
        )


def downgrade() -> None:
    with op.batch_alter_table("share_tokens") as batch_op:
        batch_op.drop_constraint("ck_share_tokens_growth_report_requires_student", type_="check")
        batch_op.drop_constraint("ck_share_tokens_resource_type_valid", type_="check")
        batch_op.alter_column("lesson_id", existing_type=sa.String(length=36), nullable=False)
        batch_op.drop_column("resource_type")
