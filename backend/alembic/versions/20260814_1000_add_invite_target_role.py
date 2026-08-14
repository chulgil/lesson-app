"""Add target_role to invites.

#1267 — invite QR/code generation can prebind a target role (teacher /
student / parent) so a scanning user skips manual role selection. Plain
nullable string column (not a native PG enum) — this project has been bitten
before by native enum `ALTER TYPE ADD VALUE` migrations, and a 4th target
role should never need one. Values are validated in the Pydantic schema.
Legacy invites keep target_role=NULL and existing behavior is unchanged.

Revision ID: add_invite_target_role
Revises: add_lesson_piece_recording_fks
Create Date: 2026-08-14 10:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_invite_target_role"
down_revision: str | None = "add_lesson_piece_recording_fks"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "invites",
        sa.Column("target_role", sa.String(length=20), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("invites", "target_role")
