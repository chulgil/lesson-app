"""add_lesson_student_note_subscription_id

Add student_note and subscription_id columns to lessons table.
Aligns with Flutter Lesson entity fields.

Revision ID: 18e537a2c493
Revises: a0204bd2ab2c
Create Date: 2026-05-04 11:10:54.315591+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '18e537a2c493'
down_revision: Union[str, None] = 'a0204bd2ab2c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("lessons", sa.Column("student_note", sa.Text(), nullable=True))
    op.add_column("lessons", sa.Column("subscription_id", sa.String(36), nullable=True))


def downgrade() -> None:
    op.drop_column("lessons", "subscription_id")
    op.drop_column("lessons", "student_note")
