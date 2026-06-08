"""merge practice_loop_stats and ac_m3_academy_announcements heads

Revision ID: merge_phase14_heads
Revises: practice_loop_stats, ac_m3_academy_announcements
Create Date: 2026-06-08 04:25:50.283822+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'merge_phase14_heads'
down_revision: Union[str, None] = ('practice_loop_stats', 'ac_m3_academy_announcements')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
