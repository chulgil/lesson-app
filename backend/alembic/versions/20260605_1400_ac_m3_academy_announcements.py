"""ac_m3_academy_announcements

AC-M3 — 학원장 단방향 공지 BE 데이터 모델.

Spec: docs/specs/web/academy/announcements_spec.md §2.

테이블:
- academy_announcements: 공지 헤더 (audience, channels, status, 통계)
- academy_announcement_recipients: 공지 × 수신자 (읽음/배달 추적)

Enums:
- academyannouncementaudience: all / teachers / parents / students / teacher_students
- academyannouncementstatus: draft / scheduled / sending / sent / cancelled
- academyannouncementrecipientrole: teacher / parent / student

Policy:
- 학원장 1인 작성 권한 (단방향)
- 카톡 알림톡은 사전 등록 템플릿만 (custom 메시지는 인앱)
- target_count 는 발송 시점 snapshot (사후 멤버십 변동 무관)

Revision ID: ac_m3_academy_announcements
Revises: ac_m2_user_tokens_revoked_at
Create Date: 2026-06-05 14:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "ac_m3_academy_announcements"
down_revision: str | None = "ac_m2_user_tokens_revoked_at"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Enums.
    audience = sa.Enum(
        "all",
        "teachers",
        "parents",
        "students",
        "teacher_students",
        name="academyannouncementaudience",
    )
    status = sa.Enum(
        "draft",
        "scheduled",
        "sending",
        "sent",
        "cancelled",
        name="academyannouncementstatus",
    )
    recipient_role = sa.Enum(
        "teacher",
        "parent",
        "student",
        name="academyannouncementrecipientrole",
    )
    bind = op.get_bind()
    audience.create(bind, checkfirst=True)
    status.create(bind, checkfirst=True)
    recipient_role.create(bind, checkfirst=True)

    # academy_announcements
    op.create_table(
        "academy_announcements",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "author_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("body_markdown", sa.Text(), nullable=False),
        sa.Column("audience", audience, nullable=False),
        sa.Column("audience_filter", sa.JSON(), nullable=True),
        sa.Column("channels", sa.JSON(), nullable=False, server_default=sa.text("'[]'::json")),
        sa.Column("kakao_template_id", sa.String(100), nullable=True),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", status, nullable=False, server_default="draft"),
        sa.Column("target_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("delivered_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("read_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index("idx_acad_ann_academy_created", "academy_announcements", ["academy_id", "created_at"])
    op.create_index("idx_acad_ann_academy_status", "academy_announcements", ["academy_id", "status"])
    op.create_index("idx_acad_ann_scheduled", "academy_announcements", ["scheduled_at"])

    # academy_announcement_recipients
    op.create_table(
        "academy_announcement_recipients",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "announcement_id",
            sa.String(36),
            sa.ForeignKey("academy_announcements.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("role", recipient_role, nullable=False),
        sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("kakao_delivered", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("inapp_delivered", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.create_index(
        "uq_acad_ann_recipient_per_user",
        "academy_announcement_recipients",
        ["announcement_id", "user_id"],
        unique=True,
    )
    op.create_index(
        "idx_acad_ann_recipient_user_role",
        "academy_announcement_recipients",
        ["user_id", "role"],
    )
    op.create_index(
        "idx_acad_ann_recipient_read",
        "academy_announcement_recipients",
        ["announcement_id", "read_at"],
    )


def downgrade() -> None:
    op.drop_index("idx_acad_ann_recipient_read", table_name="academy_announcement_recipients")
    op.drop_index("idx_acad_ann_recipient_user_role", table_name="academy_announcement_recipients")
    op.drop_index("uq_acad_ann_recipient_per_user", table_name="academy_announcement_recipients")
    op.drop_table("academy_announcement_recipients")

    op.drop_index("idx_acad_ann_scheduled", table_name="academy_announcements")
    op.drop_index("idx_acad_ann_academy_status", table_name="academy_announcements")
    op.drop_index("idx_acad_ann_academy_created", table_name="academy_announcements")
    op.drop_table("academy_announcements")

    sa.Enum(name="academyannouncementrecipientrole").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="academyannouncementstatus").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="academyannouncementaudience").drop(op.get_bind(), checkfirst=True)
