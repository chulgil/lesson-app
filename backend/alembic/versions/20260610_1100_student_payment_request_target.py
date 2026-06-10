"""Issue #636 — Student.payment_request_target 컬럼 추가.

spec user_master.md §5.2 — 선생님이 학생별로 입금 안내 대상을 설정.
default = 'student' (본인 입금).

Revision ID: student_payment_request_target
Revises: invite_declined_reason
Create Date: 2026-06-10 11:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "student_payment_request_target"
down_revision: str | None = "invite_declined_reason"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "students",
        sa.Column(
            "payment_request_target",
            sa.Enum("student", "parent", name="paymentrequesttarget", native_enum=True),
            nullable=False,
            server_default="student",
        ),
    )


def downgrade() -> None:
    op.drop_column("students", "payment_request_target")
