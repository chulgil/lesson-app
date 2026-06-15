"""Issue #725 — AcademyStudent.parent_name 컬럼 추가 (AC-M3 H2).

spec payment_matching_spec.md §3.4 — 학부모가 본인 이름으로 무통장입금하는
한국 최빈 케이스를 입금자명 fuzzy 매칭으로 잡기 위한 학부모 이름 컬럼.

Revision ID: ac_m3_student_parent_name
Revises: ac_m3_payment_matching
Create Date: 2026-06-15 10:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "ac_m3_student_parent_name"
down_revision: str | None = "ac_m3_payment_matching"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "academy_students",
        sa.Column("parent_name", sa.String(length=100), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("academy_students", "parent_name")
