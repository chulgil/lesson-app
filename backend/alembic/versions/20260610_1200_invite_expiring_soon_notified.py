"""Issue #633 — AcademyInvite.expiring_soon_notified_at 컬럼 추가.

Revision ID: invite_expiring_soon_notif
Revises: invite_declined_reason
Create Date: 2026-06-10 12:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "invite_expiring_soon_notif"
down_revision: str | None = "invite_declined_reason"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "academy_invites",
        sa.Column("expiring_soon_notified_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("academy_invites", "expiring_soon_notified_at")
