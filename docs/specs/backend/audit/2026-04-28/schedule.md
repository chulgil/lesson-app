# Schedule 도메인 백엔드 API 점검

> 점검일: 2026-04-28
> 점검 범위: schedule.py(7), bookings.py(9), lesson_requests.py(10), scheduler.py(4) — 총 30 endpoints
> 모델: backend/app/models/schedule.py, schedule_ext.py, settings.py(부분)

## 1. SSOT 위치

| 영역 | SSOT |
|------|------|
| Schedule 도메인 동작 규칙 | `docs/specs/schedule/schedule_master.md` (43일 stale 아님 — 03-12 그대로 유효) |
| RequestEvent 챗 SSOT | `frontend/lib/features/schedule/domain/entities/request_event.dart` (백엔드 미구현) |
| Chat guide 매트릭스 | `docs/specs/schedule/chat_guide_message_spec.md` (2026-04-28) |
| Schedule confirmation card | `docs/specs/schedule/schedule_confirmation_card_spec.md` (2026-04-28) |
| Travel time 갭 분석 | `docs/specs/schedule/travel_time_spec.md` §7 (2026-04-28) |
| 4단 우선순위 (휴가/휴무/추가오픈/근무시간) | schedule_master.md §2.3 + 본 audit §3 |
| 백엔드 backend_spec.md | **STALE** (3/16, +55 endpoint 누락) |

## 2. 점검 기준 매트릭스

### 2.1 점검기준 1 — RequestEvent enum 일치

| # | 프론트 (request_event.dart:RequestEventType) | 백엔드 model | 백엔드 endpoint 처리 | 판정 |
|---|----------------------------------------------|--------------|-----------------------|------|
| 1 | `initialRequest` (HiveField 0) | LessonRequest 본체 (별도 event 없음) | POST /lesson-requests | PARTIAL — event 기록 없음 |
| 2 | `approve` / `reject` | RequestStatus.approved/rejected | PATCH /lesson-requests/{id}/status | PARTIAL — status 만 |
| 3 | `proposeAlternative` / `counterPropose` | LessonRequest.time_proposals JSON | POST /propose-alternatives, /counter-propose | FAIL — event row 없음, JSON 덤프 |
| 4 | `acceptAlternative` | RequestStatus.timeConfirmed | POST /accept-alternative | PARTIAL |
| 5 | `proposalSent` / `proposalAccepted` / `paymentNotified` | RequestStatus.proposalSent/proposalAccepted/paymentNotified ✅ | (status 전이 endpoint 없음 — Subscription 쪽으로 분기) | FAIL — schedule 도메인 endpoint 부재 |
| 6 | `paymentConfirmed` / `subscriptionIssued` | **MISSING** in RequestStatus | — | **MISSING** |
| 7 | `lessonCompleted` / `lessonCancelled` / `scheduleChanged` / `lessonNoteAdded` | **MISSING** | — | **MISSING** |
| 8 | `scheduleChangeProposed/Accepted/Rejected/Countered` | LessonScheduleChange.status (alternativeProposed 등) | schedule_ext_service에 함수 존재, **HTTP endpoint 미노출** | **MISSING** (router 미연결) |
| 9 | `subscriptionRenewed` / `subscriptionCompleted` | — | — | **MISSING** |
| 10 | `withdrawApproval` | — | — | **MISSING** |
| 11 | `message` (general chat) | — | — | **MISSING** |
| 12 | RequestEvent 테이블 자체 | **MISSING** (request_events 테이블 없음) | — | **MISSING (P0)** |

→ 프론트는 27 event type을 Hive에 적재. 백엔드는 LessonRequest 1행 + status 전이 + time_proposals JSON 덤프로 압축. **챗 히스토리 재생 불가**.

### 2.2 점검기준 2 — 4단 우선순위 (휴가/휴무/추가오픈/근무시간)

| # | 요구사항 (스펙 §) | 백엔드 model | 백엔드 endpoint | 판정 |
|---|------------------|--------------|------------------|------|
| 1 | ExceptionType.holiday | schedule_ext.py:10 ExceptionType ✅ | POST /schedule/exceptions ✅ | PASS |
| 2 | ExceptionType.vacation | schedule_ext.py:11 ✅ | 동일 | PASS |
| 3 | ExceptionType.additionalSlot | schedule_ext.py:12 ✅ | 동일 | PASS |
| 4 | 근무시간 (WeeklySchedule) | TeacherAvailability + AvailabilityTimeSlot ✅ | GET/PUT /schedule/availability ✅ | PASS |
| 5 | **부분 차단** holiday/vacation startTime/endTime 활용 (travel_time_spec §7.2 케이스 1-2) | schedule_ext.py:66-67 start_time/end_time **필드 존재** | get_available_slots에서 미사용 | **FAIL** — 컬럼은 있는데 슬롯 계산 시 미참조 |
| 6 | TimeException 자체를 슬롯 계산에 반영 | schedule_ext.py ✅ | `schedule_service.py:172 get_available_slots` 에 ScheduleException **조회 누락** | **FAIL (P0)** — 휴무/휴가 등록해도 슬롯이 계속 available 로 나옴 |
| 7 | additionalSlot → 추가 슬롯 노출 | schedule_ext.py ✅ | 동일하게 미반영 | **FAIL** |

→ 모델/enum 은 4단 표현 가능, **그러나 슬롯 생성 로직이 ScheduleException 을 전혀 조회하지 않음**.

### 2.3 점검기준 3 — travel_time 갭

| # | 요구사항 | 백엔드 | 판정 |
|---|---------|--------|------|
| 1 | ClassMembership.travelTimeMinutes | `models/subscription.py` 에 컬럼 부재 (검색 결과 0건) | **MISSING** |
| 2 | ClassMembership.lessonLocationId | 동일 부재 | **MISSING** |
| 3 | Lesson.travelTimeMinutes 복사 | models/lesson.py 부재 | **MISSING** |
| 4 | Booking 충돌 검사 시 travel_time gap 반영 | `schedule_service.py:172 get_available_slots` 는 단순 `booked_times in {}` 만 체크. duration 도 다음 슬롯 시작 간격(30분 hardcoded) 과 겹침 비교 안 함 | **FAIL (P0)** |
| 5 | settings.break_time_between_lessons 적용 | `models/settings.py:19` 컬럼 존재, 슬롯 계산에서 미참조 | **FAIL** |

→ 백엔드 슬롯 계산은 break_time / travel_time / duration overlap 모두 무시. 즉 30분 간격으로 기계적으로 생성하고 동일 시작 시간만 booked 처리.

### 2.4 점검기준 4 — schedule_confirmation_cards (chat_guide source 추적)

| # | 요구사항 | 백엔드 | 판정 |
|---|---------|--------|------|
| 1 | schedule_confirmation_card 모델 | grep 0건 | **MISSING (P1)** |
| 2 | 카드 타입 분기 (afterTrial/reEnrollment/additionalInstrument) | endpoint 0개 | **MISSING** |
| 3 | chat_guide source 컬럼 (가이드 메시지가 어떤 상태에서 왔는지 추적) | LessonRequest.status 만 존재, source/variant 컬럼 없음 | **MISSING** — 프론트는 ChapterGuideVariant.action/wait 으로 분기하나 백엔드는 status 단일 필드 |

## 3. 갭 상세

### P0 — 데이터 손실 / 기능 차단

1. **ScheduleException 이 슬롯 계산에 반영 안됨** (`schedule_service.py::get_available_slots`)
   - 영향: 학생 예약 화면에서 선생님 휴무/휴가 무시하고 예약 가능
   - 권장: `_computeSlotsForDate` 에 ScheduleException 조회 + containsDate 차단 로직 추가. 추가로 startTime/endTime 부분 차단 지원
2. **RequestEvent 테이블/엔티티 부재**
   - 영향: 챗 히스토리(말풍선) 백엔드 동기화 불가, 다중 디바이스/role-switch 시 채팅 빔. 프론트는 27 event 정의했는데 서버가 status 7개로만 표현
   - 권장: `request_events` 테이블 신설 (request_id, actor_type, actor_id, event_type, suggested_slots JSON, scheduled_change_type, ...) + POST/GET endpoint
3. **Booking 충돌 검사 부재 (overlap)**
   - 영향: 14:00 (60분) 예약 후 14:30 슬롯이 여전히 available 로 노출
   - 권장: get_available_slots 에 `booking.scheduled_time + duration` 와 `slot_start + duration` overlap 체크. break_time/travel_time 합산.

### P1 — 기능 차단 (수강권/UX)

4. **schedule_confirmation_cards 미구현**
   - 영향: 수강권 발급 후 학생 대시보드 "스케줄 확정 카드" 가 백엔드 영속 불가 (현재 mock only)
   - 권장: 모델 + POST /subscriptions/{id}/confirmation-card 신설
5. **schedule_change endpoints 라우터 미연결**
   - 영향: schedule_ext_service.create_schedule_change 함수 존재하지만 HTTP 노출 없음. 정기 레슨 시간 변경 협상 불가
   - 권장: schedule.py 또는 신설 schedule_changes.py 라우터 추가
6. **RequestStatus 누락 6종**: subscriptionIssued, paymentConfirmed, lessonCompleted, lessonCancelled, withdrawApproval, scheduleChange*
   - 권장: enum 확장 + 마이그레이션

### P2 — 정합성 (스펙 ↔ 모델)

7. **travel_time 모델 컬럼 부재** (ClassMembership/Lesson)
   - travel_time_spec Phase 1-3 모두 미착수. 프론트 mock 만 동작
8. **break_time_between_lessons 컬럼 → 사용처 0건**
   - settings.py 에 정의했으나 schedule_service 가 무시
9. **LessonScheduleChange 모델 존재하나 프론트 ScheduleChangeType 와 매칭** (singleLesson/bulkChange) — endpoint 누락만 해결되면 PASS

## 4. 결론

| 항목 | 카운트 |
|------|--------|
| 총 점검 항목 | 27 |
| PASS | 4 (ExceptionType 4종 + WeeklySchedule) |
| PARTIAL | 4 (RequestEvent 일부 status 매핑) |
| FAIL | 5 (slot overlap/break/travel/exception 미반영, partial blocking 미지원) |
| MISSING | 14 (RequestEvent 테이블, confirmation_card, status 6종, travel_time 컬럼 3종, schedule_change 라우터, chat_guide source) |

**총평**: 백엔드 schedule 도메인은 모델 enum 은 어느 정도 표현 가능하나 **(a) 슬롯 계산이 충돌/예외 무시 (P0)** 와 **(b) RequestEvent 챗 SSOT 테이블 자체 부재 (P0)** 가 치명적. 프론트가 §7.123 4단 우선순위·RequestEvent SSOT·travel_time gap 까지 확장한 동안 백엔드는 3/16 시점 그대로 정체. backend_spec.md 갱신 + Phase 패치 plan (P0 2건 우선) 권장.
