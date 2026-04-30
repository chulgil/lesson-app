# Lesson Domain Backend Audit (2026-04-28)

> Phase 1B — Lesson 도메인 백엔드 vs `lesson_master.md` SSOT 정합성 점검.
> 점검자: Claude (Lesson 도메인 분석)
> 점검 시점 baseline: backend HEAD, spec lesson_master.md (last 2026-04-23, §13.2 DRIFT 6건 검증 반영 커밋 63f3bfa9)

## 1. SSOT 위치

- **도메인 정의 SSOT**: `docs/specs/lesson/lesson_master.md` (§10 Enum, §11 매핑, §13.2 DRIFT 표)
- **프론트 enum 진원지**: `frontend/lib/features/lessons/domain/entities/lesson.dart` (LessonStatus 10값)
- **RequestEvent SSOT**: `frontend/lib/features/schedule/domain/entities/request_event.dart` (typeId 130/131/132, 27 event types) — 커밋 c85f3aa0 로 강화
- **백엔드 진원지 부재**: `backend/app/models/lesson.py` 는 LessonStatus 10값을 보유하나 lesson 도메인 외 RequestEvent / MakeupLesson FK / FifthWeekPolicy 통합은 누락

## 2. 점검 매트릭스

| # | 요구사항 (스펙 §) | 프론트 코드 | 백엔드 endpoint | 백엔드 model | 판정 |
|---|---|---|---|---|---|
| 1 | §10.1 LessonStatus 10값 (scheduled, completed, cancelled, cancelledByStudentAdvance/Late, cancelledByTeacher, cancelledMutual, noShow, studentAbsent, reschedulePending) | `lesson.dart:LessonStatus` | PATCH `/lessons/{id}/status` (string passthrough) | `lesson.py:LessonStatus` 10값 동일 | **PASS** |
| 2 | §5.2 Lesson 노트 필드 (feedback, keyPoints[], practiceTips, recordings[]) | `lesson.dart` | PUT `/lessons/{id}/feedback` | `lesson.py:Lesson` (feedback Text, key_points JSON, practice_tips Text) + `LessonRecording` 모델 존재 | **PASS** (단 §3 참조) |
| 3 | §6.1/§6.5 LessonLocationInfo (name, address) 저장 | `LessonLocationSection` | LessonCreate.location_name | `Lesson.location_name`, `Lesson.location_address` (DB), `LessonLocation` 별도 모델 | **PASS** (location_address Update 누락은 §3.4 참조) |
| 4 | §6.3 자동 프리필 1단계 `Student.defaultLocationId` | (Phase 2 미구현, 프론트도 없음) | — | `Student` 모델에 default_location_id 필드 없음 | **MISSING** (스펙·프론트·백엔드 모두 미구현, Phase 2 deferred) |
| 5 | §6.3 자동 프리필 2단계 `LessonClass.defaultLocation` | 미구현 | — | `LessonClass` 모델에 default_location_id 없음 | **MISSING** (Phase 2 deferred) |
| 6 | §10.2 BookingStatus 7값 (pending/confirmed/changeRequested/completed/cancelled/unavailable/expired) | `lesson_booking.dart` | bookings 라우터 | `schedule.py:BookingStatus` 7값 (**pending/approved/rejected/cancelled/completed/noShow/changeRequested**) | **FAIL** — 스펙 ≠ 백엔드. `confirmed`→`approved`, `unavailable`/`expired` 누락, 스펙 외 `noShow`/`rejected` 추가 |
| 7 | §10.5 NoShowPolicy 4값 (deductCredit, halfCredit, noDeduction, reschedule) | `no_show_policy.dart` | groups 라우터 (group class) | `schedule.py:NoShowPolicy` **2값** (deduct, noDeduct) ↔ `schedule_ext.py:IndividualNoShowPolicy` **4값** (정합) | **FAIL** — 두 enum 분기. 그룹 클래스용 2값과 개인용 4값이 별도 정의 |
| 8 | §10.6 MakeupStatus 5값 (pending/scheduled/completed/expired/**waived**) + MakeupReason 4값 | `makeup_lesson.dart` | (endpoint 없음) | `policy.py:MakeupStatus` 5값 — 스펙 `waived`가 백엔드는 `cancelled` | **FAIL** — `waived` ≠ `cancelled` (의미 다름: 면제 vs 취소). MakeupReason enum 부재 |
| 9 | §10.6 MakeupLesson 엔티티 (originalLessonId, scheduledLessonId, expiresAt 30일 기본) | `makeup_lesson.dart` | **endpoint 없음** | `policy.py:MakeupLesson` 모델 존재 (scheduled_lesson_id 필드 부재) | **FAIL** — 모델 있으나 라우터 0개, scheduled_lesson_id 누락 |
| 10 | §10.7 FifthWeekPolicy 4값 (skip/optional/credit/always) | (Dart enum 정의만, 미연동 — 스펙 §10.7 명시) | — | **백엔드 enum 부재**, `LessonPolicy` 에 fifth_week_policy 필드 없음 | **MISSING** |
| 11 | §3.6 시나리오 D / RequestEvent SSOT — 일괄/단건 변경 chat history | `request_event.dart` (typeId 132 ScheduleChangeType, 27 RequestEventType) | (endpoint 없음) | `schedule_ext.py:LessonScheduleChange` 모델 + ScheduleChangeType/Status enum **존재** — 스펙 §11에서는 `LessonScheduleChange` deprecate 결정 (커밋 c85f3aa0) | **STALE** — 스펙·프론트는 `RequestEvent` SSOT, 백엔드는 폐기 결정된 `lesson_schedule_changes` 테이블 잔존. RequestEvent 모델·테이블 부재 |
| 12 | §10.8 LessonType 3값 (trial/regular/oneTime) | `lesson_booking.dart:LessonType` | — | `schedule.py:BookingLessonType` **4값** (trial/regular/oneTime/**makeup**) | **STALE** — 백엔드가 보강(+makeup) 했으나 스펙 미반영 |
| 13 | §3.6 노쇼 NoShowRecord (lesson_id, applied_policy, deducted_credits, makeup_lesson_id) | `no_show_policy.dart:NoShowRecord` | (endpoint 없음) | `schedule_ext.py:NoShowRecord` 모델 존재 | **MISSING** — 모델만 있고 endpoint 없음 |
| 14 | §13.2 DRIFT-1 레슨 장소 (60% Phase 1) | LessonLocationSection | locations 라우터 7개 | `LessonLocation` 모델 | **PASS** |
| 15 | §13.2 DRIFT-2 스케줄 확인 카드 (50%) | `schedule_confirmation_card.dart` 172줄 | (endpoint 없음, schedule 라우터 7개 중 카드 미노출) | `policy.py:ScheduleConfirmationCard` 모델 존재 | **FAIL** — 모델 존재, endpoint 0개. 프론트 174 위젯/Provider도 호출 경로 부재 |
| 16 | §13.2 DRIFT-3 FCM 푸시 (40% 인프라) | `FcmService` | device_tokens 라우터 2개 | `device_token` 모델 | **PASS** (인프라만, 알림 발송 통합은 별건) |
| 17 | §13.2 DRIFT-4 레슨 노트 히스토리 (BROKEN 라우트) | `LessonNoteHistoryScreen` | GET `/lessons` (filter student_id) — 전용 endpoint 없음 | — | **STALE** — 프론트 라우트 미등록(BROKEN), 백엔드는 list 재활용 |
| 18 | §13.2 DRIFT-5 빠른 레슨 등록 (0%) | 미구현 | — | — | **MISSING** (모두 미착수, 일치) |
| 19 | §13.2 DRIFT-6 정기 레슨 등록 (60%) | proposal 플로우 파편화 | subscriptions 라우터 18개 | subscription 모델 | (Phase 1D Subscription audit 범위로 위임) |
| 20 | §11.1 LessonPiece 엔티티 | `lesson.dart:LessonPiece` | LessonCreate.pieces[] 입력 가능 | `lesson.py:LessonPiece` 테이블 존재 | **FAIL** — 모델·schema 존재하나 `LessonService.create()` 가 pieces 무시 (코드 90~98 라인), `update()` 도 `exclude={"pieces"}` |
| 21 | §11.1 LessonRecording 엔티티 | `lesson.dart:LessonRecording` | recordings 라우터 7개 (별도) | `lesson.py:LessonRecording` 테이블 | **PASS** (recordings 도메인 별건) |
| 22 | §3.5 paymentConfirmed/isUnpaid (Subscription) | `subscription.dart` | subscriptions 라우터 | (Phase 1D 범위) | (위임) |
| 23 | §10.3 AvailabilitySlotStatus 5값 / §10.4 SlotStatus 3값 | schedule entities | schedule 라우터 | (Phase 1A Schedule audit 범위) | (위임) |

## 3. 갭 상세

### P0 (데이터 손실 / 정합성 critical)

| # | 갭 | 영향 | 권장 조치 |
|---|---|---|---|
| 6 | **BookingStatus 스펙↔백엔드 불일치** | 프론트는 `confirmed/unavailable/expired` 발신 → 백엔드는 알 수 없는 값으로 거부 또는 enum mismatch 500. 예약 승인/만료 플로우 전체 차단 | 백엔드 enum을 스펙 7값으로 정렬 (`approved`→`confirmed`, `unavailable`/`expired` 추가). alembic 마이그레이션 + 데이터 매핑 필수 |
| 7 | **NoShowPolicy 그룹용 2값 / 개인용 4값 분기** | 개인 레슨에서 §10.5 4값 정책(`halfCredit`/`reschedule`) 백엔드 적용 경로 모호 — `IndividualNoShowPolicy`는 `NoShowRecord` 에만 사용, `LessonPolicy` 의 정책 필드는 boolean 평면 | `LessonPolicy` 에 `no_show_policy: IndividualNoShowPolicy` 컬럼 추가, 프론트 정책 설정 UI ↔ 백엔드 매핑 |
| 11 | **RequestEvent SSOT 백엔드 미반영** | 프론트 chat history 27 event type의 영속화 경로 부재. 일정변경/취소/협상 이벤트 모두 메모리 in Hive only | `request_events` 테이블 신설(actor_type, actor_id, event_type, suggested_slots JSON, schedule_change_type, proposed_*, subscription_id, session_number). 폐기된 `lesson_schedule_changes` 마이그레이션 |

### P1 (기능 차단)

| # | 갭 | 영향 | 권장 조치 |
|---|---|---|---|
| 9 | **MakeupLesson endpoint 0개** | 보강 생성/조회/소진 API 부재 → §3.6 보강 추적 시스템 전체 비활성. `scheduled_lesson_id` 필드도 누락 | makeup 라우터 신설 (POST/GET/PATCH), 모델에 scheduled_lesson_id 추가 |
| 8 | **MakeupStatus `waived`↔`cancelled` 의미 충돌** | 면제 처리 vs 취소가 같은 값으로 저장 → 통계/리포트 왜곡 | 백엔드 enum에 `waived` 추가, alembic 마이그레이션 |
| 13 | **NoShowRecord endpoint 0개** | 모델만 있고 노쇼 기록/조회 API 부재 → §3.6 노쇼 자동 처리 미작동 | noshow 라우터 신설 (POST 자동 처리, GET 조회) |
| 15 | **ScheduleConfirmationCard endpoint 0개** | 모델 존재하지만 발급/응답 endpoint 부재 → §3.3 Phase 4 학생 스케줄 확인 1탭 미작동 | scheduler/schedule 라우터에 confirmation_cards CRUD 추가 |
| 20 | **LessonService.create() pieces 무시** | 프론트가 보낸 LessonPiece 배열이 무시됨 → 곡명 표시 0건 | service.create() 에 pieces insert 추가 |

### P2 (정합성 / 향후 정렬)

| # | 갭 | 권장 조치 |
|---|---|---|
| 4, 5 | Student.defaultLocationId / LessonClass.defaultLocation Phase 2 deferred | 스펙 §6.3 1~2단계는 deferred 표기 일치 — 모델 컬럼 추가 시점에 마이그레이션 동기화 |
| 10 | FifthWeekPolicy 백엔드 enum 부재 | §10.7 "현재 코드에 아직 반영되지 않음" 명시와 일치하나, 정기 레슨 결제 자동화 진입 전 필수 |
| 12 | BookingLessonType 에 `makeup` 추가됨 (스펙 미반영) | 스펙 §10.8 에 makeup 추가 또는 백엔드에서 제거 |
| 17 | 레슨 노트 히스토리 전용 endpoint 부재 | 학생별 노트 timeline GET endpoint 추가 (현재 list 재활용 무리) |

## 4. 결론

- 총 점검 항목: **23**
- **PASS: 5** (LessonStatus, 노트 필드, 위치 저장 phase1, 노트 base, recordings 분리)
- **FAIL: 6** (BookingStatus, NoShowPolicy 분기, MakeupStatus waived, MakeupLesson endpoint, ScheduleConfirmationCard endpoint, LessonService.pieces 무시)
- **MISSING: 5** (Student/LessonClass defaultLocation, FifthWeekPolicy, NoShowRecord endpoint, 빠른 레슨 등록)
- **STALE: 3** (RequestEvent SSOT 미반영, 레슨노트 히스토리 BROKEN, LessonType makeup 스펙 누락)
- **위임: 4** (Subscription/Schedule audit 범위)

**최우선 P0 갭**: #6 BookingStatus enum 불일치, #11 RequestEvent SSOT 백엔드 부재, #7 NoShowPolicy 분기 — 세 건 모두 alembic 마이그레이션 동반 필요.

**후속 patch plan 권장**: P0 3건 + P1 5건을 단일 마이그레이션 (`0008_lesson_request_event_ssot`) 묶음으로 처리. P2 는 Phase 2 통합 갭 리포트에서 우선순위 재평가.
