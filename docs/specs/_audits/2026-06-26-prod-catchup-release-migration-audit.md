# Prod 캐치업 릴리스 — 마이그레이션 감사 (Alembic 0001 -> head)

> 작성: 2026-06-26 | 상태: **연기 (DEFERRED)** — 의도된 릴리스 윈도우에 착수
> 계기: #928 보강크레딧-예약 기능의 prod 활성화 검토 중 발견
> 범위: prod DB `lessonaza` (alembic `0001`, ~2개월 stale) -> head `add_practice_journal` = **99개 마이그레이션**

## TL;DR

- **판정: CONDITIONAL-GO + 하드 블로커 1건.**
- **핵심 재구성**: #928 기능 자체는 사소하나, prod 활성화 = **99개 마이그레이션 전체를 stale prod 에 적용**(alembic 은 체인 중간만 못 올림). 즉 #928 후속이 아니라 **prod 대형 캐치업 릴리스**. 비용은 #928 이 아니라 누적된 prod 부채.
- **하드 블로커**: `resolve_paymenttype`(#858) 가 "테이블이 비어있다(beta 기준)"를 전제로 VARCHAR->enum 캐스트. prod payments 에 행이 있으면 **캐스트 실패 -> 배포 중단**.
- **결정(2026-06-26)**: prod 릴리스를 별도 프로젝트로 연기. #928 은 dev/mock 으로 동작·머지 완료(PR #1000). FE remote flip 은 이 릴리스 시점에.

## 1. make-or-break 사전쿼리 (prod, read-only — GO/NO-GO 를 가름)

```sql
-- #858 블로커: 결과가 {trial,regular} 외이거나 행이 있으면 마이그레이션 rework 선행
SELECT type, count(*) FROM payments GROUP BY type;
SELECT count(*) FROM payments;                 -- 0 이면 #858 자동 해소
SELECT card_type, count(*) FROM schedule_confirmation_cards GROUP BY card_type;

-- enum/제약 캐스트 안전성
SELECT DISTINCT no_show_policy, applied_policy FROM group_classes;   -- noshowpolicy 멤버 부분집합?

-- NOT NULL 백필 위험 (d91e: server_default 없는 NOT NULL 추가)
SELECT count(*) FROM lesson_requests;          -- 0 아니면 d91e 패치 필요
SELECT count(*) FROM teacher_settings;

-- timestamptz 락 시간 추정 (0003: 57테이블 재작성)
SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 10;

-- 환경
SELECT version();                              -- ADD VALUE autocommit 호환 (>=12)
```

## 2. 위험 마이그레이션 (직접 검증)

| 마이그레이션 | 등급 | 위험 | 완화 |
|---|---|---|---|
| `20260619_0200_resolve_paymenttype_collision_and_card_type_enum` (#858) | **CRITICAL 블로커** | 주석에 "empty on beta" 명시. `payments.type` 구enum`(organization,parent)` -> 신enum`(trial,regular)` USING 캐스트. prod 결제행 1건이라도 신집합에 없으면 실패 | 사전쿼리로 payments 실상 확인. 비어있으면 안전. 아니면 정규화 UPDATE 선행(단 organization/parent vs trial/regular 의미 불일치 -> 데이터 해석 필요) |
| `20260317_0000_0003_timestamp_to_timestamptz` | HIGH | 57테이블 ~150컬럼 `ALTER TYPE TIMESTAMPTZ USING col AT TIME ZONE 'UTC'`. 컬럼별 ACCESS EXCLUSIVE 락 + 재작성. naive=UTC 가정(KST naive 면 9h 시프트) | 점검창 필수. 사전 row count 로 락 시간 추정. 저장값 TZ 의미 확인 |
| `drop_pg_fields_from_payments` · `drop_students_connection_status` · `beta_backend_contract_fixes` · `normalize_teaching_resource_tags` | HIGH | upgrade 에서 drop_column/table = **비가역 데이터 손실** | 백업 + 손실 컬럼 사전 export |
| `add_missing_native_enum_values` · `0005_frontend_backend_alignment` | HIGH | `ALTER TYPE ADD VALUE`(구 PG 트랜잭션 제약) + #815 camelCase `values_callable` 누락 시 런타임 500 | env.py 가 ADD VALUE autocommit 실행하는지 확인 + FE 소셜로그인 enum 로드 스모크 |
| FK 추가 9건 (`add_subscription_fk_constraints`, `add_*_user_fk`, `add_notification_user_fks`, `add_teacher_student_relation_fks`, `add_booking_subscription_origin`, `add_lesson_source`, `beta_backend_contract_fixes`) | MEDIUM | prod orphan 행 있으면 FK 적용 실패 | 클론 dry-run 이 검출 |
| CHECK 추가 8건 (`add_subscription_counter_checks`, `add_schedule_availability_constraints`, `add_schedule_exception_owner_scope`, `add_lesson_session_number`, `add_vacation_mode_to_availability`, `reschedule_check_bonus`, `add_makeup_credits_and_scheduled_lessons`, `beta_backend_contract_fixes`) | MEDIUM | prod 위반 행 있으면 적용 실패 | 클론 dry-run 이 검출 |
| `align_booking_status` · `unify_no_show_policy` | MEDIUM | VARCHAR->enum 이나 캐스트 **전에** 데이터 정규화 수행 -> 구enum 값만 있으면 안전 | (자가완화됨) |
| 나머지 ~76건 | LOW | additive create_table / nullable add_column / index | 클론 dry-run 으로 일괄 확인 |

> 검증 방법: CRITICAL/HIGH 는 마이그레이션 파일 직독. FK/CHECK/LOW 카테고리는 전수 op-sweep(create_foreign_key / create_check_constraint / USING / nullable=False / drop_* / op.execute) 으로 식별 — 개별 정밀검증은 **클론 dry-run 이 최종 게이트**.

## 3. 배포 절차

0. prod `alembic current` = `0001`, `alembic heads` 단일 수렴 확인.
1. **클론 dry-run (필수)**: prod 스냅샷 복원한 throwaway PG 에 `alembic upgrade 0001:head` 전구간 1회. 빈DB 게이트(`test_alembic_postgres_validation.py`)로는 위 캐스트/FK/CHECK/NOT NULL 못 잡음 — **실데이터 클론만이 검출**.
2. 1절 사전쿼리 전부 PASS. 미스매치 시 정규화 UPDATE 패치 선커밋.
3. `pg_dump` 전체 백업 + 손실 대상 컬럼 별도 export, 복원 테스트.
4. 점검창(0003 락 추정 + 버퍼), 앱 maintenance 모드.
5. `alembic upgrade head` 적용 (단일 트랜잭션 비보장 — ADD VALUE/일부 DDL autocommit, 중단 시 부분 적용 가능).
6. 스모크: `/payments` · `/lessons` · #928 보강크레딧 발급/조회 200, FE 소셜로그인 enum 로드(#815 회귀), `alembic current` = head.
7. 롤백 트리거: 캐스트 실패 / NOT NULL 실패 / `invalid input value for enum` / 스모크 5xx -> 즉시 중단·백업 복원.

## 4. 롤백 전략

- **비가역(downgrade 로 복구 불가) -> 백업 복원만**: `drop_pg_fields_from_payments`, `drop_students_connection_status`, `beta_backend_contract_fixes`(token/scope/target_id), `normalize_teaching_resource_tags`, `0003 timestamptz`(downgrade 시 TZ 손실).
- 기본: `alembic downgrade` 신뢰 금지 -> 3번 백업에서 PITR/full restore. 점검창 안에서만 적용해 부분 실패 시 롤백 윈도우 확보.
- enum 변경은 downgrade 에 `DROP TYPE` 포함 — 부분 중단 시 타입 잔존 가능, 복원 후 수동 `DROP TYPE IF EXISTS` 정리.

## 참고: #928 활성화에 추가로 필요한 FE/BE

- BE: `POST /api/bookings { use_credit, credit_id }` 소비 경로 + `makeup_credits` 마이그레이션은 **이미 repo 에 구현됨**(이 릴리스에 포함). 유일한 갭 = §5.3 `LessonBooking.credit_used` 표시 플래그(미구현, 마이그레이션 추가 필요).
- FE: remote 예약 생성이 `use_credit` 를 BE 로 전달 + mode-aware(remote=BE 소비, mock=FE 소비). 현재는 `createLocalFallbackRepository`/deferred stub 으로 dev/mock 만 동작. 이 릴리스 시점에 flip.

## 근거 파일

`backend/alembic/versions/`: `20260317_..._0003_timestamp_to_timestamptz`, `20260619_0200_resolve_paymenttype_collision_and_card_type_enum`, `20260429_0000_align_booking_status`, `20260429_0100_unify_no_show_policy`, `20260501_0000_drop_pg_fields_from_payments`, `20260619_0100_add_missing_native_enum_values`, `20260601_1100_add_makeup_credits_and_scheduled_lessons`. BE 소비경로: `app/services/schedule_service.py:834,878,989`, `app/schemas/schedule.py:349`, `app/services/makeup_credit_service.py:195`.
