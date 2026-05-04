# Student Lesson Progress Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the student home's scattered lesson request, proposal, subscription, and schedule-confirmation banners with a teacher-home-aligned lesson progress timeline.

**Architecture:** Add a student-specific progress item model and provider that aggregates existing request/proposal/subscription-confirmation sources into a single ordered list. Render the list with the same Notebook section grammar as teacher home: section header, compact stats, ruled list rows, status chip, and timestamp. Keep routes and existing domain providers intact.

**Tech Stack:** Flutter, Riverpod, GoRouter, existing Lessonaza Notebook theme tokens, Flutter widget tests.

---

### Task 1: Add Progress Item Domain Model

**Files:**
- Create: `frontend/lib/features/student_home/domain/entities/student_lesson_progress_item.dart`
- Test: `frontend/test/features/student_home/student_lesson_progress_item_test.dart`

**Step 1: Write the failing test**

Create a test that verifies priority sorting:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lesson_app/features/student_home/domain/entities/student_lesson_progress_item.dart';

void main() {
  test('sorts action required before waiting before completed', () {
    final now = DateTime(2026, 5, 4, 12);
    final items = [
      StudentLessonProgressItem(
        id: 'completed',
        kind: StudentLessonProgressKind.subscriptionReady,
        priority: StudentLessonProgressPriority.completed,
        title: '수강권이 준비됐어요',
        subtitle: '다음 레슨 일정에 맞춰 시작합니다',
        statusLabel: '완료',
        createdAt: now,
      ),
      StudentLessonProgressItem(
        id: 'waiting',
        kind: StudentLessonProgressKind.request,
        priority: StudentLessonProgressPriority.waiting,
        title: '레슨 신청을 보냈어요',
        subtitle: '선생님 답변을 기다리고 있어요',
        statusLabel: '대기',
        createdAt: now,
      ),
      StudentLessonProgressItem(
        id: 'action',
        kind: StudentLessonProgressKind.scheduleConfirmation,
        priority: StudentLessonProgressPriority.actionRequired,
        title: '수강권이 준비됐어요',
        subtitle: '첫 레슨 시간을 확인해주세요',
        statusLabel: '확인 필요',
        createdAt: now,
      ),
    ];

    final sorted = StudentLessonProgressItem.sorted(items);

    expect(sorted.map((item) => item.id), ['action', 'waiting', 'completed']);
  });
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test frontend/test/features/student_home/student_lesson_progress_item_test.dart
```

Expected: fail because the entity does not exist.

**Step 3: Write minimal implementation**

Add enums:

```dart
enum StudentLessonProgressKind {
  request,
  proposal,
  payment,
  subscriptionReady,
  scheduleConfirmation,
  renewal,
}

enum StudentLessonProgressPriority {
  actionRequired,
  waiting,
  completed,
}
```

Add immutable `StudentLessonProgressItem` with the fields from the design doc and a static `sorted` method.

**Step 4: Run test to verify it passes**

Run the same `flutter test` command. Expected: pass.

**Step 5: Commit**

```bash
git add frontend/lib/features/student_home/domain/entities/student_lesson_progress_item.dart frontend/test/features/student_home/student_lesson_progress_item_test.dart
git commit -m "feat(student): add lesson progress item model"
```

---

### Task 2: Add Aggregating Provider

**Files:**
- Create: `frontend/lib/features/student_home/presentation/providers/student_lesson_progress_provider.dart`
- Test: `frontend/test/features/student_home/student_lesson_progress_provider_test.dart`

**Step 1: Write failing provider tests**

Test at least:

- subscription issued plus pending schedule confirmation produces an action-required item with title `수강권이 준비됐어요`
- pending proposal produces an action-required proposal item
- empty sources produce an empty list

**Step 2: Run tests to verify failure**

Run:

```bash
flutter test frontend/test/features/student_home/student_lesson_progress_provider_test.dart
```

Expected: fail because provider does not exist.

**Step 3: Implement provider**

Aggregate existing providers where available:

- `studentTodayRequestsProvider(studentId)`
- `pendingStudentProposalsProvider(studentId)`
- `pendingRenewalProposalProvider(studentId)`
- `studentSubscriptionsProvider(studentId)`
- `pendingScheduleConfirmationCardsProvider(studentId)`

Map each source into `StudentLessonProgressItem`, then sort with `StudentLessonProgressItem.sorted`.

**Step 4: Run focused tests**

Run:

```bash
flutter test frontend/test/features/student_home/student_lesson_progress_provider_test.dart
```

Expected: pass.

**Step 5: Commit**

```bash
git add frontend/lib/features/student_home/presentation/providers/student_lesson_progress_provider.dart frontend/test/features/student_home/student_lesson_progress_provider_test.dart
git commit -m "feat(student): aggregate lesson progress items"
```

---

### Task 3: Build Timeline Section UI

**Files:**
- Create: `frontend/lib/features/student_home/presentation/widgets/student_lesson_progress_section.dart`
- Create: `frontend/lib/features/student_home/presentation/widgets/student_lesson_progress_item_row.dart`
- Test: `frontend/test/features/student_home/student_lesson_progress_section_test.dart`

**Step 1: Write failing widget tests**

Test:

- section header shows `레슨 진행`
- action-required item appears before waiting item
- title uses `수강권이 준비됐어요`
- legacy strings `수강권이 발급되었습니다` and `수강권이 발행되었습니다` do not appear
- narrow width renders without layout exception

**Step 2: Run tests to verify failure**

Run:

```bash
flutter test frontend/test/features/student_home/student_lesson_progress_section_test.dart
```

Expected: fail because widgets do not exist.

**Step 3: Implement UI**

Use:

- `NotebookSectionHeader`
- `AppColors.inkQuaternary` top/bottom borders
- `Divider(height: 1, thickness: 1)`
- row layout matching `LessonRequestSection` and `ScheduleChangeRequestSection`
- `Expanded` for title/subtitle
- constrained right column for status chip and elapsed time

**Step 4: Run widget tests**

Run the same focused test. Expected: pass.

**Step 5: Commit**

```bash
git add frontend/lib/features/student_home/presentation/widgets/student_lesson_progress_section.dart frontend/lib/features/student_home/presentation/widgets/student_lesson_progress_item_row.dart frontend/test/features/student_home/student_lesson_progress_section_test.dart
git commit -m "feat(student): add lesson progress timeline section"
```

---

### Task 4: Replace Student Event Group

**Files:**
- Modify: `frontend/lib/features/student_home/presentation/screens/student_dashboard_tab.dart`
- Test: `frontend/test/features/student_home/student_dashboard_layout_test.dart`

**Step 1: Update dashboard layout test**

Assert that `StudentLessonProgressSection` is present and the old standalone proposal/renewal banners are not independently rendered from `_StudentEventsGroup`.

**Step 2: Run test to verify failure**

Run:

```bash
flutter test frontend/test/features/student_home/student_dashboard_layout_test.dart
```

Expected: fail until dashboard uses the new section.

**Step 3: Replace `_StudentEventsGroup` content**

Replace the current four-widget column with:

```dart
StudentLessonProgressSection(studentId: studentId)
```

Remove now-unused imports from `student_dashboard_tab.dart`.

**Step 4: Run dashboard tests**

Run:

```bash
flutter test frontend/test/features/student_home/student_dashboard_layout_test.dart
```

Expected: pass.

**Step 5: Commit**

```bash
git add frontend/lib/features/student_home/presentation/screens/student_dashboard_tab.dart frontend/test/features/student_home/student_dashboard_layout_test.dart
git commit -m "feat(student): use lesson progress timeline on home"
```

---

### Task 5: Normalize Subscription Issued Copy

**Files:**
- Modify: `frontend/lib/core/l10n/app_strings.dart`
- Modify: `frontend/lib/features/schedule/presentation/widgets/schedule_confirmation_card_widget.dart`
- Modify: `frontend/lib/features/subscription/presentation/widgets/subscription_issued_card.dart`
- Modify as needed: `frontend/lib/features/schedule/presentation/widgets/current_request_box.dart`
- Test: focused tests that cover these widgets or existing related tests

**Step 1: Write/update tests**

Assert visible student-facing copy uses:

```text
수강권이 준비됐어요
```

Assert the following do not appear in student-facing widget output:

```text
수강권이 발급되었습니다
수강권이 발행되었습니다
```

**Step 2: Run tests to verify failure**

Run relevant focused tests, including the new section test.

**Step 3: Update copy**

Recommended string constants:

```dart
static const subscriptionReadyTitle = '수강권이 준비됐어요';
static const subscriptionReadyScheduleNeeded = '첫 레슨 시간을 확인해주세요';
static const subscriptionReadyScheduleConfirmed = '다음 레슨 일정에 맞춰 시작합니다';
static const subscriptionReadyPostpaid = '수강권은 준비됐고, 입금 확인은 나중에 진행됩니다';
```

Keep teacher/admin success snackbars using `발급` if they describe the teacher's completed action.

**Step 4: Run focused tests**

Expected: pass.

**Step 5: Commit**

```bash
git add frontend/lib/core/l10n/app_strings.dart frontend/lib/features/schedule/presentation/widgets/schedule_confirmation_card_widget.dart frontend/lib/features/subscription/presentation/widgets/subscription_issued_card.dart frontend/lib/features/schedule/presentation/widgets/current_request_box.dart
git commit -m "fix(student): align subscription ready copy"
```

---

### Task 6: Final Verification

**Files:**
- No source files unless fixes are required.

**Step 1: Run focused tests**

```bash
flutter test frontend/test/features/student_home/student_lesson_progress_item_test.dart
flutter test frontend/test/features/student_home/student_lesson_progress_provider_test.dart
flutter test frontend/test/features/student_home/student_lesson_progress_section_test.dart
flutter test frontend/test/features/student_home/student_dashboard_layout_test.dart
```

Expected: all pass.

**Step 2: Run analyze**

```bash
flutter analyze
```

Expected: no new issues.

**Step 3: Run final status check**

```bash
git status --short
```

Expected: clean after commits.

**Step 4: Commit fixes if needed**

If verification requires small fixes:

```bash
git add <changed-files>
git commit -m "fix(student): stabilize lesson progress timeline"
```
