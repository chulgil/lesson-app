# Operating Hours Swipe Actions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 선생님 운영시간대 행을 오른쪽 스와이프 액션 UI로 바꾸고, 삭제 후 요일 카드는 휴무 상태로 유지한다.

**Architecture:** `LessonTimeSettingsScreen`은 시간대 삭제 콜백을 provider에 연결한다. `DaySectionCard`는 요일 카드를 계속 렌더링하고 하단 `+ 시간대 추가`를 제거한다. `TimeSlotTile`은 오른쪽 스와이프 시 편집/삭제 버튼을 노출하는 위젯이 된다.

**Tech Stack:** Flutter, Riverpod, widget tests.

---

### Task 1: Widget Contract Test

**Files:**
- Test: `frontend/test/features/profile/lesson_time_settings_widgets_test.dart`
- Modify: `frontend/lib/features/profile/presentation/widgets/lesson_time_settings_widgets.dart`

**Step 1:** `DaySectionCard`가 하단 `+ 시간대 추가`를 렌더링하지 않고, 휴무 요일은 `휴무`를 유지하는 widget test를 추가한다.

**Step 2:** 테스트를 실행해 실패를 확인한다.

**Step 3:** `DaySectionCard`에서 `onAddSlot`과 하단 추가 버튼을 제거한다.

**Step 4:** 테스트 통과를 확인한다.

### Task 2: Swipe Action UI

**Files:**
- Test: `frontend/test/features/profile/lesson_time_settings_widgets_test.dart`
- Modify: `frontend/lib/features/profile/presentation/widgets/lesson_time_settings_widgets.dart`

**Step 1:** `TimeSlotTile` 오른쪽 스와이프 후 `편집`, `삭제` 버튼이 보이고 각 콜백이 호출되는 widget test를 추가한다.

**Step 2:** 테스트를 실행해 실패를 확인한다.

**Step 3:** `TimeSlotTile`을 custom drag-reveal action row로 바꾸고 기존 취소선/트레일링 버튼 UI를 제거한다.

**Step 4:** 테스트 통과를 확인한다.

### Task 3: Delete Wiring

**Files:**
- Modify: `frontend/lib/features/profile/presentation/screens/lesson_time_settings_screen.dart`
- Modify: `frontend/lib/features/settings/presentation/providers/teacher_settings_provider.dart`

**Step 1:** `TeacherSettingsNotifier`에 `removeTimeSlot`을 추가한다.

**Step 2:** 운영시간대 화면에서 삭제 버튼을 눌렀을 때 해당 슬롯을 제거하고, 삭제 후 해당 요일 카드가 휴무로 표시되도록 연결한다.

**Step 3:** 관련 widget test와 analyzer를 실행한다.
