"""Backup lesson_schedule_changes before deprecation — Plan A Phase 1

Revision ID: backup_lsc_legacy
Revises: add_sub_expiry_dispatch_log
Create Date: 2026-04-30 00:00:00.000000

Plan A SSOT (Issue #235):
- request_events table is the new SSOT for lesson request chat history
  (introduced in revision `add_request_events`).
- lesson_schedule_changes is the legacy table — still used by
  schedule_ext_service for now, but no API endpoint exposes it.
- This migration creates a non-destructive backup table so we can safely
  drop the legacy in a follow-up migration after the 14-day verification
  window (Plan A Phase 4).

Why backup instead of row-level migration:
- lesson_schedule_changes has no request_id column, so rows cannot be
  re-keyed into request_events without a manual mapping pass.
- We preserve every legacy row in `lesson_schedule_changes_legacy_backup`
  so a future migration can mine them with full context if needed.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "backup_lsc_legacy"
down_revision: str | None = "add_sub_expiry_dispatch_log"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Create backup table mirroring lesson_schedule_changes schema and rows.

    Postgres CTAS preserves both schema and data in a single statement.
    SQLite (test) lacks CTAS-with-data semantics for non-trivial types,
    so we fall back to schema-only when not on Postgres — backups are
    only meaningful on production data anyway.
    """
    bind = op.get_bind()
    dialect_name = bind.dialect.name

    if dialect_name == "postgresql":
        op.execute(
            "CREATE TABLE IF NOT EXISTS lesson_schedule_changes_legacy_backup "
            "AS TABLE lesson_schedule_changes WITH DATA"
        )
        op.execute(
            "COMMENT ON TABLE lesson_schedule_changes_legacy_backup IS "
            "'Plan A Phase 1 backup (2026-04-30). Source: lesson_schedule_changes. "
            "Drop source after Phase 4 cutover (>= 2026-05-14).'"
        )
    else:
        op.create_table(
            "lesson_schedule_changes_legacy_backup",
            sa.Column("id", sa.String(length=36), primary_key=True),
            sa.Column("student_id", sa.String(length=36), nullable=False),
            sa.Column("teacher_id", sa.String(length=36), nullable=False),
            sa.Column("change_type", sa.String(length=20), nullable=False),
            sa.Column("previous_day_of_week", sa.Integer(), nullable=True),
            sa.Column("previous_time", sa.String(length=5), nullable=True),
            sa.Column("new_day_of_week", sa.Integer(), nullable=True),
            sa.Column("new_time", sa.String(length=5), nullable=True),
            sa.Column("effective_from", sa.Date(), nullable=False),
            sa.Column("status", sa.String(length=20), nullable=False),
            sa.Column(
                "requested_at",
                sa.DateTime(timezone=True),
                server_default=sa.func.now(),
                nullable=False,
            ),
            sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("request_reason", sa.Text(), nullable=True),
            sa.Column("response_message", sa.Text(), nullable=True),
            sa.Column("requested_by", sa.String(length=36), nullable=True),
        )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS lesson_schedule_changes_legacy_backup")
