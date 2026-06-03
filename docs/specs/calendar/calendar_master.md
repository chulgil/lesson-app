# Calendar System Master Spec (통합·이관됨)

> ⛔ **이 문서는 더 이상 SSOT가 아닙니다.** 캘린더 탭 기능은 schedule 도메인으로 통합되었습니다.
> **현행 SSOT: [schedule_master.md](../schedule/schedule_master.md)** (주간 캘린더 + 날짜별 레슨 목록 + 뷰 모드)
> 정리일: 2026-06-03 (코드↔스펙 드리프트 동기화 후속, Item 1)

## 왜 이관되었나

`features/calendar/` 디렉토리·`CalendarTab`·`calendar_event.dart`는 코드에서 제거되었다. 캘린더 탭은 `features/schedule/presentation/screens/schedule_tab.dart`(클래스 `ScheduleTab` — "Calendar tab with WeekCalendar and lesson list")로 통합되었으며, 본 문서가 기술하던 내용은 [schedule_master.md](../schedule/schedule_master.md)가 더 상세하고 정확하게 다룬다. (역방향 드리프트 해소: 코드가 SSOT)

## 구(calendar) → 현(schedule) 매핑

| 구 calendar_master 개념 | 현행 위치 / 심볼 |
|------------------------|------------------|
| `CalendarTab` 화면 | `features/schedule/presentation/screens/schedule_tab.dart` (`ScheduleTab`) |
| 주간 캘린더 위젯 | `core/widgets/week_calendar_widget.dart` + `schedule/.../widgets/compact_week_strip.dart`, `weekly_calendar_picker.dart` |
| 뷰 모드 | `ScheduleViewMode` (`schedule_view_mode_provider.dart`) — list/timeline/weeklyGrid. 구 `CalendarViewType`(month/week/day) 대체 |
| 날짜 선택/정렬 상태 | `schedule_tab_state_provider.dart` — 구 `teacherSelectedDateProvider`/`teacherLessonSortTypeProvider` 대체 |
| 레슨 카드 / 상태 색상 바 / 컨텍스트 배지(학원·개인) / 수강권 배지 | schedule_master.md (주간 그리드·타임라인·블록 인터랙션 섹션) |
| 레슨 추가 네비게이션(`/lessons/add?date=&hour=`) | schedule_master.md (가용 시간 탭 → 예약 추가) |
| `CalendarEventType` enum (lesson/practice/break_) | ❌ 코드에서 제거됨 (미사용) |

## 관련 스펙

| 스펙 | 관계 |
|------|------|
| **[schedule_master.md](../schedule/schedule_master.md)** | ← **현행 SSOT** |
| [teacher_availability_spec.md](../schedule/teacher_availability_spec.md) | 가용시간 설정 |
| [student_home_master.md](../student_home/student_home_master.md) | 학생 스케줄 탭 (유사 구조) |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-06-03 | schedule_master.md로 통합 — 리다이렉트 스텁으로 전환 (코드에서 `features/calendar/` 제거 확인, 역방향 드리프트 해소) |
| 2026-03-07 | Dart enum 코드 블록 추가, 구현 파일 위치 섹션 추가 |
| 2026-03-06 | 기존 구현 기반 스펙 문서 생성 (역공학) |
