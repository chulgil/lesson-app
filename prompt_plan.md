# 통합 레슨 신청 v2.0 (Cherry) — 구현 계획

> 확정일: 2026-03-28
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
- unified_lesson_request.dart — PreferredTimeSlot 클래스 + preferredSlots 리스트
- weekly_calendar_picker.dart — NEW: 주간 캘린더 + 3안 선택 엔진
- mock_unified_lesson_request_repository.dart — seed 데이터 마이그레이션

### Phase 2: 폼 연동 + 완료 페이지
- unified_lesson_request_screen.dart — ScheduleSlotPicker → WeeklyCalendarPicker 교체
- request_completion_screen.dart — NEW: 5단계 가이드 + 요약
- schedule_routes.dart — 완료 페이지 라우트 추가

### Phase 3: 선생님 수락 UI + 2라운드
- approval_bottom_sheet.dart — 3안 표시 + 수락/역제안 UI
- currentRound 상한 2 적용

## 의존성
Phase 1 → Phase 2 → Phase 3 (순차)

## 관련 문서
- 스펙: docs/specs/booking/unified_lesson_request_spec.md (v2.0)
- 체크리스트: docs/specs/booking/unified_lesson_request_checklist.md
- PAD: docs/specs/booking/unified_lesson_request_v2_pad.md

---

## 이전 계획

### Mock → Remote 전환 (2026-03-17, ✅ 완료)
