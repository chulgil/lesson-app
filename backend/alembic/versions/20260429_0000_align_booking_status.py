"""Align lesson_bookings.status to spec §10.2 7값 SSOT (Plan B Phase 5b)

Revision ID: align_booking_status
Revises: add_request_events
Create Date: 2026-04-29 00:00:00.000000

#238 결정 게이트 (2026-04-29):
- §6.1 noShow → 옵션 A 제거 (NoShowRecord 테이블 #239 가 SSOT)
- §6.2 rejected → 옵션 A 제거 (decline_reason 컬럼으로 사유 분리)

데이터 변환:
- approved → confirmed (rename)
- rejected → cancelled + decline_reason 컬럼 신설
- noShow → cancelled (NoShowRecord 마이그레이션은 #239 에서 후속)

postgres ENUM 변경 패턴: ALTER TYPE ... ADD VALUE 가 트랜잭션 내 사용 불가 →
columns 를 VARCHAR 로 캐스팅 → 데이터 변환 → 새 ENUM 재생성.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "align_booking_status"
down_revision: str | None = "add_request_events"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# spec §10.2 SSOT
NEW_BOOKING_STATUS_VALUES = (
    "pending",
    "confirmed",
    "changeRequested",
    "completed",
    "cancelled",
    "unavailable",
    "expired",
)


def upgrade() -> None:
    # 1) decline_reason 컬럼 추가 (rejected → cancelled 사유 보존)
    op.add_column(
        "lesson_bookings",
        sa.Column("decline_reason", sa.Text(), nullable=True),
    )

    bind = op.get_bind()
    is_postgres = bind.dialect.name == "postgresql"

    if is_postgres:
        # 2) postgres: ENUM 재생성 패턴
        # 2a) status 를 임시 VARCHAR 로 변환
        op.execute("ALTER TABLE lesson_bookings ALTER COLUMN status TYPE VARCHAR(30) USING status::text")
        # 2b) 데이터 변환
        op.execute("UPDATE lesson_bookings SET status = 'confirmed' WHERE status = 'approved'")
        op.execute(
            "UPDATE lesson_bookings SET status = 'cancelled', decline_reason = COALESCE(notes, '(legacy reject)') "
            "WHERE status = 'rejected'"
        )
        op.execute("UPDATE lesson_bookings SET status = 'cancelled' WHERE status = 'noShow'")
        # 2c) 기존 ENUM 타입 제거
        op.execute("DROP TYPE IF EXISTS bookingstatus")
        # 2d) 새 ENUM 타입 생성 + 컬럼 변환
        new_enum = sa.Enum(*NEW_BOOKING_STATUS_VALUES, name="bookingstatus")
        new_enum.create(bind, checkfirst=False)
        op.execute("ALTER TABLE lesson_bookings ALTER COLUMN status TYPE bookingstatus USING status::bookingstatus")
        op.execute("ALTER TABLE lesson_bookings ALTER COLUMN status SET DEFAULT 'pending'")
    else:
        # sqlite: status 는 VARCHAR — 데이터 변환만 수행
        op.execute("UPDATE lesson_bookings SET status = 'confirmed' WHERE status = 'approved'")
        op.execute(
            "UPDATE lesson_bookings SET status = 'cancelled', decline_reason = COALESCE(notes, '(legacy reject)') "
            "WHERE status = 'rejected'"
        )
        op.execute("UPDATE lesson_bookings SET status = 'cancelled' WHERE status = 'noShow'")


def downgrade() -> None:
    bind = op.get_bind()
    is_postgres = bind.dialect.name == "postgresql"

    if is_postgres:
        # decline_reason 데이터 손실 경고: downgrade 는 데이터 보존 불가
        op.execute("ALTER TABLE lesson_bookings ALTER COLUMN status TYPE VARCHAR(30) USING status::text")
        # confirmed → approved 역변환만 (cancelled→rejected/noShow 분기 불가)
        op.execute("UPDATE lesson_bookings SET status = 'approved' WHERE status = 'confirmed'")
        op.execute("DROP TYPE IF EXISTS bookingstatus")
        legacy_enum = sa.Enum(
            "pending",
            "approved",
            "rejected",
            "changeRequested",
            "completed",
            "cancelled",
            "noShow",
            name="bookingstatus",
        )
        legacy_enum.create(bind, checkfirst=False)
        op.execute("ALTER TABLE lesson_bookings ALTER COLUMN status TYPE bookingstatus USING status::bookingstatus")
        op.execute("ALTER TABLE lesson_bookings ALTER COLUMN status SET DEFAULT 'pending'")
    else:
        op.execute("UPDATE lesson_bookings SET status = 'approved' WHERE status = 'confirmed'")

    op.drop_column("lesson_bookings", "decline_reason")
