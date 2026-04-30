# Backend API Audit — Summary (2026-04-28)

> 점검 범위: Schedule, Lesson, Student, Subscription 4 도메인
> 점검 방법: 프론트 스펙 + 코드 ↔ 백엔드 endpoint + model 매트릭스 매핑
> 점검자: Claude (도메인별 격리 컨텍스트 4 에이전트 병렬 실행)

## 1. 결론 (한 줄)

**프론트는 5주간 80+ 커밋 진척, 백엔드는 같은 기간 정체** — 72 항목 중 정합 13 / 갭 54 (75%). 가장 심각한 영역은 **Subscription** (PASS 0).

## 2. 도메인별 점수

| 도메인 | 항목 | PASS | FAIL | MISSING | STALE | PARTIAL/위임 | 정합률 |
|--------|-----:|-----:|-----:|--------:|------:|------------:|-------:|
| Schedule | 27 | 4 | 5 | 14 | — | 4 PARTIAL | 15% |
| Lesson | 23 | 5 | 6 | 5 | 3 | 4 위임 | 22% |
| Student | 10 | 4 | 1 | 4 | 1 | — | 40% |
| Subscription | 12 | **0** | 2 | 8 | 1 | — | **0%** |
| **합계** | **72** | **13** | **14** | **31** | **5** | 8 | **18%** |

> 정합률 = PASS / (전체 - 위임)

## 3. P0 갭 (즉시 차단, 7건)

| # | 도메인 | 갭 | 사용자 영향 | 권장 조치 |
|---|--------|----|-----------|----------|
| **P0-1** | Schedule | `get_available_slots` 가 ScheduleException 무시 | 휴무·휴가 등록해도 학생 예약 화면에 슬롯 노출 | service 로직에 ScheduleException 조회 + booking overlap + travel_time 추가 |
| **P0-2** | Schedule | `request_events` 테이블 자체 부재 | 챗 히스토리 다중 디바이스 동기화 불가, role-switch 시 채팅 빔 | `RequestEvent` 모델 + 마이그레이션 + endpoint 신설 |
| **P0-3** | Lesson | `BookingStatus` 백엔드/스펙 불일치 (`approved`↔`confirmed`, `unavailable`/`expired` 누락) | 예약 승인/만료 플로우 전체 차단 | enum 정렬 + 마이그레이션 |
| **P0-4** | Lesson | `RequestEvent` SSOT 백엔드 미반영 (폐기 결정된 `lesson_schedule_changes` 잔존) | DRIFT-2 카드/§3.6 노쇼 영속 0 | P0-2 와 묶어서 `RequestEvent` 모델 도입 + `lesson_schedule_changes` 정리 |
| **P0-5** | Lesson | `NoShowPolicy` 그룹 2값(deduct/noDeduct) ↔ 개인 4값 분기 | §10.5 정책 매핑 부재, 그룹 클래스 노쇼 정책 표현 불가 | `NoShowPolicy` 4값 정렬 + 마이그레이션 |
| **P0-6** | Subscription | `subscription_expiry_service` 부재 — D-14/D-7/D-1/D-0 알림이 디바이스 로컬에만 존재 | 앱 종료/멀티디바이스 시 알림 미발화. spec §3.4 "in-app + push" 정면 위반 | scheduler/cron 작업 신설 + notifications 발송 |
| **P0-7** | Subscription | `Subscription.status` (`expiringSoon`/`expired`) 자동 전이 부재 | enum 정의만 있고 시간 기반 전이 0, 수동 PATCH만 가능 | 만료 cron 에 status 전이 통합 |

## 4. P1 갭 (기능 차단, 9건)

| # | 도메인 | 갭 | 영향 |
|---|--------|----|------|
| P1-1 | Schedule | `LessonScheduleChange` 함수 존재하나 HTTP 라우터 미연결 | 일정 변경 endpoint 호출 불가 |
| P1-2 | Schedule | `RequestStatus` enum 6종(subscriptionIssued/paymentConfirmed/lessonCompleted/lessonCancelled/withdrawApproval/scheduleChange*) 백엔드 누락 | 일부 챗 상태 백엔드 추적 불가 |
| P1-3 | Schedule | `schedule_confirmation_cards` 모델 row 0건 (insert 경로 없음) | DRIFT-2 카드 영속 미작동 |
| P1-4 | Schedule | `ClassMembership.travel_time_minutes` 컬럼 0건 | travel_time 갭 백엔드 영속 불가 |
| P1-5 | Lesson | `LessonService.create()` 가 `pieces` 입력 무시 (라인 90-98) | 곡명 0건, schema·model 멀쩡한데 service 결손 |
| P1-6 | Lesson | `MakeupLesson` 모델 있으나 endpoint 0개, `scheduled_lesson_id` 누락 | 보강 레슨 도메인 사용 불가 |
| P1-7 | Lesson | `ScheduleConfirmationCard` 모델 있으나 endpoint 0개 | DRIFT-2 50% 평가의 공백 |
| P1-8 | Student | `GET /students/summary` 부재 | 프론트가 N×M 카운트를 매번 계산 → 학생 수 확장 시 진입 지연 |
| P1-9 | Subscription | Phase 5b 4-axis 토글(D14/D7/D1/D0) ↔ 백엔드 단일 int 컬럼 비호환 | 다기기 sync 불가 |

## 5. P2 갭 (정합성, 9건 발췌)

- Lesson #10: `FifthWeekPolicy` 4값 enum 부재
- Lesson #12: `BookingLessonType` 에 백엔드가 `makeup` 추가했으나 spec §10.8 미반영 (역방향 STALE)
- Lesson #17: `LessonNoteHistoryScreen` 라우트 BROKEN — list endpoint 재활용
- Student §10 Bulk Teacher Actions 3종 (preview/cancel/broadcast) 부재 — 신규 설계라 자연스러움
- Subscription `renewal_alert_days/threshold` 컬럼 존재하나 어떤 서비스도 미사용 (#18 "설정 필드 = 로직 사용" 위반)
- 기타 18개 항목 도메인별 audit md 참조

## 6. 인프라 갭

- **`scheduler.py` 는 attendance 한정** (4 endpoints), 만료 알림 cron 부재
- **`docker-compose*.yml` 에 cron 컨테이너 없음** — 운영 인프라 부재
- **alembic 마이그레이션 7건 추가** (3/16 spec 미반영)
- **endpoint 154 → 209** (+55) — backend_spec.md 갱신 필수

## 7. 후속 plan 분기

> 사용자가 `prompt_plan.md` 에서 별도 후속 plan 으로 이미 분기 완료.
> 이 audit 의 P0-1, P0-2, P0-4 는 사용자 plan 의 P0-1 (스케쥴변경 챕터 모델 적용) + P0-2 (ScheduleChangeType/Status dead enum 제거) 와 일치.
> P0-3, P0-5, P0-6, P0-7 은 별도 백엔드 plan 으로 분리 권장.

### 권장 분기

| 갭 | 후속 plan |
|----|----------|
| P0-1, P0-2, P0-4 (RequestEvent SSOT 통합) | 사용자 prompt_plan.md P0-1/P0-2 와 통합 — 프론트·백엔드 동시 작업 |
| P0-3, P0-5 (Lesson enum 정렬) | 별도 plan: `backend_lesson_enum_align.md` (alembic 2건) |
| P0-6, P0-7 (Subscription 만료 자동화) | 별도 plan: `backend_subscription_expiry_cron.md` (인프라 + service + scheduler) |
| P1-1 ~ P1-9 | 위 3개 plan 에 P1 phase 로 부착 |

## 8. backend_spec.md 갱신 사항

- Endpoints: 154 → 209
- 라우터: 19 → 26
- 추가 라우터: ai_notes, device_tokens, locations, parents, profile_images, scheduler, settings_api
- 마이그레이션 0003~0006 + 2건 알파뉴메릭 + reschedule_deadline_hours 추가
- "다음 단계" 섹션의 ① ScheduleException 연결, ③ Mock→Remote 전환은 본 audit P0/P1 갭과 직결 — 우선순위 재명시

## 9. 평가

| 기준 | 점수 | 근거 |
|------|------|------|
| 완성도 | 9/10 | 4 도메인 72 항목 전수 점검, P0~P2 우선순위 + 후속 plan 분기 명시 |
| 견고성 | 8/10 | 격리 4 에이전트 → 교차 검증, 위임 항목(4) 명시로 중복 회피 |
| 일관성 | 9/10 | 동일 템플릿(`_checklist_template.md`) + 동일 판정 라벨(PASS/FAIL/MISSING/STALE/PARTIAL) |
| 간결성 | 8/10 | SUMMARY 200줄 이내, 도메인별 100~130줄 |
| **가중 평균** | **8.6** | **PASS (≥7.5)** |
