# Patch Plan A — RequestEvent SSOT 통합 + Slot 충돌/예외 반영

> Plan ID: `audit/2026-04-28/A_request_event_ssot`
> Adaptive Quality: **ultra** (스키마 마이그레이션 + 다중 도메인 영향, 데이터 이관 동반)
> 대응 P0 갭: **P0-1** (slot 계산 결손) · **P0-2** (`request_events` 부재) · **P0-4** (RequestEvent SSOT 백엔드 미반영 + `lesson_schedule_changes` 폐기)
> 작성일: 2026-04-28
> 후속 plan 분리: B (Lesson enum 정렬), C (Subscription 만료 cron) 와 독립 진행. 단 B 의 BookingStatus 변경과 본 plan 의 slot 계산 변경은 충돌 가능 → 5.1 의존성 참조.

---

## 1. Goal

프론트 `RequestEvent` 27 event SSOT 를 백엔드에 1:1 영속화하고, `get_available_slots` 가 ScheduleException · booking overlap · break_time 을 반영하도록 통합한다. 폐기 결정된 `lesson_schedule_changes` 데이터는 `request_events` 로 이관 후 drop.

---

## 2. Architecture

```
┌──────────────────────────────── Frontend (SSOT) ────────────────────────────────┐
│  request_event.dart  RequestEventType(27) + ScheduleChangeType(2) + RequestEvent│
│       │                                                                          │
│       │  HTTP                                                                    │
└───────┼──────────────────────────────────────────────────────────────────────────┘
        ▼
┌────────────── Router (FastAPI) ─────────────┐    ┌──────────── Router ─────────────┐
│ /lesson-requests/{id}/events                │    │ /schedule/slots (P0-1 수정)     │
│   POST  append_event                        │    │   GET get_available_slots       │
│   GET   list_events                         │    │     ↓ 통합                      │
└──────────────┬──────────────────────────────┘    └──────────────┬──────────────────┘
               │                                                   │
               ▼                                                   ▼
┌─────────────────────────── Service Layer ────────────────────────────────────────┐
│ RequestEventService                          │ ScheduleService.get_available_slots│
│   append_event()  → INSERT request_events    │   (1) availability rows            │
│   list_events()   → SELECT order by created  │   (2) ScheduleException 차단/추가  │
│   replay_status() → 챗 재생 (다기기 sync)    │   (3) booking overlap 검사         │
│                                              │   (4) break_time/duration overlap  │
└──────────────┬───────────────────────────────┴────────────────┬───────────────────┘
               │                                                  │
               ▼                                                  ▼
┌─────────────────────────────── Models / DB ──────────────────────────────────────┐
│ request_events (NEW)                         │ schedule_exceptions (existing)     │
│   id, request_id FK, actor_type, actor_id,   │ teacher_availabilities (existing)  │
│   event_type(27), suggested_slots JSON,      │ lesson_bookings (existing)         │
│   selected_slot_index, message,              │ settings.break_time_between_lessons│
│   schedule_change_type(2), proposed_dow,     │   (existing, 미참조 → 참조 시작)   │
│   proposed_time, subscription_id,            │                                    │
│   session_number, created_at                 │                                    │
│                                              │                                    │
│ lesson_schedule_changes (DEPRECATED)         │                                    │
│   → 데이터 이관 후 drop (Phase 4)            │                                    │
└──────────────────────────────────────────────┴────────────────────────────────────┘
```

핵심: **단일 진실 소스 = `request_events` 테이블**, `lesson_schedule_changes` 행은 본 plan 안에서 `request_events.scheduleChangeProposed` 등 4 event 로 변환 후 테이블 drop.

---

## 3. Phase 분해 (TDD)

각 phase 는 **RED → GREEN → IMPROVE** 루프를 적용하고, `verification.md` 의 Red-Green 사이클(되돌리면 실패)을 마이그레이션·서비스·라우터 모두 검증한다.

### Phase 1 — 모델 + 마이그레이션 (예상 4h)

목표: `request_events` 테이블 신설. 폐기 테이블은 phase 4 까지 유지.

| Step | 행동 | TDD 산출물 |
|------|------|-----------|
| 1.1 | `backend/app/models/request_event.py` 신설 — `RequestEventType` (27 값) + `ScheduleChangeType` (2 값) + `RequestEvent` SQLAlchemy 모델 (15 컬럼) | 모델 import 테스트 |
| 1.2 | `backend/alembic/versions/20260428_0000_add_request_events.py` — `upgrade()`: CREATE TABLE + 3 인덱스 (`request_id`, `event_type`, `created_at`). `downgrade()`: DROP TABLE | alembic upgrade/downgrade 왕복 테스트 |
| 1.3 | `backend/app/models/__init__.py` 에 export 추가 | `from app.models import RequestEvent` 통과 |
| **[병렬]** 1.4 | `backend/app/schemas/request_event.py` — `RequestEventCreate`, `RequestEventResponse` Pydantic | schema 직렬화 테스트 |

검증:
- `pytest backend/tests/test_request_events_model.py -v` → 4/4 PASS
- `alembic downgrade -1 && alembic upgrade head` → 무손실 왕복

### Phase 2 — 서비스 레이어 (예상 8h)

목표: (a) `RequestEventService` 신설, (b) `get_available_slots` 통합 수정.

#### Phase 2A — RequestEventService

| Step | 행동 | TDD 산출물 |
|------|------|-----------|
| 2A.1 | `backend/app/services/request_event_service.py` 신설 — `append_event(data)`, `list_events(request_id)`, `replay_status(request_id)` | unit test 3개 |
| 2A.2 | `replay_status` 는 event 시퀀스를 받아 `RequestStatus` 종결값 추론 (terminal event 우선: cancel/expire/subscriptionCompleted/reject) | replay 시나리오 5종 (정상승인/거절/대안수락/취소/만료) |
| **[병렬]** 2A.3 | `lesson_request_service.py` 의 status 변경 함수 (`approve`, `reject`, `propose_alternative`, `accept_alternative`) 가 변경 시점에 자동으로 `append_event` 호출하도록 hook 추가 — 기존 `time_proposals` JSON 덤프와 **이중 기록**(phase 4 에서 단일화) | hook 호출 stub 검증 |

#### Phase 2B — get_available_slots 통합

| Step | 행동 | TDD 산출물 |
|------|------|-----------|
| 2B.1 | `schedule_service.py:172` 에 ScheduleException 조회 추가. `ExceptionType.holiday/vacation` → 슬롯 차단, `additionalSlot` → 슬롯 추가. 부분 차단(`start_time`/`end_time` not null) 지원 | 시나리오 4 케이스 (전일휴무/오전반차/오후반차/추가오픈) |
| 2B.2 | Booking overlap 검사 — 기존 `slot_time in booked_times` 단순 매치를 `slot_start + duration` ↔ `booking.scheduled_time + booking.duration` 구간 겹침으로 변경 | overlap 테스트 (14:00-15:00 예약 후 14:30 슬롯 차단 검증) |
| **[병렬]** 2B.3 | `settings.break_time_between_lessons` 적용 — booking 종료 후 break 만큼 다음 슬롯 차단 | break 5/10/15분 테스트 |
| 2B.4 | travel_time 은 본 plan 범위 외(P1-4 별도). 단, `_compute_blocked_intervals()` 헬퍼를 분리해 향후 travel_time 추가가 단일 함수 수정으로 끝나도록 설계 | 헬퍼 추출 리팩토링 검증 |

검증:
- `pytest backend/tests/test_schedule_slots_integration.py -v` → 8/8 PASS
- Red-Green: 2B.1 적용 전 vacation 등록 → slot 노출 (FAIL), 적용 후 차단 (PASS)

### Phase 3 — HTTP 라우터 (예상 3h)

| Step | 행동 | TDD 산출물 |
|------|------|-----------|
| 3.1 | `backend/app/api/v1/lesson_requests.py` 에 2개 endpoint 추가:<br>- `POST /lesson-requests/{request_id}/events` (event append)<br>- `GET /lesson-requests/{request_id}/events` (event list, pagination) | 라우터 contract test 2개 |
| **[병렬]** 3.2 | `backend/app/api/v1/schedule.py` — `LessonScheduleChange` 4 event (`scheduleChangeProposed/Accepted/Rejected/Countered`) 발신 endpoint 신설 (또는 기존 `schedule_ext_service.create_schedule_change` 함수를 `request_events` 로 라우팅) | 라우터 P1-1 차단 해소 검증 |
| 3.3 | `lesson_request_service` 의 `propose_alternative`/`counter_propose` 응답에 새로 생성된 event id 포함 → 프론트 optimistic update 정렬 | API contract 테스트 |

검증:
- `pytest backend/tests/test_lesson_requests.py::test_event_endpoints -v` → 통과
- OpenAPI schema diff — endpoint 4개 추가 (POST/GET events + schedule_change 노출)

### Phase 4 — 폐기 정리 + 데이터 이관 (예상 5h)

> **CRITICAL**: 본 phase 는 ultra 모드. `/code-review` + `/security-review` 2회 + handoff-verify 5회 루프.

| Step | 행동 | TDD 산출물 |
|------|------|-----------|
| 4.1 | `backend/alembic/versions/20260428_0001_migrate_lsc_to_request_events.py` — `upgrade()`: 기존 `lesson_schedule_changes` 모든 행을 SELECT → `request_events` 로 INSERT 변환 매핑:<br>  · `pending` → `scheduleChangeProposed`<br>  · `approved` → `scheduleChangeAccepted`<br>  · `rejected` → `scheduleChangeRejected`<br>  · `alternativeProposed` → `scheduleChangeCountered`<br>  · `cancelled` → `cancel`<br>  `request_id` 매핑은 `(student_id, teacher_id)` 페어로 가장 최근 lesson_request 매핑. 매핑 실패 시 `migration_orphans` 임시 테이블로 격리. | 더미 데이터 5건 변환 테스트 |
| 4.2 | `lesson_request_service.py` 의 이중 기록(2A.3) 제거 — `time_proposals` JSON 덤프 deprecate, `request_events` 단일화. 기존 컬럼은 유지 (읽기 전용 호환) | 이중기록 단일화 검증 |
| 4.3 | `backend/alembic/versions/20260428_0002_drop_lesson_schedule_changes.py` — `upgrade()`: DROP TABLE. `downgrade()`: CREATE TABLE 원형 복구 (4.1 데이터는 복구 불가, 주석 명시) | downgrade 시 빈 테이블 복구 확인 |
| **[병렬]** 4.4 | `schedule_ext.py` 에서 `LessonScheduleChange` 모델 + 2 enum (`ScheduleChangeType`, `ScheduleChangeStatus`) 제거. `schedule_ext_service.py` 의 관련 함수 제거 (또는 `request_events` 위임) | dead code grep 0건 |
| 4.5 | 운영 DB 백업 → 4.1 dry-run → 4.1 실제 적용 → 4.3 적용 순서. 각 단계 사이 5분 관찰 | 단계별 row count 검증 |

검증:
- `alembic upgrade head` → 모든 행 이관 + 폐기 테이블 drop
- `alembic downgrade -3` → 4.3 → 4.1 → Phase 1 순서 역행, `request_events` 비워지고 `lesson_schedule_changes` 빈 상태 복구

### Phase 5 — 시나리오 테스트 (예상 4h)

목표: `RequestEvent` 챗 재생 + 슬롯 충돌 방지가 사용자 시나리오에서 동작하는지 E2E 검증.

| Step | 행동 | TDD 산출물 |
|------|------|-----------|
| 5.1 | `tests/scenarios/helpers.py` 에 `TeacherActions.append_event()`, `StudentActions.list_chat_events()` 추가 | helper smoke test |
| **[병렬]** 5.2 | `tests/test_scenarios_request_event.py` 신설 — 시나리오:<br>  · 챗 재생 (생성→대안→수락→완료 4 event 재생) <br>  · 다기기 sync (선생님 디바이스 A 가 event 추가 → 학생 디바이스 B 가 GET 으로 동일 순서 수신) <br>  · role-switch (학생→학부모 전환 시 채팅 비지 않음) | 3 시나리오 PASS |
| **[병렬]** 5.3 | `tests/test_scenario_schedule_integration.py` 에 vacation/booking-overlap/break-time 3 케이스 추가 | 3 시나리오 PASS |
| 5.4 | `docs/specs/backend/scenario_testing_guide.md` 시나리오 목록 업데이트 (rules/scenario-testing.md 요구) | 문서 갱신 |

검증:
- `pytest backend/tests/test_scenarios_request_event.py -v` → 3/3 PASS
- `pytest backend/tests/test_scenario_schedule_integration.py -v` → 신규 3건 포함 모두 PASS
- 전체 회귀: `pytest backend/tests/ -v` → 0 fail

---

## 4. TDD 첫 번째 테스트 (RED 작성, 구현 전 실패 확인)

### 4.1 `request_events` 테이블 + 모델 (Phase 1 첫 RED)

```python
# backend/tests/test_request_events_model.py
import pytest
from sqlalchemy import select


@pytest.mark.asyncio
async def test_request_event_persists_27_event_types(db_session, teacher, student):
    """RequestEvent 모델은 27 event_type 모두 저장/조회 가능해야 한다 (P0-2)."""
    from app.models.request_event import (
        RequestEvent,
        RequestEventType,
        ScheduleChangeType,
    )
    from app.models.schedule import LessonRequest

    # 사전: lesson_request 1건
    req = LessonRequest(student_id=student.id, teacher_id=teacher.id, expires_at="2026-12-31")
    db_session.add(req)
    await db_session.flush()

    # 27 event 모두 INSERT
    for et in RequestEventType:
        evt = RequestEvent(
            request_id=req.id,
            actor_type="teacher",
            actor_id=teacher.id,
            event_type=et,
            schedule_change_type=ScheduleChangeType.singleLesson if et.name.startswith("scheduleChange") else None,
        )
        db_session.add(evt)
    await db_session.flush()

    # 27 행 모두 SELECT 가능
    rows = (await db_session.scalars(
        select(RequestEvent).where(RequestEvent.request_id == req.id)
    )).all()
    assert len(rows) == 27, f"기대 27 event, 실제 {len(rows)}"
    assert {r.event_type for r in rows} == set(RequestEventType)
```

**RED 확인 절차**: Phase 1.1 모델 작성 전 실행 → `ImportError: cannot import name 'RequestEvent'` 로 실패해야 함. Phase 1.1 + 1.2 적용 후 GREEN.

### 4.2 `get_available_slots` × ScheduleException 통합 (Phase 2B 첫 RED)

```python
# backend/tests/test_schedule_slots_integration.py
import pytest
from datetime import date


@pytest.mark.asyncio
async def test_vacation_blocks_slot_generation(db_session, teacher_with_availability):
    """ExceptionType.vacation 등록일은 슬롯이 0건이어야 한다 (P0-1)."""
    from app.models.schedule_ext import ExceptionType, ScheduleException
    from app.services.schedule_service import ScheduleService

    target_date = date(2026, 5, 1)  # 금요일 09:00-18:00 availability 가정

    # 휴가 등록
    exc = ScheduleException(
        teacher_availability_id=teacher_with_availability.availability_id,
        type=ExceptionType.vacation,
        start_date=target_date,
        end_date=target_date,
        start_time=None,  # 전일 차단
        end_time=None,
        reason="개인 휴가",
    )
    db_session.add(exc)
    await db_session.flush()

    service = ScheduleService(db_session)
    response = await service.get_available_slots(
        teacher_id=teacher_with_availability.user_id,
        date=target_date.isoformat(),
        duration=60,
    )

    # 현재(Phase 2B 적용 전): 슬롯 9개 노출 (BUG, P0-1)
    # 적용 후: 슬롯 0개
    assert len(response.slots) == 0, (
        f"vacation 등록일에 슬롯이 {len(response.slots)}개 노출 — P0-1 회귀"
    )
```

**RED 확인 절차**:
1. Phase 2B 적용 전 실행 → 9 slot 노출로 FAIL (P0-1 재현)
2. Phase 2B.1 적용 후 실행 → PASS
3. **Red-Green 사이클 검증**: 2B.1 revert → FAIL 재발 확인 → 다시 적용 → PASS (verification.md §Red-Green)

---

## 5. 의존성 / 리스크 / 롤백

### 5.1 의존성

| 의존 | 영향 | 처리 |
|------|------|------|
| Plan B (BookingStatus enum 정렬) | Phase 2B.2 의 booking overlap 검사가 `status.in_(["pending","approved"])` 사용. B 적용 후 `approved`→`confirmed` 로 변경됨 | B 가 머지되면 본 plan 의 2B.2 코드도 `confirmed` 로 동시 패치. 두 plan 동시 진행 시 매주 1회 머지 동기화 회의 |
| Plan C (만료 cron) | 독립. 단 만료 시 `expire` event 자동 발신이 Plan A 의 `append_event` API 사용 | C 는 본 plan Phase 3 완료 후 진입 |
| `lesson_request_service` 기존 호출자 (frontend) | event hook 추가가 응답 latency 5ms 미만 증가 | latency 회귀 테스트 추가 (5ms 이내) |
| `time_proposals` JSON 컬럼 | Phase 4.2 deprecate. 기존 프론트가 읽기로 사용 중일 수 있음 | grep 으로 frontend 사용처 확인 → 미사용 확인 후 deprecate |

### 5.2 리스크 (우선순위 순)

| # | 리스크 | 확률 | 영향 | 완화 |
|---|--------|------|------|------|
| **R1** | Phase 4.1 데이터 이관 시 `(student_id, teacher_id)` ↔ `lesson_request` 매핑 실패로 orphan 발생 | 중 | 챗 히스토리 누락 | `migration_orphans` 임시 테이블로 격리 + 운영자 수동 매핑 도구 |
| R2 | Phase 2B 슬롯 알고리즘 변경으로 기존 booking 화면 회귀 | 중 | 학생 예약 화면 슬롯 카운트 차이 | scenario_schedule_pingpong 회귀 테스트 + 베타 환경 24h 관찰 |
| R3 | Phase 4.3 DROP TABLE 후 외부(분석/백오피스) 의존성 발견 | 저 | 분석 쿼리 실패 | DROP 7일 전 backend_spec.md 공지 + grep 으로 SQL 파일 외부 참조 검색 |
| R4 | `request_events` 행 수 폭증 (event 27 종 × request 수) | 중 | 인덱스 스캔 저하 | `(request_id, created_at)` 복합 인덱스 + 1년 이상 행 partition (별건 plan) |
| R5 | Phase 2A.3 이중 기록으로 race condition (event 순서 뒤집힘) | 저 | 챗 순서 뒤바뀜 | `created_at` UTC 마이크로초 + sequence 컬럼 보강 |

### 5.3 롤백 plan

각 phase 별 독립 롤백:
- Phase 1: `alembic downgrade -1` — 모델 import 만 되돌리면 됨
- Phase 2: 코드 revert (DB 변경 없음)
- Phase 3: 라우터 코드 revert (DB 변경 없음)
- Phase 4.1 (데이터 이관): downgrade 불가 — **운영 적용 전 백업 필수**. 백업본으로 `lesson_schedule_changes` 복구
- Phase 4.3 (drop): `alembic downgrade -1` 로 빈 테이블 재생성 + 백업본에서 행 복구

전체 롤백: `alembic downgrade <phase 1 직전 revision>` — request_events 사라지나 lesson_schedule_changes 복구는 별도 백업 의존.

---

## 6. 평가 기준 (Rubric)

| 기준 | 가중 | 합격 | 측정 |
|------|------|------|------|
| 완성도 | 40% | 8/10 | P0-1/P0-2/P0-4 3건 모두 검증 PASS, 27 event_type 영속화, vacation/booking-overlap/break-time 3 시나리오 통과 |
| 견고성 | 30% | 7/10 | pytest 모든 신규 테스트 PASS + 회귀 0건, alembic 왕복 무손실, Red-Green 사이클 4.2 명시 |
| 일관성 | 20% | 8/10 | 도메인 린터 (model→service→router 폴더 구조), 기존 SQLAlchemy 2.0 패턴 준수, schedule_ext_service 와 동일 네이밍 |
| 간결성 | 10% | 7/10 | request_event_service.py 300줄 미만, 기존 `time_proposals` JSON 덤프 deprecate 로 중복 제거 |

**합격선 가중평균 7.5 이상**. 어느 항목 5 미만이면 무조건 FAIL.

---

## 7. 사용자 결정 필요 (Unknown)

1. **Phase 4.1 매핑 정책**: `lesson_schedule_changes.requested_by` 가 NULL 인 historical 행을 어떤 actor 로 표기할 것인가? (`teacher` 추정 vs `system` 신규 actor_type 신설)
2. **`time_proposals` JSON 컬럼 deprecate 시점**: Phase 4.2 즉시 vs 다음 마이너 릴리스(2 sprint 후)까지 dual-write 유지

---

## 8. Lore

```
Lore-directive: RequestEvent 27 event SSOT = request_events 테이블 단일화 (frontend Hive ↔ backend 1:1)
Lore-directive: get_available_slots 는 ScheduleException + booking overlap + break_time 통합 책임
Lore-constraint: Phase 4.3 lesson_schedule_changes DROP 은 데이터 이관 + 7일 공지 후만 허용
Lore-rejected: time_proposals JSON 덤프 유지 — 챗 재생/다기기 sync/role-switch 3건 모두 불능, SSOT 위반
Lore-rejected: schedule_change 별도 테이블 유지 — 동일 챗 흐름이 두 테이블로 분리되어 재생 시 sequence 정렬 비용 발생
```
