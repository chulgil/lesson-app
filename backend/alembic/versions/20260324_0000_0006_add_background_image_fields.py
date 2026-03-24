"""Add background_image fields to teachers and students.

Revision ID: 0006
Revises: 0005
Create Date: 2026-03-24 00:00:00.000000+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0006'
down_revision: Union[str, None] = '0005'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('teachers', sa.Column('background_image', sa.Text(), nullable=True))
    op.add_column('students', sa.Column('background_image_url', sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column('students', 'background_image_url')
    op.drop_column('teachers', 'background_image')
