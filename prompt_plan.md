# #211 과거 시간 선택 차단 — 구현 계획

> 확정일: 2026-03-28
> 범위: 대안 시간 제안 + 메인 주간 스케줄에서 과거 셀 비활성화
> 복잡도: LOW (~23줄 수정, 2개 파일)

## 수정 파일

| 파일 | 변경 |
|------|------|
| `alternative_time_grid.dart` (line 219-239) | `_buildCell` empty 분기에 isPast 체크 + 회색 비활성 |
| `schedule_weekly_grid_view.dart` (line 302-313) | `_buildGridCell` empty 분기에 isPast 체크 |

## 과거 판단 기준

```
isPast = DateTime(date.y, date.m, date.d, hour, minute).isBefore(DateTime.now())
```

## 검증

```bash
flutter test test/features/schedule/
flutter analyze
```

## 관련

- 이슈: #211
- PAD: docs/specs/schedule/alternative_proposal_enhancement_pad.md

---

## 이전 계획

### 통합 레슨 신청 v2.0 (Cherry) — 2026-03-28, ✅ Phase 1-5 완료

> 범위: Cherry (3안 선택 엔진 + 완료 페이지 + 선생님 수락 UI)
> 복잡도: MEDIUM (~500줄 신규 + ~130줄 수정)

## 범위

| 포함 | 제외 (추후) |
|------|------------|
| ✅ WeeklyCalendarPicker (이전/다음, 3안 ❶❷❸) | ❌ 안내 메시지 커스텀 |
| ✅ PreferredTimeSlot 데이터 모델 | ❌ 취소 정책/예상 시간 표시 |
| ✅ RequestCompletionScreen (5단계 가이드) | ❌ perSession 타입 추가 |
| ✅ 선생님 3안 수락 UI | ❌ 재수강 프리필 |
| ✅ 2라운드 협상 축소 | ❌ 악기 1개 숨김 |

## Phase 구성

### Phase 1: PreferredTimeSlot + WeeklyCalendarPicker
- [x] unified_lesson_request.dart — PreferredTimeSlot 클래스 + preferredSlots 리스트
- [x] slot_selection_logic.dart — 3안 선택 로직 엔진 (TDD 완료)
- [x] weekly_calendar_picker.dart — NEW: 주간 캘린더 UI (TDD 완료)
- [x] mock_unified_lesson_request_repository.dart — seed 데이터 마이그레이션 + maxRounds 2

### Phase 2: 폼 연동 + 완료 페이지
- [x] unified_lesson_request_screen.dart — ScheduleSlotPicker → WeeklyCalendarPicker 교체
- [x] request_completion_screen.dart — NEW: 5단계 가이드 + 요약
- [x] schedule_routes.dart + app_routes.dart — 완료 페이지 라우트 추가

### Phase 3: 선생님 수락 UI + 2라운드
- [x] unified_approval_bottom_sheet.dart — NEW: 3안 표시 + 수락/역제안 UI
- [x] currentRound 상한 2 적용 (Phase 1에서 완료)
- [x] 수락/거절/역제안 비즈니스 로직 테스트 (10 tests)

### Phase 4: 수강권 제안 연동
- [x] _handleSendProposal: 체험→직접완료, 정규→IssueSubscriptionScreen
- [x] completeRequest 액션 추가
- [x] 체험레슨 무료/유료 분기 (trialLessonFree 참조)
- [x] 가격표 자동 매칭 (TeacherSettings.getPrice 연동)
- [ ] 학생 화면: 수강권 제안 수신 → 수락 → 입금 알림 (추후, #201)

### Phase 5: 선생님 UX 개선 (2026-03-28 완료)
- [x] AppStrings 용어 상수 파일 (다국어 기반)
- [x] 용어 통일: 레슨 요청/수락/다음에
- [x] 즉시 확인 필요 4→2 축소
- [x] 안내 메시지 커스텀 (bookingGuidanceMessage)
- [x] 선생님 설정 편집 UI
- [x] 학생 역제안 선택 바텀시트
- [x] 예상 시간 + 취소 정책 표시
- [x] 악기 1개 → 선택 UI 숨김
- [x] fontSize → AppTypography 교체

## 의존성
Phase 1 → Phase 2 → Phase 3 → Phase 4 (순차)

## 관련 문서
- 스펙: docs/specs/booking/unified_lesson_request_spec.md (v2.0)
- 체크리스트: docs/specs/booking/unified_lesson_request_checklist.md
- PAD: docs/specs/booking/unified_lesson_request_v2_pad.md

---

## 이전 계획

### Mock → Remote 전환 (2026-03-17, ✅ 완료)
