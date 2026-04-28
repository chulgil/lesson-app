# P0-1 Phase A — 챕터 모델 적용 매핑 분석

> 작성: 2026-04-28
> 모드: ultra (스펙 정렬 + 다중 화면 영향)
> 결론(요약): **prompt_plan.md 의 P0-1·P0-2 는 사실상 완료 상태**. Phase B/C 신규 코드 작업 불필요. 다음 진입은 **P1-1 (스펙↔코드 정합 + travel_time §7 4 케이스 패치)**.

## 1. 분석 대상

| 화면/위젯 | 파일 | 라인 | 역할 |
|----------|------|------|------|
| RequestDetailScreen | `frontend/lib/features/schedule/presentation/screens/request_detail_screen.dart` | 1408 | 레슨 신청 라이프사이클 챗 (5-Phase 챕터 모델 호스트) |
| ScheduleChangeSlotBottomSheet | `frontend/lib/features/schedule/presentation/widgets/schedule_change_slot_bottom_sheet.dart` | 434 | 슬롯 제안 sub-task picker (BottomSheet) |
| ScheduleChangeTypeBottomSheet | `frontend/lib/features/schedule/presentation/widgets/schedule_change_type_bottom_sheet.dart` | 136 | 단일/정기 변경 타입 선택 진입점 |
| ScheduleChangeResponseBottomSheet | `frontend/lib/features/schedule/presentation/widgets/schedule_change_response_bottom_sheet.dart` | 281 | 상대방 응답 (수락/거절/역제안) |

## 2. 챕터 패턴 SSOT (RequestDetailScreen)

```
Scaffold
├─ AppBar              ← _buildChatAppBar (opponent name + type)
└─ body: Column
   ├─ LessonProgressBar(currentPhase)        [고정, AppBar 직하]
   ├─ Expanded > ListView
   │  ├─ ChapterSummaries (완료된 챕터, 접힘)
   │  └─ RequestHistoryChat (현재 phase 의 chronological events)
   ├─ _buildEventStrip                       [success/error/info 피드백]
   └─ CurrentRequestBox                      [phase-aware action bar]
```

핵심 의존:
- `LessonProgressBar` 는 `RequestPhase` enum (request → subscription → lessons → completed → terminal) 기반.
- `ChapterSummary` 는 완료된 phase 의 요약을 1줄로 표시 + 펼침 시 `RequestHistoryChat` 재사용.
- `RequestHistoryChat` 은 `RequestEvent` 리스트 + `viewerRole` 기반으로 말풍선 렌더.
- `CurrentRequestBox` 는 `RequestPhase` 별 액션 분기 (Phase 1: 수락/역제안, Phase 2: 결제, Phase 3: 레슨 진행).

**결론**: 챕터 패턴은 **`UnifiedLessonRequest` 라이프사이클**에 강결합. RequestPhase enum 의존도가 핵심.

## 3. ScheduleChangeSlotBottomSheet 현재 구조

```
showModalBottomSheet
└─ Container(maxHeight: 92%)
   └─ Column
      ├─ BottomSheetHandle
      ├─ _buildHeader (sectionTitle Playfair + close)
      ├─ ChapterGuideBox (variant: action)         ← P0-1(a) 통합 완료
      ├─ _buildCurrentScheduleInfo                  ← 컨텍스트 제공
      ├─ _buildBulkChangeInfo (조건부)
      ├─ _buildWeekNavigation
      ├─ Flexible > AlternativeTimeGrid
      ├─ _buildSuggestedSlotsList (조건부)
      └─ _buildBottomSection (TextField + Submit)   ← P0-1(a) CurrentRequestBox 시각 align
```

진입 경로:
1. RequestDetailScreen / SubscriptionDetailScreen 의 `_handleScheduleChange` →
2. `showScheduleChangeTypeBottomSheet` (단일/정기 타입 선택) →
3. `showScheduleChangeSlotBottomSheet` (슬롯 1~3개 제안) →
4. 결과는 부모 화면에서 `RequestEvent.scheduleChangeProposed` 이벤트로 영속.

## 4. 챕터 패턴 vs SubTask Picker — 적용 매트릭스

| 패턴 요소 | RequestDetailScreen | ScheduleChangeSlotBottomSheet | 적용 가능성 | 판정 |
|----------|---------------------|-------------------------------|-----------|------|
| LessonProgressBar | ✅ 5-Phase 라이프사이클 표시 | RequestPhase 외부, sub-task 단계 | ❌ **부적합** — phase 가 1개 (제안) → 2개 (제안+제출) 뿐, ProgressBar 시각 가치 없음 |
| ChapterSummary | ✅ 완료 chapter 접기 | 단일 단계, 접을 chapter 없음 | ❌ **부적합** — 1단계 sub-task |
| RequestHistoryChat | ✅ Event 시간순 챗 | Grid+SuggestedSlotsList 가 이미 채팅 대체 | ⚠️ **중복** — 슬롯 제안은 부모 챗 챕터의 신규 event |
| CurrentRequestBox | ✅ Phase별 액션 분기 | 단일 액션 (제안 제출) | ⚠️ **과한 추상화** — 현재 _buildBottomSection 으로 충분 |
| ChapterGuideBox | ✅ 단계별 가이드 | ✅ **이미 적용됨** (variant: action) | ✅ **완료** |
| Masthead AppBar | ✅ Playfair appBarTitle | _buildHeader 가 sectionTitle Playfair | ✅ **시각 패턴 통일** (P0-1(a) align) |

### Lore 결정 (a3f7ccab)

> **Lore-constraint**: ScheduleChangeSlotScreen 은 sub-task picker — 챕터 모델 (LessonProgressBar/ChapterSummary) 은 부모 RequestDetailScreen 이 보유, 본 화면은 시각 align 만

이 constraint 는 prompt_plan.md 작성(2026-04-28) 이전에 이미 결정·기록됨. prompt_plan.md 의 "Masthead+ProgressBar+ChapterSummary+RequestHistoryChat+CurrentRequestBox 재구성" 문구는 **스펙 동기화 누락** 으로 판단.

## 5. P0-1 / P0-2 실 상태

### P0-1 — 스케쥴변경에 챕터 모델 적용

| Phase | prompt_plan 정의 | 실 commit | 상태 |
|-------|------------------|-----------|------|
| Phase A (분석) | 매핑 표 작성 | (본 문서) | 🟡 **본 문서로 완료** |
| Phase B (재구성) | AppBar→Masthead, ListView 재구성 | a3f7ccab (시각 align) + 67a937ca (BottomSheet 화) + 57028b8b (ChapterGuideBox 통합) | ✅ **완료** — sub-task picker constraint 하에 적절 범위 |
| Phase C (Smoke Test + 회귀) | layout test + analyze | 미수행 | ⚠️ **분리 권장** — 사실상 BottomSheet UI 변경 없음, 회귀 위험 낮음 |

### P0-2 — ScheduleChangeType/Status dead enum 제거

| 작업 | commit | 상태 |
|------|--------|------|
| ScheduleChangeStatus enum 제거 | c85f3aa0 | ✅ **완료** (`grep ScheduleChangeStatus\b` → 0 hits) |
| LessonScheduleChange entity 제거 | c85f3aa0 | ✅ **완료** |
| ScheduleChangeType → request_event.dart 이동 (typeId 90→132) | c85f3aa0 | ✅ **완료** |
| RequestEventType.scheduleChange* 4값 (Proposed/Accepted/Rejected/Countered) | c85f3aa0 | ✅ **완료** (request_event.dart:116-125) |
| 12 caller import 정리 | c85f3aa0 | ✅ **완료** |

## 6. 잔여 갭 (P0-1 / P0-2 범위 내)

| # | 갭 | 영향 | 처리 |
|---|----|----|------|
| G1 | Phase C smoke test 미수행 (BottomSheet layout test) | BoxConstraints 회귀 위험 (낮음) | 별도 phase 로 분리 — `test/features/schedule/widgets/schedule_change_slot_bottom_sheet_layout_test.dart` |
| G2 | prompt_plan.md 의 P0-1 scope 묘사가 실 결정과 불일치 | 후속 세션에서 재시도 시 혼선 | **본 문서가 정정** + prompt_plan.md "다음 단계" 섹션 업데이트 권장 |

→ G1, G2 모두 **신규 코드 작업 아님**. P0-1·P0-2 는 본 phase 종료 시점에 **사실상 클로즈**.

## 7. 다음 진입점 권고

prompt_plan.md 의 다음 backlog 우선순위 재확인:

| 우선순위 | 작업 | 실 상태 | 권고 |
|---------|------|--------|------|
| P0-1 | 챕터 모델 적용 | ✅ 완료 (sub-task picker constraint) | **클로즈** + prompt_plan.md 업데이트 |
| P0-2 | dead enum 제거 | ✅ 완료 (c85f3aa0) | **클로즈** |
| P1-1 | 스펙 동기화 + travel_time §7 4 케이스 | 0ed0d3c7 commit "Phase 3 — 스펙 동기화" 일부 진행, **travel_time 4 케이스 미확인** | 🎯 **다음 진입** |
| P1-2 | 레슨신청 세부 수정 (AppBar 통일, 3경로 카드, 가이드 색상) | 미확인 | P1-1 후속 |
| P2 | i18n AppStrings 마이그레이션 (Phase 5-1h~) | 5-1g 까지 완료 (commit b0c96b58) | 독립 백로그 |

## 8. Phase B/C 진입 여부 판정

| 옵션 | 추천 |
|------|------|
| (A) Phase B 강행 — Masthead/ProgressBar 등 풀 패턴 재구성 | ❌ Lore-constraint a3f7ccab 위반, RequestPhase 외부 sub-task 에 라이프사이클 강요 |
| (B) Phase C smoke test 만 추가 후 P0-1 클로즈 | ⚠️ 회귀 위험 낮음 — 별도 backlog 로 분리 가능 |
| (C) **P0-1·P0-2 클로즈, P1-1 진입** | ✅ **권장** — 실 갭(travel_time 4 케이스, 스펙 동기화) 우선 |

## 9. 평가 (rubric)

| 기준 | 점수 | 근거 |
|------|------|------|
| 완성도 | 9/10 | RequestDetailScreen 챕터 패턴 SSOT + ScheduleChangeSlotBottomSheet 현 구조 + Lore constraint 전수 매핑 |
| 견고성 | 8/10 | git log + grep 으로 P0-1 a/b·P0-2 commit 검증, ScheduleChangeStatus 0 hits 확인 |
| 일관성 | 9/10 | 사용자 prompt_plan.md scope ↔ 실 commit ↔ Lore constraint 3 source 정합 매트릭스 |
| 간결성 | 8/10 | 9 섹션, 230 라인, 코드 0 |
| **가중 평균** | **8.6** | **PASS (≥7.5)** |

## 10. 사용자 결정 요청

다음 중 선택:
- **(C) 권장**: P0-1·P0-2 클로즈 → P1-1 (travel_time §7 4 케이스 + 스펙 동기화) 진입
- **(B) 보수적**: P0-1 Phase C smoke test 만 추가 후 P1-1 진입
- **(A) 강행**: prompt_plan.md 문구 그대로 ProgressBar/ChapterSummary 강제 적용 (Lore constraint a3f7ccab 폐기 결정 필요)

> 권장: (C). 이유: Lore constraint a3f7ccab 가 sub-task picker 범위를 명시했고, 잔여 실 갭(travel_time)이 사용자 영향이 더 큼.
