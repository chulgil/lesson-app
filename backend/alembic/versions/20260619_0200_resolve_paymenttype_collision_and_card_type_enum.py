"""Resolve paymenttype type-name collision + convert card_type to native enum.

Revision ID: resolve_enum_drift_858
Revises: add_missing_native_enum_values
Create Date: 2026-06-19 02:00:00.000000

Closes the two deeper enum drifts surfaced by test_alembic_postgres_validation.py
(#858):

1. ``paymenttype`` collision — ``payment.py PaymentType`` (trial/regular, used by
   ``payments.type``) and ``lesson.py PaymentType`` (organization/parent, used by
   ``lessons.payment_type``) both auto-mapped to the single PG type ``paymenttype``.
   The initial migration created it as (organization, parent), so ``payments.type``
   could not store trial/regular → latent 500. Give ``payments.type`` a distinct
   type ``paymentcategorytype`` (model now sets name= explicitly).

2. ``schedule_confirmation_cards.card_type`` — model declares a native enum but the
   column is still VARCHAR(30) (no ``confirmationcardtype`` type). Convert it.

Both tables are empty on beta (verified), so the ``USING`` casts are trivially safe.
CREATE TYPE / ALTER COLUMN TYPE are transaction-safe on Postgres.
"""

from collections.abc import Sequence

from alembic import op

revision: str = "resolve_enum_drift_858"
down_revision: str | None = "add_missing_native_enum_values"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        # SQLite (tests) stores enums as TEXT — no native type/column conversion.
        return

    # 1) payments.type → distinct type paymentcategorytype (trial/regular).
    op.execute("CREATE TYPE paymentcategorytype AS ENUM ('trial', 'regular')")
    op.execute("ALTER TABLE payments ALTER COLUMN type TYPE paymentcategorytype USING type::text::paymentcategorytype")

    # 2) schedule_confirmation_cards.card_type VARCHAR(30) → confirmationcardtype.
    #    Drop the server_default (model has only a Python-side default) before the
    #    type change, matching the model.
    op.execute("CREATE TYPE confirmationcardtype AS ENUM ('afterTrial', 'reEnrollment', 'additionalInstrument')")
    op.execute("ALTER TABLE schedule_confirmation_cards ALTER COLUMN card_type DROP DEFAULT")
    op.execute(
        "ALTER TABLE schedule_confirmation_cards ALTER COLUMN card_type "
        "TYPE confirmationcardtype USING card_type::confirmationcardtype"
    )


def downgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return

    op.execute("ALTER TABLE schedule_confirmation_cards ALTER COLUMN card_type TYPE VARCHAR(30) USING card_type::text")
    op.execute("ALTER TABLE schedule_confirmation_cards ALTER COLUMN card_type SET DEFAULT 'afterTrial'")
    op.execute("DROP TYPE confirmationcardtype")

    op.execute("ALTER TABLE payments ALTER COLUMN type TYPE paymenttype USING type::text::paymenttype")
    op.execute("DROP TYPE paymentcategorytype")
