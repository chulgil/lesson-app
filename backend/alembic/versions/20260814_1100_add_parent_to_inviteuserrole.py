"""Add 'parent' value to the inviteuserrole native enum.

#1275 — ConnectionRequest.requester_role/target_role (native PG enum
``inviteuserrole``) only defined teacher/student, so a parent redeeming a
parent-target invite (#1267) could never complete ``create_connection_request``
— the write raised ``invalid input value for enum inviteuserrole: "parent"``
on Postgres (SQLite tests never caught this; enums are TEXT there).

Follows the established ``ALTER TYPE ... ADD VALUE IF NOT EXISTS`` pattern
from ``add_missing_native_enum_values`` — idempotent, Postgres-only, no
downgrade (Postgres cannot drop enum values without recreating the type).

Revision ID: add_parent_to_inviteuserrole
Revises: add_invite_target_role
Create Date: 2026-08-14 11:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_parent_to_inviteuserrole"
down_revision: str | None = "add_invite_target_role"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        # SQLite (tests) stores enums as TEXT — nothing to alter.
        return
    op.execute("ALTER TYPE inviteuserrole ADD VALUE IF NOT EXISTS 'parent'")


def downgrade() -> None:
    # PostgreSQL cannot drop enum values without recreating the type and rewriting data.
    pass
