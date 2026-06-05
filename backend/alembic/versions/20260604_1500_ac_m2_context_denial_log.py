"""ac_m2_context_denial_log

AC-M2 — context_toggle_spec §6.3, §9 권한 매트릭스 차단 audit.

테이블:
- context_access_denial_logs: 권한 매트릭스 차단 audit (1년 보존)

응답 detail.audit_id 는 본 행의 id. 분쟁 시 분석/cleanup 정책은 별도.

Revision ID: ac_m2_context_denial_log
Revises: ac_m1_group_c_billing
Create Date: 2026-06-04 15:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "ac_m2_context_denial_log"
down_revision: str | None = "ac_m1_group_c_billing"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "context_access_denial_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("active_context", sa.String(20), nullable=True),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("denial_code", sa.String(50), nullable=False),
        sa.Column("endpoint_path", sa.String(200), nullable=False),
        sa.Column("http_method", sa.String(10), nullable=False),
        sa.Column("target_resource_id", sa.String(100), nullable=True),
        sa.Column("denied_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "idx_context_denial_user_time",
        "context_access_denial_logs",
        ["user_id", "denied_at"],
    )
    op.create_index(
        "idx_context_denial_academy_time",
        "context_access_denial_logs",
        ["academy_id", "denied_at"],
    )
    op.create_index(
        "idx_context_denial_code_time",
        "context_access_denial_logs",
        ["denial_code", "denied_at"],
    )


def downgrade() -> None:
    op.drop_index("idx_context_denial_code_time", table_name="context_access_denial_logs")
    op.drop_index("idx_context_denial_academy_time", table_name="context_access_denial_logs")
    op.drop_index("idx_context_denial_user_time", table_name="context_access_denial_logs")
    op.drop_table("context_access_denial_logs")
