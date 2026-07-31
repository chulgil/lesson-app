"""group_class_schedules.group_class_id → group_classes FK 정합 (P1-0)

Revision ID: group_class_schedule_fk
Revises: add_practice_journal
Create Date: 2026-07-31 09:00:00.000000

배경
----
``group_class_schedules.group_class_id`` 는 FK 제약이 없는 String(36) 이었고,
서비스 레이어는 이 값을 ``lesson_classes.id`` (학원 조직단위 = 별개 개념) 로
해석했다. 그 결과 정원·노쇼정책을 보유한 ``group_classes`` 는 어떤 코드도 읽지
않는 죽은 테이블이었다. 이 마이그레이션이 참조 대상을 ``group_classes`` 로
확정한다.

기존 데이터 이관 전략 — 백필(mirror), 삭제 아님
------------------------------------------------
기존 스케줄 행의 ``group_class_id`` 는 ``lesson_classes.id`` 를 담고 있으므로,
FK 를 그대로 걸면 위반한다. 두 선택지 중 **백필** 을 택한다.

  (A) 백필  : 참조된 lesson_classes 행마다 **같은 id** 의 group_classes 행을
              생성해 미러링한다. 스케줄 id·예약·출석 이력이 그대로 보존되고,
              FK 도 즉시 성립한다.  ← 채택
  (B) 삭제  : 고아 스케줄 행을 지운다. 예약/출석 이력이 유실된다. → 거절.

미러 행의 값은 모델 기본값과 같다(정원 10 / 60분 / 예약마감 60분 / 취소마감
1440분 / 노쇼 deductCredit). 그룹레슨 기능은 출시 전이라 실 데이터는 없거나
극소량이며, 미러 행이 남아도 교사가 정원·정책을 수정하면 된다.

백필로도 복구 불가능한 행(참조 대상이 lesson_classes 에도 없는 완전 고아)만
삭제한다. 이 행들은 어차피 조회 불가였다 — ownership 검증이 teacher 를 찾지
못해 403/404 로 막혔다.

downgrade 는 FK 만 되돌린다. 미러된 group_classes 행은 삭제하지 않는다 —
지우면 upgrade 이후 생성된 정상 스케줄이 고아가 되기 때문.
"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "group_class_schedule_fk"
down_revision: str | None = "add_practice_journal"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

FK_NAME = "fk_group_class_schedules_group_class_id_group_classes"

# Postgres 의 native enum 컬럼(groupclasstype / noshowpolicy)은 INSERT ... SELECT
# 에서 text 리터럴을 자동 변환하지 않는다. SQLite 는 캐스트 문법을 모르므로 분기.
_ENUM_LITERALS = {
    "postgresql": ("'regular'::groupclasstype", "'deductCredit'::noshowpolicy"),
    "_default": ("'regular'", "'deductCredit'"),
}

_BACKFILL_SQL = """
INSERT INTO group_classes (
    id, teacher_id, name, type, max_capacity, duration_minutes,
    booking_deadline_minutes, cancel_deadline_minutes, no_show_policy, is_active
)
SELECT DISTINCT lc.id, lc.teacher_id, lc.name, {class_type}, 10, 60,
       60, 1440, {no_show_policy}, true
FROM lesson_classes lc
JOIN group_class_schedules gcs ON gcs.group_class_id = lc.id
WHERE NOT EXISTS (SELECT 1 FROM group_classes gc WHERE gc.id = lc.id)
"""

_PURGE_ORPHAN_BOOKINGS_SQL = """
DELETE FROM group_class_bookings
WHERE schedule_id IN (
    SELECT id FROM group_class_schedules
    WHERE group_class_id NOT IN (SELECT id FROM group_classes)
)
"""

_PURGE_ORPHAN_SCHEDULES_SQL = """
DELETE FROM group_class_schedules
WHERE group_class_id NOT IN (SELECT id FROM group_classes)
"""


def upgrade() -> None:
    dialect = op.get_bind().dialect.name
    class_type, no_show_policy = _ENUM_LITERALS.get(dialect, _ENUM_LITERALS["_default"])
    op.execute(_BACKFILL_SQL.format(class_type=class_type, no_show_policy=no_show_policy))
    op.execute(_PURGE_ORPHAN_BOOKINGS_SQL)
    op.execute(_PURGE_ORPHAN_SCHEDULES_SQL)

    with op.batch_alter_table("group_class_schedules") as batch_op:
        batch_op.create_foreign_key(
            FK_NAME,
            "group_classes",
            ["group_class_id"],
            ["id"],
            ondelete="CASCADE",
        )


def downgrade() -> None:
    with op.batch_alter_table("group_class_schedules") as batch_op:
        batch_op.drop_constraint(FK_NAME, type_="foreignkey")
