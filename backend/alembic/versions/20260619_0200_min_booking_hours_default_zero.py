"""Relax teacher booking lead time: default min_booking_hours 24 -> 0 (#850).

Revision ID: min_booking_hours_default_zero
Revises: add_missing_native_enum_values
Create Date: 2026-06-19 02:00:00.000000

``teacher_settings.min_booking_hours`` shipped with ``server_default='24'`` but the
booking flow never enforced it (no slot/booking path read the value). #850 makes
the value authoritative: students can no longer book inside the window. To avoid
silently turning a 24h lock on for every existing teacher (who never opted in),
the default is relaxed to ``0`` (= no restriction) and existing rows still sitting
on the old default ``24`` are reset to ``0``. Only teachers who explicitly raise
the value opt into enforcement.

Migrations only run on Postgres here (tests build the schema with
``metadata.create_all``), so this is written for Postgres.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "min_booking_hours_default_zero"
down_revision: str | None = "add_missing_native_enum_values"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # SQLite cannot ALTER COLUMN SET DEFAULT (test_alembic_sqlite_upgrade
    # gate); the docstring's "Postgres only" intent needs the actual guard.
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return

    # Future rows: default 24 -> 0.
    op.alter_column(
        "teacher_settings",
        "min_booking_hours",
        existing_type=sa.Integer(),
        existing_nullable=False,
        server_default="0",
    )
    # Existing rows still on the never-enforced default 24 -> 0 (behavior preserved).
    op.execute("UPDATE teacher_settings SET min_booking_hours = 0 WHERE min_booking_hours = 24")


def downgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return

    # Restore the structural default only. The data reset (24 -> 0) is not
    # reversed: the original value is indistinguishable from a deliberate 0.
    op.alter_column(
        "teacher_settings",
        "min_booking_hours",
        existing_type=sa.Integer(),
        existing_nullable=False,
        server_default="24",
    )
