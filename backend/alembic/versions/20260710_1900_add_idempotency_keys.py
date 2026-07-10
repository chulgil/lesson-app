"""Issue #1117 — idempotency_keys 테이블 추가 (POST 중복 생성 방지, INV-2/SN-4).

느린 네트워크에서 응답이 유실된 POST 를 클라이언트가 재생할 때, 서버가 같은
``Idempotency-Key`` 를 (user_id 스코프) 유니크로 dedupe 해 중복 리소스 생성을 막는다.
새 테이블만 추가하는 additive 마이그레이션 — 기존 데이터/스키마 무변경, 무손실.

Revision ID: add_idempotency_keys
Revises: add_teacher_nickname
Create Date: 2026-07-10 19:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "add_idempotency_keys"
down_revision: str | None = "add_teacher_nickname"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "idempotency_keys",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("idem_key", sa.String(length=255), nullable=False),
        sa.Column("method", sa.String(length=10), nullable=False),
        sa.Column("path", sa.String(length=500), nullable=False),
        sa.Column("status_code", sa.Integer(), nullable=True),
        sa.Column("response_body", sa.JSON(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id", name="pk_idempotency_keys"),
        sa.UniqueConstraint("user_id", "idem_key", name="uq_idempotency_keys_user_id_idem_key"),
    )


def downgrade() -> None:
    op.drop_table("idempotency_keys")
