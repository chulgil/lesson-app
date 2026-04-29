"""Add reschedule_deadline_hours to subscriptions

Revision ID: add_reschedule_deadline_hours
Revises: e34fbc3ccb63
Create Date: 2026-04-04 11:00:00.000000

체인 복구 (#252, 2026-04-29): down_revision 을 fictional
`add_bank_account_change_logs` → 실제 head `e34fbc3ccb63`
(frontend_backend_schema_alignment_phase2) 로 정렬.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "add_reschedule_deadline_hours"
down_revision: str | None = "e34fbc3ccb63"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "subscriptions",
        sa.Column("reschedule_deadline_hours", sa.Integer(), nullable=False, server_default="12"),
    )


def downgrade() -> None:
    op.drop_column("subscriptions", "reschedule_deadline_hours")
