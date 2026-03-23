"""Frontend-backend alignment — add missing columns and update schemas.

Revision ID: 0005
Revises: 0004
Create Date: 2026-03-23 00:00:00.000000+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0005'
down_revision: Union[str, None] = '0004'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # -----------------------------------------------------------------------
    # lesson_locations — add missing columns
    # -----------------------------------------------------------------------
    op.add_column('lesson_locations', sa.Column('owner_id', sa.String(36), nullable=True))
    op.add_column('lesson_locations', sa.Column('address_detail', sa.String(200), nullable=True))
    op.add_column('lesson_locations', sa.Column('online_link', sa.Text(), nullable=True))
    op.add_column('lesson_locations', sa.Column('is_default', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('lesson_locations', sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('lesson_locations', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True))
    op.create_index('idx_location_owner', 'lesson_locations', ['owner_id'])

    # -----------------------------------------------------------------------
    # teacher_student_relations — add tracking columns
    # -----------------------------------------------------------------------
    op.add_column('teacher_student_relations', sa.Column('active_subscription_id', sa.String(36), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('last_subscription_expired_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('expired_until', sa.DateTime(timezone=True), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('trial_booking_id', sa.String(36), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('total_lesson_count', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('teacher_student_relations', sa.Column('last_lesson_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('is_manually_registered', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('teacher_student_relations', sa.Column('is_app_connected', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('teacher_student_relations', sa.Column('app_connected_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('last_lesson_day', sa.String(10), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('last_lesson_time', sa.String(5), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('last_lesson_duration', sa.Integer(), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('schedule_recorded_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('terminated_by', sa.String(36), nullable=True))
    op.add_column('teacher_student_relations', sa.Column('termination_reason', sa.Text(), nullable=True))

    # Update RelationStatus enum to include new values
    # Note: PostgreSQL enum types need ALTER TYPE for new values
    op.execute("ALTER TYPE relationstatus ADD VALUE IF NOT EXISTS 'trialBooked'")
    op.execute("ALTER TYPE relationstatus ADD VALUE IF NOT EXISTS 'expired'")
    op.execute("ALTER TYPE relationstatus ADD VALUE IF NOT EXISTS 'past'")


def downgrade() -> None:
    # teacher_student_relations
    op.drop_column('teacher_student_relations', 'termination_reason')
    op.drop_column('teacher_student_relations', 'terminated_by')
    op.drop_column('teacher_student_relations', 'schedule_recorded_at')
    op.drop_column('teacher_student_relations', 'last_lesson_duration')
    op.drop_column('teacher_student_relations', 'last_lesson_time')
    op.drop_column('teacher_student_relations', 'last_lesson_day')
    op.drop_column('teacher_student_relations', 'app_connected_at')
    op.drop_column('teacher_student_relations', 'is_app_connected')
    op.drop_column('teacher_student_relations', 'is_manually_registered')
    op.drop_column('teacher_student_relations', 'last_lesson_at')
    op.drop_column('teacher_student_relations', 'total_lesson_count')
    op.drop_column('teacher_student_relations', 'trial_booking_id')
    op.drop_column('teacher_student_relations', 'expired_until')
    op.drop_column('teacher_student_relations', 'last_subscription_expired_at')
    op.drop_column('teacher_student_relations', 'active_subscription_id')

    # lesson_locations
    op.drop_index('idx_location_owner', table_name='lesson_locations')
    op.drop_column('lesson_locations', 'updated_at')
    op.drop_column('lesson_locations', 'is_active')
    op.drop_column('lesson_locations', 'is_default')
    op.drop_column('lesson_locations', 'online_link')
    op.drop_column('lesson_locations', 'address_detail')
    op.drop_column('lesson_locations', 'owner_id')
