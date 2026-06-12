"""#709 — SMS OTP 전화인증 코드 저장 테이블.

phone_verification_codes: 해시된 OTP + TTL + 시도 횟수 (teacher 당 최신 1행).
phone_verification_daily_counts: 번호당 일일 발송 한도 (5회/일) 추적.

Revision ID: phone_verification_codes
Revises: recording_title_shared_at
Create Date: 2026-06-12 10:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "phone_verification_codes"
down_revision: str | None = "recording_title_shared_at"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "phone_verification_codes",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("code_hash", sa.String(length=256), nullable=False),
        sa.Column("salt", sa.String(length=64), nullable=False),
        sa.Column("phone_number", sa.String(length=20), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempt_count", sa.Integer(), nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_phone_verification_codes"),
    )
    op.create_index(
        "ix_phone_verification_codes_teacher_id",
        "phone_verification_codes",
        ["teacher_id"],
    )
    op.create_index(
        "ix_phone_verification_codes_phone_number",
        "phone_verification_codes",
        ["phone_number"],
    )

    op.create_table(
        "phone_verification_daily_counts",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("phone_number", sa.String(length=20), nullable=False),
        sa.Column("date_key", sa.String(length=10), nullable=False),
        sa.Column("count", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_phone_verification_daily_counts"),
    )
    op.create_index(
        "uq_phone_verification_daily",
        "phone_verification_daily_counts",
        ["phone_number", "date_key"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("uq_phone_verification_daily", table_name="phone_verification_daily_counts")
    op.drop_table("phone_verification_daily_counts")
    op.drop_index("ix_phone_verification_codes_phone_number", table_name="phone_verification_codes")
    op.drop_index("ix_phone_verification_codes_teacher_id", table_name="phone_verification_codes")
    op.drop_table("phone_verification_codes")
