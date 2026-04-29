# 추천 액션 순서 P0~P2 — 통합 plan

> 작성일: 2026-04-28
> 모드: `/plan --eng` + adaptive-quality **ultra** (스펙 정렬 + 마이그레이션 + 다중 화면 영향)
> 사용자 결정: 추천 순서대로 진행 (P0→P1→P2)

## 요구사항 재정의

5개 우선순위 작업을 단계화해 진행:

| 우선순위 | 작업 | 핵심 변경 |
|---|---|---|
| **P0-1** | 스케쥴변경에 챕터 모델 적용 | `ScheduleChangeSlotScreen` 을 `RequestDetailScreen` 패턴(Masthead+ProgressBar+ChapterSummary+RequestHistoryChat+CurrentRequestBox) 으로 재구성 |
| **P0-2** | ScheduleChangeType/Status dead enum 제거 | `RequestEvent.scheduleChangeType` SSOT 정착, 미사용 잔재 정리 |
| **P1-1** | 스펙 동기화 — 가이드 2색, 확정카드, travel_time | `chat_guide_message_spec` ↔ 코드 매트릭스 정합 + travel_time §7 4 갭 케이스 패치 |
| **P1-2** | 레슨신청 세부 수정 | AppBar 통일, Phase 2 액션박스 3경로 카드, 가이드 색상 분기 정합성 |
| **P2** | i18n AppStrings 마이그레이션 | Phase 5-1h(booking_reschedule) → 5-1i → 5-2 lessons → 5-3 subscription |

## 핵심 발견 (탐색 결과)

- ✅ **공통 위젯 이미 존재**: `core/widgets/chapter_guide_box.dart`, `core/widgets/chapter_summary.dart`, `features/schedule/presentation/widgets/request_history_chat.dart` — 새 위젯 추출 불필요
- ✅ **RequestEvent SSOT 이미 통합**: `RequestEvent.scheduleChangeType` 필드 존재 — dead enum 제거가 핵심
- ✅ **spec 이미 작성됨**: `chat_guide_message_spec.md`, `schedule_confirmation_card_spec.md` — 코드 정합만
- ❌ **travel_time §7 갭 4 케이스**: 부분 차단 / 반차 vacation / 차단경계 incoming travel / 차단직후 outgoing travel — 코드 미구현

## 아키텍처

```
P0-1 (재구성)  →  P0-2 (정리)  →  P1-1 (스펙+travel)  →  P1-2 (UI세부)  →  P2 (i18n)
                                                                        ↑
                                                            (Phase 5-1h 부터 이어서)
```

## P0-1 Phase 분해

### Phase A — 분석 & 매핑 표
- `ScheduleChangeSlotScreen` 현재 구조 라인별 매핑
- `RequestDetailScreen` 의 챕터 패턴 (1410줄) 분해
- 두 화면 공통 차이점 → 재구성 디프 plan

### Phase B — 재구성 적용
- AppBar → Masthead
- Body 를 `CustomScrollView` 또는 `ListView` 로 chapterSummary + history + requestBox 순서로 재구성
- 기존 AlternativeTimeGrid 흐름 보존 (제안 슬롯 선택 로직)

### Phase C — Smoke Test + 회귀
- `test/features/schedule/screens/schedule_change_slot_layout_test.dart` 추가 (BoxConstraints 크래시 방지)
- `flutter analyze` 0 / `flutter test` 통과
- 실기 확인 (학생 경로)

## P0-2 — 완료 (2026-04-28 검증)

phase_a_mapping.md 분석 + 추가 grep 결과:

- frontend: `ScheduleChangeStatus` 호출처 0건 (이미 제거됨)
- frontend: `ScheduleChangeType` 은 `RequestEvent.scheduleChangeType` SSOT 로 정착 (request_event.dart §16-41)
- backend: `ScheduleChangeStatus` 는 `RegularLessonScheduleChange.status` 컬럼에서 active 사용 — dead 아님 (schedule_ext.py §46-50, §181-184)

코드 작업 불필요. P0-2 close.

## P1-1 Phase 분해

### Phase A — 스펙↔코드 정합 ✅ 완료 (commit 0ed0d3c7)
- chat_guide_message_spec 12 상태 ↔ `_getPhaseGuide()` 일치
- schedule_confirmation_card_spec 3타입 ↔ `schedule_confirmation_card_widget` 일치

### Phase B — travel_time §7 4 케이스 패치 ✅ 완료 (2026-04-28)
- `TimeException.containsDateTimeRange(date, slotStart, slotEnd)` 추가
- `_computeSlotsForDate`: 부분 차단 슬롯만 제외 (whole-day 역호환 유지)
- 회귀 테스트 5건 (4 케이스 + 역호환), 5/5 PASS, schedule scope 237/237 통과
- TimeException UI 부분 차단 시간 입력 → 별도 phase 로 분리 (entity 만 준비)

### Phase C — 검증 ✅ 완료
- `flutter analyze lib/features/schedule/ test/features/schedule/` 0 issues
- `flutter test test/features/schedule/` 237/237 PASS
- 스펙 동기화: `travel_time_spec.md` §7.4/7.5 갱신

## P1-2 — 완료 (2026-04-29 검증)

### Phase A — AppBar 통일 ✅ 완료 (commit 99c26539, W2 번들)
- `AllLessonRequestsScreen` (line 60-65) + `SuggestAlternativeScreen` (line 147-152) → `NotebookTypography.appBarTitle` 적용
- `RequestDetailScreen._buildChatAppBar` (line 334) — 기존부터 적용 (§7.27 기준)
- 검증: `flutter analyze` 0 / `flutter test test/features/schedule/` 237/237 PASS

### Phase B — Phase 2 3경로 카드 ✅ 완료 (이미 정렬)
- 3 경로 (선불/후불/무료) 는 `current_request_box.dart` 가 아닌 `proposal_bottom_sheet.dart::_buildPaymentMethodSelector` (line 224-272) 에 위치
- chip 시각 일관성 OK: 선택 시 `paperAccent` bg + `paper` text + w600, 미선택 시 transparent + `inkSecondary`
- `current_request_box.dart::_buildPhase2PaymentChoice` 는 단일 진입 버튼 → BottomSheet 호출

### Phase C — 가이드 색상 2색 분기 ✅ 완료 (검증)
- `request_history_chat.dart::_getPhaseGuide()` 12 상태 전수 확인 → `ChapterGuideVariant.action / .wait` 2색만 사용
- `ChapterGuideVariant.neutral` 은 `_PhaseGuide` default 정의용, 어느 케이스도 사용 안 함 (5색 회피 정합)

## P2 진행 상황

- 5-1a~5-1g 완료 (commits: df846fab, 1a290003, 1accb9d6, b1580850, 5f4d5c2a, b0c96b58, 37090589)
- 5-1h booking_reschedule_screen 완료 (2026-04-29) — 17 신규 키 + 4 재사용 (cancel, cannotLoadData, rescheduleUsageStatusWithColon, rescheduleNoMoreAfter), 20 사이트, schedule scope 237/237 PASS
- 5-1i schedule_tab + lesson_requests + request_detail 완료 (2026-04-29) — 10 신규 키 + 7 재사용 (retry, lessonComplete, statusCompleted, actionLessonCancel, cancel, goBack, errorOccurred), 20 사이트, schedule scope 237/237 PASS
- 5-1j request_completion + unified_lesson_request + my_bookings 완료 (2026-04-29) — 30 신규 키 + 7 재사용 (requestCompleteTitle, lessonTypeLabel, instrumentFallback, teacher, durationMinutesValue, cannotLoadData, statusCompleted, cancel), 30 사이트, schedule scope 237/237 PASS
- 5-2 lessons 도메인
- 5-3 subscription 도메인

## 평가 기준 (Rubric, 합격선 7.5)

| 기준 | 가중 | 목표 |
|---|---|---|
| 완성도 | 40% | 8/10 — P0~P1 spec 갭 없음 |
| 견고성 | 30% | 7/10 — 회귀 없음, smoke test |
| 일관성 | 20% | 8/10 — 도메인 린터 통과, 공통 위젯 재사용 |
| 간결성 | 10% | 7/10 — 800줄/50줄 룰 |

## 리스크

| 등급 | 리스크 | 완화 |
|---|---|---|
| HIGH | ScheduleChangeSlotScreen 재구성으로 학생 경로 깨짐 | smoke test + 실기 확인 |
| HIGH | ScheduleChangeStatus 제거 시 Hive 마이그레이션 | grep 0 확인 후 제거, mock 검증 |
| MEDIUM | travel_time 패치가 기존 슬롯 생성 회귀 | unit test 4 케이스 + 회귀 케이스 1 |
| LOW | i18n 회귀 | Phase 5-1a~g 패턴 그대로 |

## 다음 단계

| 작업 | 상태 |
|---|---|
| P0-1 / P0-2 / P1-1 / P1-2 Phase A·B·C | ✅ 완료 (2026-04-29) |
| P2 5-1h booking_reschedule_screen i18n (20 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-1i schedule_tab + lesson_requests + request_detail i18n (20 사이트) | ✅ 완료 (2026-04-29) |
| P2 5-1j request_completion + unified_lesson_request + my_bookings i18n (30 사이트) | ✅ 완료 (2026-04-29) |
| **다음** P2 5-2 lessons 도메인 / 5-3 subscription 도메인 | 진입 |
| P1-1 후속 — TimeException UI 부분 차단 시간 입력 | 별도 phase |

> **세션 분할 전략**: 한 세션에 P0-1 한 phase 단위. ultra 모드 검증 강도 유지.

---

## 이전 계획

# 백엔드 API 구현 점검 (Audit Plan)

> 작성일: 2026-04-28
> 모드: `/plan --eng`
> 사용자 결정: yes (전체 4 도메인 audit 진행)

요구사항·범위·Phase 0~2 백엔드 audit 본문은 `docs/specs/backend/audit/2026-04-28/` 폴더와 git history (commit `60f48cef` 이전) 참조.

---

## 더 이전 계획

§7.127 Gaegu 손글씨 4계층 SSOT 정착 — 시스템 자동 뱃지 hand 해제 (Phase 1·2·3·5 완전 적용, Phase 4·6 보류·분리, 가중 평균 9.5 PASS). 본문은 git history 참조.
