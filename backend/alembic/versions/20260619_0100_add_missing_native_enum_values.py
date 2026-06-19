"""Add native enum values present in models but missing from the Postgres types.

Revision ID: add_missing_native_enum_values
Revises: tmpl_regular_price
Create Date: 2026-06-19 01:00:00.000000

Hotfix for the recurring "added an enum member to the model/queries but forgot the
``ALTER TYPE ... ADD VALUE`` migration" class. SQLite tests never catch it (enums
are TEXT there); on Postgres any statement binding the value raises
``invalid input value for enum ...`` → HTTP 500 (blank screen).

- ``requesteventtype``: ``scheduleChangeExpired`` / ``scheduleChangeReminder`` —
  caused the teacher schedule tab 500 + the schedule-change expiry job crash (#80).
- ``bookinglessontype``: ``makeup`` — makeup bookings would 500 the same way.

Two deeper enum drifts (``paymenttype`` type-name collision, ``confirmationcardtype``
VARCHAR→enum conversion) need model changes + data-safe conversions and are tracked
separately, not value additions.
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_missing_native_enum_values"
down_revision: str | None = "tmpl_regular_price"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# pg enum type name -> values to ensure exist (ADD VALUE IF NOT EXISTS = idempotent).
MISSING_VALUES: dict[str, tuple[str, ...]] = {
    "requesteventtype": ("scheduleChangeExpired", "scheduleChangeReminder"),
    "bookinglessontype": ("makeup",),
}


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        # SQLite (tests) stores enums as TEXT — nothing to alter.
        return
    for type_name, values in MISSING_VALUES.items():
        for value in values:
            op.execute(f"ALTER TYPE {type_name} ADD VALUE IF NOT EXISTS '{value}'")


def downgrade() -> None:
    # PostgreSQL cannot drop enum values without recreating the type and rewriting data.
    pass
