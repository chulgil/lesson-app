"""ac_m1_group_a_academy_core_domain

AC-M1 그룹 A — Academy 핵심 도메인 4 테이블 + 3 enum.

Spec: docs/specs/web/academy/README.md (AC-M1) + docs/specs/academy/academy_master.md.

테이블:
- academies: 학원 기본 정보 (1 학원 = 1 행)
- academy_members: 학원 소속 (학원장/강사). users FK.
- academy_students: 학원 학생. users FK (학생/학부모) nullable.
- academy_invites: 강사 초대 토큰 (hash 저장).

Enums:
- academymemberrole: owner, teacher
- academystudentstatus: waiting, matched, active, paused, alumni
- academyinvitestate: pending, accepted, declined, expired, revoked

Policy:
- AcademyMember.user_id 는 기존 users 테이블 FK 필수 (별도 조직 계정 시스템 없음).
- AcademyStudent.student_user_id / parent_user_id nullable.
- access_revoked_at 컬럼으로 강사 퇴직 처리 (행 삭제 X, audit 보존).
- 신규 academy_subscriptions 테이블 만들지 않음. 향후 그룹 C 에서 subscriptions 에 academy_id 컬럼 추가.

Revision ID: ac_m1_group_a_academy_core
Revises: drop_students_connection_status
Create Date: 2026-06-04 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql  # noqa: F401  (used in upgrade() enum defs)

from alembic import op

revision: str = "ac_m1_group_a_academy_core"
down_revision: str | None = "drop_students_connection_status"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Enums first (PG native enum).
    # create_type=False: 명시적 .create() 한 번만 생성, create_table 재발행 방지.
    academy_member_role = postgresql.ENUM("owner", "teacher", name="academymemberrole", create_type=False)
    academy_student_status = postgresql.ENUM(
        "waiting", "matched", "active", "paused", "alumni", name="academystudentstatus", create_type=False
    )
    academy_invite_state = postgresql.ENUM(
        "pending", "accepted", "declined", "expired", "revoked", name="academyinvitestate", create_type=False
    )
    bind = op.get_bind()
    academy_member_role.create(bind, checkfirst=True)
    academy_student_status.create(bind, checkfirst=True)
    academy_invite_state.create(bind, checkfirst=True)

    # academies
    op.create_table(
        "academies",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("slug", sa.String(100), nullable=False, unique=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column(
            "owner_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("business_number", sa.String(20), nullable=True),
        sa.Column("phone", sa.String(30), nullable=True),
        sa.Column("address", sa.String(500), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("timezone", sa.String(50), nullable=False, server_default="Asia/Seoul"),
        sa.Column("locale", sa.String(10), nullable=False, server_default="ko"),
    )
    op.create_index("idx_academies_owner", "academies", ["owner_user_id"])
    op.create_index("idx_academies_slug", "academies", ["slug"])

    # academy_members
    op.create_table(
        "academy_members",
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
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("role", academy_member_role, nullable=False),
        sa.Column("public_page_consent", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("onboarding_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("access_revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("delegate_role", sa.String(30), nullable=False, server_default="none"),
        sa.Column("delegate_role_granted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "uk_academy_members_acad_user_role",
        "academy_members",
        ["academy_id", "user_id", "role"],
        unique=True,
    )
    op.create_index("idx_academy_members_user", "academy_members", ["user_id"])
    op.create_index("idx_academy_members_academy_role", "academy_members", ["academy_id", "role"])

    # academy_students
    op.create_table(
        "academy_students",
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
            "student_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "parent_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "teacher_member_id",
            sa.String(36),
            sa.ForeignKey("academy_members.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("instrument", sa.String(50), nullable=True),
        sa.Column("status", academy_student_status, nullable=False, server_default="waiting"),
        sa.Column("registered_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("matched_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status_changed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("intake_notes", sa.Text(), nullable=True),
        sa.Column("deposit_code", sa.String(30), nullable=True),
    )
    op.create_index("idx_academy_students_academy_status", "academy_students", ["academy_id", "status"])
    op.create_index("idx_academy_students_teacher", "academy_students", ["teacher_member_id"])
    op.create_index("idx_academy_students_student_user", "academy_students", ["student_user_id"])
    op.create_index("idx_academy_students_parent_user", "academy_students", ["parent_user_id"])

    # academy_invites
    op.create_table(
        "academy_invites",
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
            "invited_by_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("token_hash", sa.String(128), nullable=False, unique=True),
        # NOTE: PostgreSQL 전용 ``::json`` cast 제거 — SQLite (tests) 에서 ``unrecognized token: ":"`` 로 실패.
        # ``sa.text("'[]'")`` 는 PostgreSQL JSON 컬럼에도 안전 (자동 cast 됨).
        sa.Column("roles", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
        sa.Column("target_email", sa.String(255), nullable=True),
        sa.Column("target_phone", sa.String(30), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("state", academy_invite_state, nullable=False, server_default="pending"),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("declined_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "accepted_member_id",
            sa.String(36),
            sa.ForeignKey("academy_members.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("note", sa.Text(), nullable=True),
    )
    op.create_index("idx_academy_invites_academy_state", "academy_invites", ["academy_id", "state"])
    op.create_index("idx_academy_invites_expires", "academy_invites", ["expires_at"])


def downgrade() -> None:
    op.drop_index("idx_academy_invites_expires", table_name="academy_invites")
    op.drop_index("idx_academy_invites_academy_state", table_name="academy_invites")
    op.drop_table("academy_invites")

    op.drop_index("idx_academy_students_parent_user", table_name="academy_students")
    op.drop_index("idx_academy_students_student_user", table_name="academy_students")
    op.drop_index("idx_academy_students_teacher", table_name="academy_students")
    op.drop_index("idx_academy_students_academy_status", table_name="academy_students")
    op.drop_table("academy_students")

    op.drop_index("idx_academy_members_academy_role", table_name="academy_members")
    op.drop_index("idx_academy_members_user", table_name="academy_members")
    op.drop_index("uk_academy_members_acad_user_role", table_name="academy_members")
    op.drop_table("academy_members")

    op.drop_index("idx_academies_slug", table_name="academies")
    op.drop_index("idx_academies_owner", table_name="academies")
    op.drop_table("academies")

    bind = op.get_bind()
    sa.Enum(name="academyinvitestate").drop(bind, checkfirst=True)
    sa.Enum(name="academystudentstatus").drop(bind, checkfirst=True)
    sa.Enum(name="academymemberrole").drop(bind, checkfirst=True)
