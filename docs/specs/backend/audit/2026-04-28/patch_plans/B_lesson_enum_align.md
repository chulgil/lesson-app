# Patch Plan B — Lesson Enum Alignment (P0-3, P0-5)

> 적응 품질 모드: **ultra** (alembic 마이그레이션 + enum 변경 = 데이터 영향)
> baseline: `audit/2026-04-28/SUMMARY.md` §3 P0-3/P0-5, `audit/2026-04-28/lesson.md` #6/#7
> SSOT: `docs/specs/lesson/lesson_master.md` §10.2 (BookingStatus 7값) / §10.5 (NoShowPolicy 4값)

---

## 1. Goal

`LessonBooking.status` 와 `GroupClass.no_show_policy` 백엔드 enum 을 lesson_master.md SSOT 와 1:1 정렬하고, 분기된 `IndividualNoShowPolicy` 를 단일 `NoShowPolicy` 로 통합한다.

---

## 2. Architecture (영향 모듈)

```
┌──────────────────────────── 프론트 SSOT ─────────────────────────┐
│ lesson_master.md §10.2  BookingStatus  = 7 (pending/confirmed/  │
│                          changeRequested/completed/cancelled/   │
│                          unavailable/expired)                   │
│ lesson_master.md §10.5  NoShowPolicy   = 4 (deductCredit/       │
│                          halfCredit/noDeduction/reschedule)     │
└─────────────────────────────────┬───────────────────────────────┘
                                  │ 정렬
                                  ▼
┌──────────────────────────── 백엔드 변경 ─────────────────────────┐
│ models/schedule.py                                              │
│   class BookingStatus     ← 7값으로 교체                         │
│   class NoShowPolicy      ← 4값으로 교체 (그룹용 2값 폐기)        │
│ models/schedule_ext.py                                          │
│   class IndividualNoShowPolicy  ← deprecate, NoShowRecord에서   │
│                                   NoShowPolicy 참조로 전환       │
│                                                                 │
│ alembic/versions/                                               │
│   0007_align_booking_status.py        (Phase 1)                 │
│   0008_unify_no_show_policy.py        (Phase 2)                 │
│                                                                 │
│ services/                                                       │
│   schedule_service.py    ← "approved"/"rejected" 문자열 정리    │
│   schedule_ext_service.py ← NoShowRecord.applied_policy 매핑    │
│                                                                 │
│ schemas/                                                        │
│   schedule.py            ← BookingResponse mapping 코멘트 제거  │
│   schedule_ext.py        ← IndividualNoShowPolicy import 제거   │
│                                                                 │
│ api/v1/                                                         │
│   bookings.py    9 endpoints (list/create/get/approve/reject/   │
│                  cancel/change-request/makeup×2)                │
│   groups.py      15 endpoints (no_show_policy 필드 노출 경로)   │
│   lessons.py     20 endpoints (BookingStatus 직접 참조 0건 확인) │
└─────────────────────────────────────────────────────────────────┘
```

영향 row 수 (개발 DB 기준):
- `lesson_bookings.status` — 모든 row, 매핑 테이블 필요
- `group_classes.no_show_policy` — 모든 row, 매핑 테이블 필요
- `no_show_records.applied_policy` — 정렬 후 동일 enum (값 변경 0)

---

## 3. Phase 분해 (TDD)

> **Phase 의존성**: Phase 1 → Phase 3 (라우터 정리) | Phase 2 → Phase 3 | Phase 4 는 1·2·3 모두 종속

### Phase 1 — BookingStatus 정렬 (alembic 0007)

**목표**: `approved`→`confirmed` rename, `unavailable`/`expired` 추가, `noShow`/`rejected` 운명 결정 후 정리.

**Task 1.1 [순차]** — 사용자 결정 수집 (작업 시작 차단)
- [ ] `noShow` 의 운명: (A) BookingStatus 에서 제거 → 기존 row 는 `cancelled` 로 매핑, 노쇼 추적은 `NoShowRecord` 테이블이 SSOT / (B) 비공식 확장으로 유지 → 스펙 §10.2 에 추가 / (C) **unknown — 사용자 결정 필요**
- [ ] `rejected` 의 운명: (A) `cancelled` 로 매핑 + 거절 사유는 `notes` 또는 새 `decline_reason` 컬럼 / (B) 유지 / (C) **unknown — 사용자 결정 필요**
- [ ] 결정 결과를 본 plan §6 매핑표에 확정 기재 후 Phase 1.2 진행

**Task 1.2 [순차]** — Red 테스트 작성
- [ ] `tests/test_booking_status_enum.py::test_booking_status_has_seven_spec_values` (현재 RED)
- [ ] `tests/test_booking_status_enum.py::test_booking_status_rejects_legacy_approved` (현재 RED)
- [ ] `tests/test_booking_status_migration.py::test_upgrade_maps_approved_to_confirmed`
- [ ] `tests/test_booking_status_migration.py::test_downgrade_reverses_mapping`

**Task 1.3 [병렬]** — 모델/스키마 변경
- [ ] `models/schedule.py` `BookingStatus` 7값 교체
- [ ] `schemas/schedule.py` `BookingResponse.model_post_init` 매핑 주석 제거 (§5 참조)

**Task 1.4 [병렬]** — alembic 0007 작성 (reversible)
- `down_revision = "add_reschedule_deadline_hours"`
- `upgrade()`:
  1. PostgreSQL ENUM 신규 생성: `CREATE TYPE bookingstatus_v2 AS ENUM (...)`
  2. `lesson_bookings.status` 컬럼 임시 VARCHAR 캐스팅 → 매핑 SQL 실행 (§6 표) → `USING status::bookingstatus_v2` 로 ALTER
  3. 기존 `bookingstatus` ENUM DROP, `bookingstatus_v2` → `bookingstatus` RENAME
- `downgrade()`: 역순 — 7값 → 7값 ENUM 임시 → 기존 7값(approved/rejected/noShow) 매핑 복원 → 구 ENUM 재생성. **무손실 보장 위해 `notes` 에 매핑 메타 백업** (Task 1.5)

**Task 1.5 [순차, 1.4 후]** — 데이터 백업 정책
- [ ] upgrade 직전 `lesson_bookings_status_backup` 임시 테이블 생성: `(id, original_status, original_notes, migrated_at)`
- [ ] downgrade 시 백업에서 복원
- [ ] 백업 테이블은 Phase 4 검증 통과 후 별도 마이그레이션 0009 에서 DROP

**Task 1.6 [순차, 1.3+1.4 후]** — Green
- [ ] `pytest tests/test_booking_status_enum.py tests/test_booking_status_migration.py -v`
- [ ] alembic upgrade/downgrade 양방향 통과 (`alembic upgrade head && alembic downgrade -1 && alembic upgrade head`)

**완료 기준**: BookingStatus = 스펙 7값, 모든 기존 row 매핑 완료 + 백업 보존, 양방향 마이그레이션 통과.

---

### Phase 2 — NoShowPolicy 통합 (alembic 0008)

**목표**: `IndividualNoShowPolicy` 4값을 정식 `NoShowPolicy` 로 승격, 그룹용 2값(deduct/noDeduct) 폐기.

**Task 2.1 [순차]** — Red 테스트
- [ ] `tests/test_no_show_policy_unified.py::test_no_show_policy_has_four_spec_values`
- [ ] `tests/test_no_show_policy_unified.py::test_individual_no_show_policy_removed_or_aliased`
- [ ] `tests/test_no_show_policy_migration.py::test_deduct_maps_to_deductCredit`
- [ ] `tests/test_no_show_policy_migration.py::test_noDeduct_maps_to_noDeduction`

**Task 2.2 [병렬]** — 모델 변경
- [ ] `models/schedule.py` `NoShowPolicy` 를 4값(`deductCredit/halfCredit/noDeduction/reschedule`)으로 교체
- [ ] `models/schedule.py` `GroupClass.no_show_policy` default = `NoShowPolicy.deductCredit`
- [ ] `models/schedule_ext.py` `IndividualNoShowPolicy` deprecate — `NoShowPolicy` 로 alias (`IndividualNoShowPolicy = NoShowPolicy` + `# DEPRECATED, removed in 0009`)
- [ ] `models/schedule_ext.py` `NoShowRecord.applied_policy` 타입을 `NoShowPolicy` 로 교체

**Task 2.3 [병렬]** — alembic 0008 작성 (reversible)
- `down_revision = "0007_align_booking_status"`
- `upgrade()`:
  1. `CREATE TYPE noshowpolicy_v2 AS ENUM ('deductCredit','halfCredit','noDeduction','reschedule')`
  2. `group_classes.no_show_policy` 매핑: `deduct → deductCredit`, `noDeduct → noDeduction`
  3. `no_show_records.applied_policy` 는 이미 4값 `IndividualNoShowPolicy` 사용 → 같은 enum 으로 ALTER (값 변경 0)
  4. ENUM rename: `noshowpolicy → noshowpolicy_legacy`, `noshowpolicy_v2 → noshowpolicy`, 그리고 `individualnoshowpolicy` ENUM 은 noshowpolicy 와 통합 후 DROP
- `downgrade()`: `deductCredit → deduct`, `halfCredit → deduct` (정보 손실 — backup 테이블에 원본 보존), `noDeduction → noDeduct`, `reschedule → noDeduct`

**Task 2.4 [순차, 2.3 후]** — 정보 손실 백업
- [ ] `group_classes_no_show_backup` 임시 테이블: `(group_class_id, original_policy, migrated_at)`
- [ ] downgrade 가능 보장 — 4→2 다대일 매핑은 본질적으로 손실이지만 backup 으로 복원 가능

**Task 2.5 [순차, 2.2+2.3 후]** — Green
- [ ] `pytest tests/test_no_show_policy_unified.py tests/test_no_show_policy_migration.py -v`
- [ ] alembic 양방향 통과

**완료 기준**: NoShowPolicy = 스펙 4값, IndividualNoShowPolicy alias deprecated, 그룹/개인 단일 enum, 백업 보존.

---

### Phase 3 — 라우터/서비스 enum 사용처 정렬

**목표**: 문자열 `"approved"`, `"rejected"`, `"noShow"` 직접 사용 코드를 enum/매핑 결정에 맞춰 정리.

**Task 3.1 [병렬]** — 서비스 정리
- [ ] `services/schedule_service.py:371` `booking.status = "approved"` → `BookingStatus.confirmed`
- [ ] `services/schedule_service.py:385` `booking.status = "rejected"` → 사용자 결정에 따라 `BookingStatus.cancelled` (+ decline_reason) 또는 유지
- [ ] `services/schedule_service.py:207` `status.in_(["pending","approved"])` → `[BookingStatus.pending, BookingStatus.confirmed]`
- [ ] `services/schedule_service.py:447` `status="approved"` → `BookingStatus.confirmed`

**Task 3.2 [병렬]** — 라우터 시그니처 검증
- [ ] `api/v1/bookings.py` — 9 endpoints, status 문자열 직접 참조 0건 확인 (현재 service 위임)
- [ ] `api/v1/bookings.py:120` `/approve` 라우트는 path 명만 유지, 내부에서 `BookingStatus.confirmed` 로 전이
- [ ] `api/v1/bookings.py:136` `/reject` 라우트는 사용자 결정에 따라 retain 또는 `/cancel` 로 deprecate (별도 plan 권장)
- [ ] `api/v1/groups.py` — 15 endpoints, no_show_policy 필드는 GroupClass 생성/수정 schema 만 영향

**Task 3.3 [병렬]** — 스키마 정리
- [ ] `schemas/schedule.py:206-210` `model_post_init` 의 "Backend 'approved' = Frontend 'confirmed'" 매핑 주석/로직 제거 (이제 동일)
- [ ] `schemas/schedule.py` `BookingCreate.status` 등 string 필드를 `BookingStatus` 로 타입 강화

**Task 3.4 [순차, 3.1~3.3 후]** — 회귀 테스트
- [ ] `pytest tests/ -k "booking or no_show or group_class" -v`
- [ ] `pytest tests/test_scenarios_framework.py -v` 전체 시나리오 통과

**완료 기준**: 코드 전역에서 `"approved"`, `"rejected"`, `"noShow"` 문자열 리터럴 0건 (또는 사용자 결정에 따른 명시적 유지), enum 타입 일관 사용.

---

### Phase 4 — 검증 (e2e + 데이터 무결성)

**Task 4.1 [병렬]** — 데이터 무결성 체크
- [ ] `SELECT status, COUNT(*) FROM lesson_bookings GROUP BY status` — 7값 외 0건
- [ ] `SELECT no_show_policy, COUNT(*) FROM group_classes GROUP BY no_show_policy` — 4값 외 0건
- [ ] `SELECT applied_policy, COUNT(*) FROM no_show_records GROUP BY applied_policy` — 4값 외 0건
- [ ] 백업 테이블 row 수 = 원본 row 수 일치

**Task 4.2 [병렬]** — e2e 시나리오
- [ ] `tests/test_scenario_schedule_integration.py` 전 시나리오 통과
- [ ] 신규 시나리오: `test_fw_booking_lifecycle_pending_to_confirmed`, `test_fw_booking_unavailable_response`, `test_fw_booking_expired_after_48h`
- [ ] 신규 시나리오: `test_fw_no_show_individual_policy_halfCredit_deducts_0_5`, `test_fw_no_show_reschedule_creates_makeup`

**Task 4.3 [순차, 4.1+4.2 후]** — 프론트 연동 smoke
- [ ] `frontend/lib/features/schedule/data/repositories/` Mock 실행 후 BookingStatus enum 매핑 확인
- [ ] beta 서버 deploy 전 staging 에서 alembic upgrade dry-run

**Task 4.4 [순차]** — 문서/스펙 동기화
- [ ] `docs/specs/backend/backend_spec.md` — alembic 0007/0008 추가 기록
- [ ] `docs/specs/backend/database_schema.md` — `noshowpolicy` ENUM 정의 갱신 (line 955)
- [ ] `docs/specs/lesson/lesson_master.md` §10.2 — `noShow`/`rejected` 결정 결과 반영
- [ ] `audit/2026-04-28/lesson.md` #6/#7 PASS 로 갱신

**완료 기준**: 데이터 무결성 100%, e2e 5+ 신규 시나리오 통과, 문서 동기.

---

## 4. 의존성 / 리스크 / 롤백

### 의존성

| 선행 | 후행 | 이유 |
|------|------|------|
| Patch Plan A (RequestEvent SSOT) | 본 plan Phase 4 | RequestEvent 도입 후 BookingStatus 전이 이벤트가 RequestEvent 로 영속되어야 함 |
| Phase 1 | Phase 3 | enum 정의 변경 후에만 사용처 정리 가능 |
| Phase 2 | Phase 3 | 동일 |

### 리스크

| 리스크 | 확률 | 영향 | 완화 |
|--------|------|------|------|
| **데이터 매핑 모호 (`noShow`/`rejected`)** | 高 | 사용자 결정 누락 시 row 손실 | Phase 1.1 사용자 결정 게이트, 미결정 시 Phase 1 진입 차단 |
| 4→2 NoShowPolicy 다대일 손실 | 中 | downgrade 시 정보 손실 | 백업 테이블 영속, downgrade 는 backup 우선 복원 |
| Native ENUM ALTER 시 락 | 中 | 운영 DB 다운타임 | 별도 ENUM v2 생성 → swap 패턴, online migration |
| 프론트 Hive 캐시 충돌 | 高 | 앱 크래시 (#Cherry HiveType 회귀) | beta deploy 후 사용자 앱 강제 재설치 안내 또는 BookingStatus typeId 미변경 확인 |
| Group class booking 의 GroupBookingStatus 와 혼동 | 低 | 그룹용 booking enum 은 별도 (`schedule_ext.py:GroupBookingStatus`) | 본 plan 범위 외 명시 |

### 롤백

- Phase 1 단독 롤백: `alembic downgrade -1` (백업 테이블에서 원본 status 복원)
- Phase 2 단독 롤백: `alembic downgrade -1` (백업 테이블에서 원본 policy 복원, 정보 손실은 backup 으로 무손실)
- 전체 롤백: `alembic downgrade add_reschedule_deadline_hours` (Phase 1+2 모두 reverse)
- 백업 테이블은 Phase 4 무결성 통과 + 1주일 모니터링 후 별도 0009 마이그레이션에서 DROP

---

## 5. Lore Trailer (커밋 시 부착)

```
Lore-directive: BookingStatus 7값 정렬 — 프론트 SSOT (lesson_master.md §10.2) 우선
Lore-directive: NoShowPolicy 4값 통합 — IndividualNoShowPolicy alias deprecate 후 0009 에서 제거
Lore-constraint: alembic 0007/0008 reversible 필수, 다대일 매핑은 백업 테이블로 무손실
Lore-rejected: BookingStatus 7값 + noShow/rejected 9값 유지 — 스펙 SSOT 원칙 위반
Lore-rejected: NoShowPolicy 그룹/개인 분기 유지 — 도메인 enum 두 진원지는 #19 SSOT 위반
```

---

## 6. 사용자 결정 필요 (unknown)

> Phase 1.1 게이트 — 미결정 시 작업 차단

### 6.1 `BookingStatus.noShow` 의 운명

| 옵션 | 매핑 | 영향 |
|------|------|------|
| **A (권장)** | 제거. 기존 `noShow` row → `cancelled` + `NoShowRecord` 테이블로 영속 | SSOT 준수, 노쇼 추적은 전용 테이블 |
| B | 스펙 §10.2 에 `noShow` 추가 (8값) | 스펙 변경 필요, frontend Hive typeId 영향 |
| C | unknown — 사용자 결정 필요 | — |

### 6.2 `BookingStatus.rejected` 의 운명

| 옵션 | 매핑 | 영향 |
|------|------|------|
| **A (권장)** | `cancelled` + `decline_reason` 컬럼 추가 (또는 `notes` 활용) | SSOT 준수, 거절 사유 보존 |
| B | 스펙 §10.2 에 `rejected` 추가 (8값) | 스펙 변경 필요 |
| C | unknown — 사용자 결정 필요 | — |

### 6.3 `BookingLessonType.makeup` (P2 #12, 본 plan 범위 외)

- 백엔드 4값 vs 스펙 3값. 본 plan 은 §10.8 변경을 포함하지 않음 — 별도 P2 plan 권장.

### 매핑 표 (Phase 1.1 결정 후 확정)

```
# 현재 BookingStatus → 새 BookingStatus
pending          → pending           (유지)
approved         → confirmed         (rename)
rejected         → ???               (사용자 결정 §6.2)
cancelled        → cancelled         (유지)
completed        → completed         (유지)
noShow           → ???               (사용자 결정 §6.1)
changeRequested  → changeRequested   (유지)
(신규)           → unavailable       (추가)
(신규)           → expired           (추가)

# 현재 NoShowPolicy → 새 NoShowPolicy
deduct           → deductCredit      (rename)
noDeduct         → noDeduction       (rename)
(신규)           → halfCredit        (추가)
(신규)           → reschedule        (추가)
```

---

## 7. 평가 기준 (Rubric, 합격 7.5)

| 기준 | 가중 | 합격선 | 측정 |
|------|------|--------|------|
| 완성도 | 40% | 8/10 | spec §10.2/§10.5 7+4 enum 1:1 정렬, 매핑 무손실 |
| 견고성 | 30% | 7/10 | upgrade/downgrade 양방향 통과, 백업 테이블 무결성, 신규 e2e 5+ |
| 일관성 | 20% | 8/10 | 코드 전역 문자열 리터럴 0건, IndividualNoShowPolicy alias 단일 |
| 간결성 | 10% | 7/10 | alembic 2건, plan 400줄 이내, Phase 4단 |

---

## 8. TDD 테스트 예시

### 8.1 BookingStatus enum 정렬

```python
# tests/test_booking_status_enum.py
import pytest
from app.models.schedule import BookingStatus


def test_booking_status_has_seven_spec_values():
    """spec §10.2 의 7값과 1:1 일치."""
    expected = {
        "pending", "confirmed", "changeRequested",
        "completed", "cancelled", "unavailable", "expired",
    }
    actual = {s.value for s in BookingStatus}
    assert actual == expected, f"diff: {actual ^ expected}"


def test_booking_status_rejects_legacy_approved():
    """레거시 'approved' 값은 더 이상 BookingStatus 멤버 아님."""
    with pytest.raises(ValueError):
        BookingStatus("approved")
```

### 8.2 alembic 0007 데이터 매핑

```python
# tests/test_booking_status_migration.py
import pytest
from sqlalchemy import text
from alembic.config import Config
from alembic import command


@pytest.mark.asyncio
async def test_upgrade_maps_approved_to_confirmed(db_session, alembic_config: Config):
    """기존 'approved' status row 가 upgrade 후 'confirmed' 로 정렬."""
    # Arrange — 0006 상태로 다운그레이드 후 'approved' row 삽입
    command.downgrade(alembic_config, "add_reschedule_deadline_hours")
    await db_session.execute(text(
        "INSERT INTO lesson_bookings (id, teacher_id, student_id, "
        "scheduled_date, scheduled_time, status) VALUES "
        "('b1', 't1', 's1', '2026-05-01', '10:00', 'approved')"
    ))
    await db_session.commit()

    # Act — 0007 upgrade
    command.upgrade(alembic_config, "0007_align_booking_status")

    # Assert — 매핑 결과 'confirmed'
    result = await db_session.execute(
        text("SELECT status FROM lesson_bookings WHERE id = 'b1'")
    )
    assert result.scalar() == "confirmed"

    # Assert — 백업 테이블에 원본 보존
    backup = await db_session.execute(
        text("SELECT original_status FROM lesson_bookings_status_backup "
             "WHERE id = 'b1'")
    )
    assert backup.scalar() == "approved"
```
