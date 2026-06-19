"""merge branched heads: enum drift 858 + min booking hours

Revision ID: merge_0619_heads
Revises: min_booking_hours_default_zero, resolve_enum_drift_858
Create Date: 2026-06-19 08:52:22.881879+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'merge_0619_heads'
down_revision: Union[str, None] = ('min_booking_hours_default_zero', 'resolve_enum_drift_858')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
