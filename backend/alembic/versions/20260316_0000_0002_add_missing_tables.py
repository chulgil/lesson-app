"""add missing tables for frontend feature parity

Revision ID: 0002
Revises: 0001
Create Date: 2026-03-16 00:00:00.000000+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '0002'
down_revision: Union[str, None] = '0001'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- Invites ---
    op.create_table('invites',
        sa.Column('creator_id', sa.String(length=36), nullable=False),
        sa.Column('creator_name', sa.String(length=100), nullable=True),
        sa.Column('creator_role', sa.Enum('teacher', 'student', name='inviteuserrole', native_enum=True), nullable=False),
        sa.Column('invite_code', sa.String(length=10), nullable=False),
        sa.Column('invite_url', sa.Text(), nullable=False),
        sa.Column('qr_code_data', sa.Text(), nullable=False),
        sa.Column('status', sa.Enum('active', 'used', 'expired', 'revoked', name='invitestatus', native_enum=True), nullable=False),
        sa.Column('is_single_use', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('max_uses', sa.Integer(), nullable=True),
        sa.Column('use_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('invite_code'),
    )
    op.create_index('idx_invite_creator', 'invites', ['creator_id'])
    op.create_index('idx_invite_status', 'invites', ['status'])

    # --- Connection Requests ---
    op.create_table('connection_requests',
        sa.Column('requester_id', sa.String(length=36), nullable=False),
        sa.Column('requester_role', sa.Enum('teacher', 'student', name='inviteuserrole', native_enum=True, create_type=False), nullable=False),
        sa.Column('requester_name', sa.String(length=100), nullable=True),
        sa.Column('requester_profile_image', sa.Text(), nullable=True),
        sa.Column('target_id', sa.String(length=36), nullable=False),
        sa.Column('target_role', sa.Enum('teacher', 'student', name='inviteuserrole', native_enum=True, create_type=False), nullable=False),
        sa.Column('target_name', sa.String(length=100), nullable=True),
        sa.Column('target_profile_image', sa.Text(), nullable=True),
        sa.Column('method', sa.Enum('qrCode', 'urlLink', 'inviteCode', 'inAppSearch', name='invitemethod', native_enum=True), nullable=False),
        sa.Column('invite_id', sa.String(length=36), nullable=True),
        sa.Column('message', sa.Text(), nullable=True),
        sa.Column('status', sa.Enum('pending', 'accepted', 'rejected', 'cancelled', 'expired', name='connectionrequeststatus', native_enum=True), nullable=False),
        sa.Column('responded_at', sa.DateTime(), nullable=True),
        sa.Column('rejection_reason', sa.Text(), nullable=True),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_connreq_requester', 'connection_requests', ['requester_id'])
    op.create_index('idx_connreq_target', 'connection_requests', ['target_id'])
    op.create_index('idx_connreq_status', 'connection_requests', ['status'])

    # --- Connections ---
    op.create_table('connections',
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('teacher_name', sa.String(length=100), nullable=False),
        sa.Column('teacher_profile_image', sa.Text(), nullable=True),
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('student_name', sa.String(length=100), nullable=False),
        sa.Column('student_profile_image', sa.Text(), nullable=True),
        sa.Column('connection_request_id', sa.String(length=36), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('deactivated_at', sa.DateTime(), nullable=True),
        sa.Column('connected_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_connection', 'connections', ['teacher_id', 'student_id'], unique=True)
    op.create_index('idx_connection_active', 'connections', ['is_active'])

    # --- Gamification Points ---
    op.create_table('gamification_points',
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('points', sa.Integer(), nullable=False),
        sa.Column('type', sa.Enum('practiceComplete', 'streakBonus', 'lessonAttendance', 'goalAchieved', 'badgeEarned', name='pointtype', native_enum=True), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('earned_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_gam_points_student', 'gamification_points', ['student_id'])
    op.create_index('idx_gam_points_type', 'gamification_points', ['type'])

    # --- Gamification Badges ---
    op.create_table('gamification_badges',
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('badge_name', sa.String(length=100), nullable=False),
        sa.Column('badge_description', sa.Text(), nullable=False),
        sa.Column('badge_icon', sa.String(length=50), nullable=False),
        sa.Column('rarity', sa.Enum('common', 'rare', 'epic', 'legendary', name='badgerarity', native_enum=True), nullable=False),
        sa.Column('earned_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_badge_student_name', 'gamification_badges', ['student_id', 'badge_name'], unique=True)

    # --- Teacher Settings ---
    op.create_table('teacher_settings',
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('instruments', sa.JSON(), nullable=True),
        sa.Column('default_lesson_duration', sa.Integer(), nullable=False, server_default='60'),
        sa.Column('custom_lesson_durations', sa.JSON(), nullable=True),
        sa.Column('disabled_durations', sa.JSON(), nullable=True),
        sa.Column('break_time_between_lessons', sa.Integer(), nullable=False, server_default='10'),
        sa.Column('min_booking_hours', sa.Integer(), nullable=False, server_default='24'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_teacher_settings', 'teacher_settings', ['teacher_id'], unique=True)

    # --- Subscription Settings ---
    op.create_table('subscription_settings',
        sa.Column('teacher_id', sa.String(length=36), nullable=True),
        sa.Column('organization_id', sa.String(length=36), nullable=True),
        sa.Column('renewal_alert_threshold', sa.Integer(), nullable=False, server_default='2'),
        sa.Column('renewal_alert_days', sa.Integer(), nullable=False, server_default='7'),
        sa.Column('discount_policies', sa.JSON(), nullable=True),
        sa.Column('enable_push_notification', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('enable_badge', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('notify_parent', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_sub_settings_teacher', 'subscription_settings', ['teacher_id'], unique=True)

    # --- Proposal Settings ---
    op.create_table('proposal_settings',
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('auto_proposal_enabled', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('auto_proposal_template_ids', sa.JSON(), nullable=True),
        sa.Column('recommended_template_id', sa.String(length=36), nullable=True),
        sa.Column('golden_time_discount_percent', sa.Integer(), nullable=False, server_default='10'),
        sa.Column('golden_time_hours', sa.Integer(), nullable=False, server_default='72'),
        sa.Column('auto_reminder_enabled', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('reminder_hours', sa.JSON(), nullable=True),
        sa.Column('auto_renewal_enabled', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_proposal_settings_teacher', 'proposal_settings', ['teacher_id'], unique=True)

    # --- Notification Settings ---
    op.create_table('notification_settings',
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('target_user_id', sa.String(length=36), nullable=False),
        sa.Column('push_enabled', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('practice_share_enabled', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('lesson_reminder_enabled', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('payment_reminder_enabled', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_notif_settings', 'notification_settings', ['user_id', 'target_user_id'], unique=True)

    # --- Parent Notification Settings ---
    op.create_table('parent_notification_settings',
        sa.Column('parent_id', sa.String(length=36), nullable=False),
        sa.Column('payment_request', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('payment_complete', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('payment_due_soon', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('lesson_change', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('lesson_cancel', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('lesson_start', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('lesson_end', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('new_assignment', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('assignment_incomplete', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('practice_complete', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('streak_achievement', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('teacher_message', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('lesson_note_update', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('weekly_report', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('monthly_report', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_parent_notif_settings', 'parent_notification_settings', ['parent_id'], unique=True)

    # --- Feedback Presets ---
    op.create_table('feedback_presets',
        sa.Column('teacher_id', sa.String(length=36), nullable=True),
        sa.Column('text', sa.Text(), nullable=False),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_default', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('is_hidden', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_feedback_preset_teacher', 'feedback_presets', ['teacher_id'])

    # --- Teaching Resources ---
    op.create_table('teaching_resources',
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('type', sa.String(length=30), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('youtube_url', sa.Text(), nullable=True),
        sa.Column('youtube_video_id', sa.String(length=20), nullable=True),
        sa.Column('youtube_thumbnail', sa.Text(), nullable=True),
        sa.Column('youtube_start_seconds', sa.Integer(), nullable=True),
        sa.Column('youtube_end_seconds', sa.Integer(), nullable=True),
        sa.Column('audio_url', sa.Text(), nullable=True),
        sa.Column('audio_duration_seconds', sa.Integer(), nullable=True),
        sa.Column('external_url', sa.Text(), nullable=True),
        sa.Column('instrument', sa.String(length=50), nullable=True),
        sa.Column('tags', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_resource_teacher', 'teaching_resources', ['teacher_id'])

    # --- Teacher Reviews ---
    op.create_table('teacher_reviews',
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('teacher_name', sa.String(length=100), nullable=False),
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('student_name', sa.String(length=100), nullable=False),
        sa.Column('author_type', sa.Enum('student', 'parent', name='reviewauthortype', native_enum=True), nullable=False),
        sa.Column('author_id', sa.String(length=36), nullable=False),
        sa.Column('author_name', sa.String(length=100), nullable=False),
        sa.Column('rating', sa.Integer(), nullable=False),
        sa.Column('content', sa.Text(), nullable=True),
        sa.Column('tags', sa.JSON(), nullable=True),
        sa.Column('visibility', sa.Enum('public', 'teacherOnly', name='reviewvisibility', native_enum=True), nullable=False),
        sa.Column('is_anonymous', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('is_verified', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_review_teacher', 'teacher_reviews', ['teacher_id'])
    op.create_index('idx_review_student', 'teacher_reviews', ['student_id'])
    op.create_index('idx_review_active', 'teacher_reviews', ['is_active'])

    # --- Schedule Exceptions ---
    op.create_table('schedule_exceptions',
        sa.Column('teacher_availability_id', sa.String(length=36), nullable=False),
        sa.Column('type', sa.Enum('holiday', 'vacation', 'additionalSlot', name='exceptiontype', native_enum=True), nullable=False),
        sa.Column('start_date', sa.Date(), nullable=False),
        sa.Column('end_date', sa.Date(), nullable=False),
        sa.Column('start_time', sa.String(length=5), nullable=True),
        sa.Column('end_time', sa.String(length=5), nullable=True),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_sched_exc_avail', 'schedule_exceptions', ['teacher_availability_id'])
    op.create_index('idx_sched_exc_dates', 'schedule_exceptions', ['start_date', 'end_date'])

    # --- Group Class Schedules ---
    op.create_table('group_class_schedules',
        sa.Column('group_class_id', sa.String(length=36), nullable=False),
        sa.Column('start_time', sa.DateTime(), nullable=False),
        sa.Column('end_time', sa.DateTime(), nullable=False),
        sa.Column('status', sa.Enum('open', 'full', 'closed', 'cancelled', 'completed', 'inProgress', name='groupschedulestatus', native_enum=True), nullable=False),
        sa.Column('current_bookings', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('waitlist_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('max_capacity', sa.Integer(), nullable=False),
        sa.Column('waitlist_capacity', sa.Integer(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('cancel_reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_gcs_group_class', 'group_class_schedules', ['group_class_id'])
    op.create_index('idx_gcs_start', 'group_class_schedules', ['start_time'])
    op.create_index('idx_gcs_status', 'group_class_schedules', ['status'])

    # --- Group Class Bookings ---
    op.create_table('group_class_bookings',
        sa.Column('schedule_id', sa.String(length=36), nullable=False),
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('subscription_id', sa.String(length=36), nullable=True),
        sa.Column('status', sa.Enum('confirmed', 'waitlist', 'attended', 'noShow', 'cancelled', 'autoCancelled', name='groupbookingstatus', native_enum=True), nullable=False),
        sa.Column('waitlist_position', sa.Integer(), nullable=True),
        sa.Column('attended_at', sa.DateTime(), nullable=True),
        sa.Column('subscription_deducted', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('cancel_reason', sa.Text(), nullable=True),
        sa.Column('cancelled_at', sa.DateTime(), nullable=True),
        sa.Column('promoted_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_gcb_schedule_student', 'group_class_bookings', ['schedule_id', 'student_id'], unique=True)
    op.create_index('idx_gcb_student', 'group_class_bookings', ['student_id'])
    op.create_index('idx_gcb_status', 'group_class_bookings', ['status'])

    # --- No-Show Records ---
    op.create_table('no_show_records',
        sa.Column('lesson_id', sa.String(length=36), nullable=False),
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('lesson_date', sa.Date(), nullable=False),
        sa.Column('applied_policy', sa.Enum('deductCredit', 'halfCredit', 'noDeduction', 'reschedule', name='individualnoshowpolicy', native_enum=True), nullable=False),
        sa.Column('deducted_credits', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('makeup_lesson_id', sa.String(length=36), nullable=True),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('processed_by', sa.String(length=36), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_noshow_student', 'no_show_records', ['student_id'])
    op.create_index('idx_noshow_teacher', 'no_show_records', ['teacher_id'])
    op.create_index('idx_noshow_date', 'no_show_records', ['lesson_date'])

    # --- Lesson Schedule Changes ---
    op.create_table('lesson_schedule_changes',
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('change_type', sa.Enum('singleLesson', 'bulkChange', name='schedulechangetype', native_enum=True), nullable=False),
        sa.Column('previous_day_of_week', sa.Integer(), nullable=True),
        sa.Column('previous_time', sa.String(length=5), nullable=True),
        sa.Column('new_day_of_week', sa.Integer(), nullable=True),
        sa.Column('new_time', sa.String(length=5), nullable=True),
        sa.Column('effective_from', sa.Date(), nullable=False),
        sa.Column('status', sa.Enum('pending', 'approved', 'rejected', 'alternativeProposed', 'cancelled', name='schedulechangestatus', native_enum=True), nullable=False),
        sa.Column('requested_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('processed_at', sa.DateTime(), nullable=True),
        sa.Column('request_reason', sa.Text(), nullable=True),
        sa.Column('response_message', sa.Text(), nullable=True),
        sa.Column('requested_by', sa.String(length=36), nullable=True),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_lsc_student', 'lesson_schedule_changes', ['student_id'])
    op.create_index('idx_lsc_teacher', 'lesson_schedule_changes', ['teacher_id'])
    op.create_index('idx_lsc_status', 'lesson_schedule_changes', ['status'])

    # --- Practice Logs ---
    op.create_table('practice_logs',
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('total_minutes', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('tasks', sa.JSON(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('uk_practice_log', 'practice_logs', ['student_id', 'date'], unique=True)
    op.create_index('idx_practice_log_date', 'practice_logs', ['date'])


def downgrade() -> None:
    op.drop_table('practice_logs')
    op.drop_table('lesson_schedule_changes')
    op.drop_table('no_show_records')
    op.drop_table('group_class_bookings')
    op.drop_table('group_class_schedules')
    op.drop_table('schedule_exceptions')
    op.drop_table('teacher_reviews')
    op.drop_table('teaching_resources')
    op.drop_table('feedback_presets')
    op.drop_table('parent_notification_settings')
    op.drop_table('notification_settings')
    op.drop_table('proposal_settings')
    op.drop_table('subscription_settings')
    op.drop_table('teacher_settings')
    op.drop_table('gamification_badges')
    op.drop_table('gamification_points')
    op.drop_table('connections')
    op.drop_table('connection_requests')
    op.drop_table('invites')

    # Drop enum types
    for enum_name in [
        'inviteuserrole', 'invitestatus', 'invitemethod', 'connectionrequeststatus',
        'pointtype', 'badgerarity', 'reviewauthortype', 'reviewvisibility',
        'exceptiontype', 'groupschedulestatus', 'groupbookingstatus',
        'individualnoshowpolicy', 'schedulechangetype', 'schedulechangestatus',
    ]:
        op.execute(f"DROP TYPE IF EXISTS {enum_name}")
