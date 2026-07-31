"""subscriptions/subscription_templates 에 applies_to + group_class_id 추가 (P1-4)

Revision ID: subscription_applies_to
Revises: group_class_schedule_fk
Create Date: 2026-07-31 10:00:00.000000

비파괴 원칙 — NULL = universal
------------------------------
그룹레슨 도입 전에 발급된 수강권은 "1:1 전용" 이 아니라 **스코프 개념이 없던**
수강권이다. 따라서 백필하지 않는다.

  (A) 컬럼만 추가하고 기존 행은 NULL 유지. 읽을 때 NULL 을 ``universal`` 로
      해석한다 (``Subscription.effective_applies_to``).            ← 채택
  (B) 기존 행을 ``oneToOne`` 으로 백필. 그룹 수업에 쓸 수 없게 되어 이미
      결제된 수강권의 사용 범위를 사후에 축소한다. → 거절.

server_default 도 두지 않는다. default 를 걸면 (B) 와 같은 문제가 신규 행에서
재발하고, "미지정" 과 "명시적 universal" 을 구분할 수 없게 된다.

Postgres native enum
--------------------
라벨은 모델의 ``.value`` (camelCase) 로 생성한다. 모델 컬럼도
``values_callable`` 로 같은 문자열을 바인딩하므로 양쪽이 일치한다 — 멤버명
(snake_case)으로 굳으면 실데이터 로드 시 LookupError → 500 (#814 재발).

SQLite 는 native enum 이 없어 VARCHAR 로 떨어지고 ALTER 제약도 없으므로
dialect 로 분기한다.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "subscription_applies_to"
down_revision: str | None = "group_class_schedule_fk"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

ENUM_NAME = "subscriptionappliesto"
ENUM_VALUES = ("oneToOne", "group", "universal")
TABLES = ("subscriptions", "subscription_templates")

_CREATE_ENUM_SQL = f"""
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = '{ENUM_NAME}') THEN
        CREATE TYPE {ENUM_NAME} AS ENUM ({", ".join(f"'{v}'" for v in ENUM_VALUES)});
    END IF;
END
$$;
"""


def _fk_name(table: str) -> str:
    return f"fk_{table}_group_class_id_group_classes"


def _add_fk_sql(table: str) -> str:
    """ADD CONSTRAINT 는 IF NOT EXISTS 를 지원하지 않아 pg_constraint 로 가드."""
    return f"""
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '{_fk_name(table)}') THEN
        ALTER TABLE {table}
            ADD CONSTRAINT {_fk_name(table)}
            FOREIGN KEY (group_class_id) REFERENCES group_classes (id) ON DELETE SET NULL;
    END IF;
END
$$;
"""


def upgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        op.execute(_CREATE_ENUM_SQL)
        for table in TABLES:
            op.execute(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS applies_to {ENUM_NAME}")
            op.execute(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS group_class_id VARCHAR(36)")
            op.execute(_add_fk_sql(table))
        return

    # SQLite 는 FK 를 ALTER 로 붙이지 못해 batch(테이블 재생성)가 필요하다. 재생성은
    # 반영된 named CHECK 제약(ck_subscriptions_*)을 그대로 옮긴다 — 실측 확인함.
    for table in TABLES:
        with op.batch_alter_table(table) as batch_op:
            batch_op.add_column(
                sa.Column(
                    "applies_to",
                    sa.Enum(*ENUM_VALUES, name=ENUM_NAME, native_enum=True),
                    nullable=True,
                )
            )
            batch_op.add_column(sa.Column("group_class_id", sa.String(36), nullable=True))
            batch_op.create_foreign_key(
                _fk_name(table),
                "group_classes",
                ["group_class_id"],
                ["id"],
                ondelete="SET NULL",
            )


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        for table in TABLES:
            op.execute(f"ALTER TABLE {table} DROP CONSTRAINT IF EXISTS {_fk_name(table)}")
            op.execute(f"ALTER TABLE {table} DROP COLUMN IF EXISTS group_class_id")
            op.execute(f"ALTER TABLE {table} DROP COLUMN IF EXISTS applies_to")
        op.execute(f"DROP TYPE IF EXISTS {ENUM_NAME}")
        return

    # FK 가 걸린 컬럼은 SQLite 가 DROP COLUMN 을 거부한다 (dangling FK). 제약을 먼저
    # 떼고 같은 batch 안에서 컬럼을 지운다.
    for table in TABLES:
        with op.batch_alter_table(table) as batch_op:
            batch_op.drop_constraint(_fk_name(table), type_="foreignkey")
            batch_op.drop_column("group_class_id")
            batch_op.drop_column("applies_to")
