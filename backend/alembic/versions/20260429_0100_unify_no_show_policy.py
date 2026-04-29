"""Unify NoShowPolicy to 4 values (Plan B Phase 5c)

Revision ID: unify_no_show_policy
Revises: align_booking_status
Create Date: 2026-04-29 01:00:00.000000

#239 결정 게이트 (2026-04-29): 4값 단일 enum 채택.
- deductCredit, halfCredit, noDeduction, reschedule
- group_classes.no_show_policy: deduct → deductCredit, noDeduct → noDeduction
- group_class_attendances.applied_policy: 이미 4값 (변경 없음)
- IndividualNoShowPolicy 타입은 SSOT 단일화로 alias 처리 (model 코드만)
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "unify_no_show_policy"
down_revision: str | None = "align_booking_status"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# spec SSOT
NEW_VALUES = ("deductCredit", "halfCredit", "noDeduction", "reschedule")
LEGACY_VALUES = ("deduct", "noDeduct")


def upgrade() -> None:
    bind = op.get_bind()
    is_postgres = bind.dialect.name == "postgresql"

    if is_postgres:
        # group_classes.no_show_policy 만 레거시 2값 → 새 4값 정렬
        op.execute("ALTER TABLE group_classes ALTER COLUMN no_show_policy TYPE VARCHAR(30) USING no_show_policy::text")
        op.execute("UPDATE group_classes SET no_show_policy = 'deductCredit' WHERE no_show_policy = 'deduct'")
        op.execute("UPDATE group_classes SET no_show_policy = 'noDeduction' WHERE no_show_policy = 'noDeduct'")
        op.execute("DROP TYPE IF EXISTS noshowpolicy")
        new_enum = sa.Enum(*NEW_VALUES, name="noshowpolicy")
        new_enum.create(bind, checkfirst=False)
        op.execute(
            "ALTER TABLE group_classes ALTER COLUMN no_show_policy TYPE noshowpolicy USING no_show_policy::noshowpolicy"
        )
        op.execute("ALTER TABLE group_classes ALTER COLUMN no_show_policy SET DEFAULT 'deductCredit'")
        # individualnoshowpolicy → noshowpolicy 통합
        op.execute(
            "ALTER TABLE group_class_attendances "
            "ALTER COLUMN applied_policy TYPE VARCHAR(30) USING applied_policy::text"
        )
        op.execute("DROP TYPE IF EXISTS individualnoshowpolicy")
        op.execute(
            "ALTER TABLE group_class_attendances "
            "ALTER COLUMN applied_policy TYPE noshowpolicy USING applied_policy::noshowpolicy"
        )
    else:
        # sqlite: VARCHAR — 데이터 변환만
        op.execute("UPDATE group_classes SET no_show_policy = 'deductCredit' WHERE no_show_policy = 'deduct'")
        op.execute("UPDATE group_classes SET no_show_policy = 'noDeduction' WHERE no_show_policy = 'noDeduct'")


def downgrade() -> None:
    bind = op.get_bind()
    is_postgres = bind.dialect.name == "postgresql"

    if is_postgres:
        # halfCredit, reschedule 데이터 손실 경고: downgrade 는 정보 보존 불가
        op.execute("ALTER TABLE group_classes ALTER COLUMN no_show_policy TYPE VARCHAR(30) USING no_show_policy::text")
        op.execute(
            "UPDATE group_classes SET no_show_policy = 'deduct' WHERE no_show_policy IN ('deductCredit', 'halfCredit')"
        )
        op.execute(
            "UPDATE group_classes SET no_show_policy = 'noDeduct' WHERE no_show_policy IN ('noDeduction', 'reschedule')"
        )
        op.execute(
            "ALTER TABLE group_class_attendances "
            "ALTER COLUMN applied_policy TYPE VARCHAR(30) USING applied_policy::text"
        )
        op.execute("DROP TYPE IF EXISTS noshowpolicy")
        legacy_enum = sa.Enum(*LEGACY_VALUES, name="noshowpolicy")
        legacy_enum.create(bind, checkfirst=False)
        op.execute(
            "ALTER TABLE group_classes ALTER COLUMN no_show_policy TYPE noshowpolicy USING no_show_policy::noshowpolicy"
        )
        op.execute("ALTER TABLE group_classes ALTER COLUMN no_show_policy SET DEFAULT 'deduct'")
        individual_enum = sa.Enum(*NEW_VALUES, name="individualnoshowpolicy")
        individual_enum.create(bind, checkfirst=False)
        op.execute(
            "ALTER TABLE group_class_attendances "
            "ALTER COLUMN applied_policy TYPE individualnoshowpolicy "
            "USING applied_policy::individualnoshowpolicy"
        )
    else:
        op.execute(
            "UPDATE group_classes SET no_show_policy = 'deduct' WHERE no_show_policy IN ('deductCredit', 'halfCredit')"
        )
        op.execute(
            "UPDATE group_classes SET no_show_policy = 'noDeduct' WHERE no_show_policy IN ('noDeduction', 'reschedule')"
        )
