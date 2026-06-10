"""Issue #632 — AcademyInvite.declined_reason 컬럼 추가.

Revision ID: invite_declined_reason
Revises: settings_available_slots
Create Date: 2026-06-10 10:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "invite_declined_reason"
down_revision: str | None = "settings_available_slots"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "academy_invites",
        sa.Column("declined_reason", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("academy_invites", "declined_reason")
