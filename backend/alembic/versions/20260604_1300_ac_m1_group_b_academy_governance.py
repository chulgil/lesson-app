"""ac_m1_group_b_academy_governance

AC-M1 그룹 B — Academy 권한 계층 4 테이블 + 6 enum.

Spec:
- ContextSwitchLog: context_toggle_spec.md §3.3
- AcademyDelegation + Action: temporary_delegation_spec.md §3
- AcademyActivityLog: academy_schedule_authority_spec.md §2.4

테이블:
- context_switch_logs: 학원장↔강사 모드 전환 audit (영구 보존)
- academy_delegations: 임시 권한 위임
- academy_delegation_actions: 위임 액션 audit
- academy_activity_logs: 강사 활동 timeline (NFR-A-5 사후 가시성)

Enums:
- academycontext: academy_owner, teacher
- contextswitchtrigger: user, session_resume
- delegationreason: trip, sick, vacation, event, other
- delegationstate: scheduled, active, expired, revoked, auto_ended
- delegationrevokereason: owner_returned, owner_manual, expired, delegatee_declined

Policy:
- 모든 audit 행 영구 보존 — 분쟁 시 운영자 어드민 조회
- 위임 시간 제한 (ends_at 필수). 영구 권한 부여 금지.
- actor_name 직접 저장 (강사 이름 변경/퇴직 후에도 audit 보존)

Revision ID: ac_m1_group_b_governance
Revises: ac_m1_group_a_academy_core
Create Date: 2026-06-04 13:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "ac_m1_group_b_governance"
down_revision: str | None = "ac_m1_group_a_academy_core"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Enums.
    academy_context = sa.Enum("academy_owner", "teacher", name="academycontext")
    context_switch_trigger = sa.Enum("user", "session_resume", name="contextswitchtrigger")
    delegation_reason = sa.Enum("trip", "sick", "vacation", "event", "other", name="delegationreason")
    delegation_state = sa.Enum("scheduled", "active", "expired", "revoked", "auto_ended", name="delegationstate")
    delegation_revoke_reason = sa.Enum(
        "owner_returned",
        "owner_manual",
        "expired",
        "delegatee_declined",
        name="delegationrevokereason",
    )
    bind = op.get_bind()
    academy_context.create(bind, checkfirst=True)
    context_switch_trigger.create(bind, checkfirst=True)
    delegation_reason.create(bind, checkfirst=True)
    delegation_state.create(bind, checkfirst=True)
    delegation_revoke_reason.create(bind, checkfirst=True)

    # context_switch_logs
    op.create_table(
        "context_switch_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("from_context", academy_context, nullable=False),
        sa.Column("to_context", academy_context, nullable=False),
        sa.Column("switched_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ip", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.String(500), nullable=True),
        sa.Column("triggered_by", context_switch_trigger, nullable=False, server_default="user"),
    )
    op.create_index("idx_context_switch_user_time", "context_switch_logs", ["user_id", "switched_at"])
    op.create_index("idx_context_switch_academy_time", "context_switch_logs", ["academy_id", "switched_at"])

    # academy_delegations
    op.create_table(
        "academy_delegations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "delegator_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "delegatee_member_id",
            sa.String(36),
            sa.ForeignKey("academy_members.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        # NOTE: PostgreSQL 전용 ``::json`` cast 제거 — SQLite 호환.
        sa.Column("permissions", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reason", delegation_reason, nullable=False),
        sa.Column("reason_note", sa.Text(), nullable=True),
        sa.Column("state", delegation_state, nullable=False, server_default="scheduled"),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "revoked_by_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("revoked_reason", delegation_revoke_reason, nullable=True),
        sa.Column(
            "requires_password_at_start",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
        sa.Column(
            "notification_template_id",
            sa.String(100),
            nullable=False,
            server_default="delegation_v1",
        ),
    )
    op.create_index("idx_delegation_academy_state", "academy_delegations", ["academy_id", "state"])
    op.create_index("idx_delegation_delegatee", "academy_delegations", ["delegatee_member_id"])
    op.create_index("idx_delegation_ends_at", "academy_delegations", ["ends_at"])

    # academy_delegation_actions
    op.create_table(
        "academy_delegation_actions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "delegation_id",
            sa.String(36),
            sa.ForeignKey("academy_delegations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("performed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "performed_by_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("permission_used", sa.String(50), nullable=False),
        sa.Column("endpoint", sa.String(200), nullable=False),
        sa.Column("target_resource_id", sa.String(100), nullable=True),
        sa.Column("request_summary", sa.JSON(), nullable=True),
        sa.Column("response_status", sa.Integer(), nullable=False),
        sa.Column("owner_reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("owner_dispute_note", sa.Text(), nullable=True),
    )
    op.create_index(
        "idx_deleg_action_delegation_time",
        "academy_delegation_actions",
        ["delegation_id", "performed_at"],
    )
    op.create_index(
        "idx_deleg_action_review_pending",
        "academy_delegation_actions",
        ["delegation_id", "owner_reviewed_at"],
    )

    # academy_activity_logs
    op.create_table(
        "academy_activity_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "actor_member_id",
            sa.String(36),
            sa.ForeignKey("academy_members.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("actor_name", sa.String(100), nullable=False),
        sa.Column("action_type", sa.String(50), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("target_resource_type", sa.String(50), nullable=True),
        sa.Column("target_resource_id", sa.String(100), nullable=True),
        sa.Column("metadata", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("idx_activity_log_academy_time", "academy_activity_logs", ["academy_id", "created_at"])
    op.create_index("idx_activity_log_actor_time", "academy_activity_logs", ["actor_member_id", "created_at"])
    op.create_index(
        "idx_activity_log_action_type",
        "academy_activity_logs",
        ["academy_id", "action_type", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("idx_activity_log_action_type", table_name="academy_activity_logs")
    op.drop_index("idx_activity_log_actor_time", table_name="academy_activity_logs")
    op.drop_index("idx_activity_log_academy_time", table_name="academy_activity_logs")
    op.drop_table("academy_activity_logs")

    op.drop_index("idx_deleg_action_review_pending", table_name="academy_delegation_actions")
    op.drop_index("idx_deleg_action_delegation_time", table_name="academy_delegation_actions")
    op.drop_table("academy_delegation_actions")

    op.drop_index("idx_delegation_ends_at", table_name="academy_delegations")
    op.drop_index("idx_delegation_delegatee", table_name="academy_delegations")
    op.drop_index("idx_delegation_academy_state", table_name="academy_delegations")
    op.drop_table("academy_delegations")

    op.drop_index("idx_context_switch_academy_time", table_name="context_switch_logs")
    op.drop_index("idx_context_switch_user_time", table_name="context_switch_logs")
    op.drop_table("context_switch_logs")

    bind = op.get_bind()
    sa.Enum(name="delegationrevokereason").drop(bind, checkfirst=True)
    sa.Enum(name="delegationstate").drop(bind, checkfirst=True)
    sa.Enum(name="delegationreason").drop(bind, checkfirst=True)
    sa.Enum(name="contextswitchtrigger").drop(bind, checkfirst=True)
    sa.Enum(name="academycontext").drop(bind, checkfirst=True)
