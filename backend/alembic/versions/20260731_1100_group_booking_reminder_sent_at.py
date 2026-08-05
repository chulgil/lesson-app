"""group_class_bookings 에 리마인더 멱등 컬럼 2개 추가 (P2-2)

Revision ID: group_booking_reminder_sent_at
Revises: subscription_applies_to
Create Date: 2026-07-31 11:00:00.000000

왜 컬럼인가
-----------
전일·당일 리마인더는 cron 배치라 재실행(advisory lock 실패, 인스턴스 재기동,
배포 윈도우, catch-up)이 정상 동작이다. 발송 여부를 어딘가에 적어두지 않으면
같은 학생에게 리마인더가 반복해서 간다.

  (A) 예약 행에 ``reminder_*_sent_at`` 타임스탬프. 배치는 NULL 인 행만 집는다.
      ``payment_reminder_jobs`` 의 ``reminder_d{1,3,7}_sent_at`` 과 같은 규약. ← 채택
  (B) 별도 dispatch_log 테이블. 전이 2종에 테이블 하나는 과설계이고, 예약이
      취소되면 고아 행이 남는다. → 거절.

알림 타입은 enum 이 아니다
--------------------------
``notifications.type`` 은 PG native enum 이 아니라 ``VARCHAR(50)`` 이다
(0001 초기 스키마). 그래서 그룹 알림 5종을 추가해도 ``ALTER TYPE ADD VALUE``
마이그레이션이 필요 없다. native enum 인 것은 ``notificationpriority`` 뿐이고
이번 변경은 그 라벨을 건드리지 않는다.

nullable + server_default 없음: "아직 안 보냄" 을 NULL 로 표현한다. 기존 예약은
NULL 로 남아 다음 배치가 정상 판정한다 (과거 회차는 날짜 윈도우에서 걸러짐).
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "group_booking_reminder_sent_at"
down_revision: str | None = "subscription_applies_to"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLE = "group_class_bookings"
COLUMNS = ("reminder_day_before_sent_at", "reminder_day_of_sent_at")


def upgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for column in COLUMNS:
            op.execute(f"ALTER TABLE {TABLE} ADD COLUMN IF NOT EXISTS {column} TIMESTAMPTZ")
        return

    # SQLite 는 IF NOT EXISTS 가 없고, FK 가 안 걸린 nullable 컬럼이라 batch 없이 붙는다.
    for column in COLUMNS:
        op.add_column(TABLE, sa.Column(column, sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for column in COLUMNS:
            op.execute(f"ALTER TABLE {TABLE} DROP COLUMN IF EXISTS {column}")
        return

    for column in COLUMNS:
        op.drop_column(TABLE, column)
