"""add onboarding_completed to users

Revision ID: 0004
Revises: 0003
Create Date: 2026-03-17 00:00:00.000000+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0004'
down_revision: Union[str, None] = '0003'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'users',
        sa.Column('onboarding_completed', sa.Boolean(), nullable=False, server_default='false'),
    )
    # Mark existing users with a role as onboarding-completed
    op.execute("UPDATE users SET onboarding_completed = true WHERE role IS NOT NULL")


def downgrade() -> None:
    op.drop_column('users', 'onboarding_completed')
