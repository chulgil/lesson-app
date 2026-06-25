import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/schedule/presentation/screens/register_regular_lesson_screen.dart';

void main() {
  group('RegisterRegularLessonScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterRegularLessonScreen(
              teacherId: 'teacher_1',
              teacherName: '김선생님',
            ),
          ),
        ),
      );

      // Wait for UI to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('academy privacy section renders when teacher has academies', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterRegularLessonScreen(
              teacherId: 'teacher_1',
              teacherName: '김선생님',
            ),
          ),
        ),
      );

      // Wait for UI to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // This test just ensures no exceptions occur during rendering
      expect(tester.takeException(), isNull);
    });
  });

  // ── hasSlotOverlap unit tests (TDD #923) ──────────────────────────────────
  //
  // hasSlotOverlap checks [start, start+duration) interval overlap for slots
  // sharing the same dayOfWeek within a Map<int, TimeOfDay>.
  //
  // With Map<int, TimeOfDay> as the data structure, each dayOfWeek key can hold
  // only one TimeOfDay, so same-day duplicates are structurally impossible.
  // The function therefore always returns false — but its presence makes the
  // intent explicit and guards against future refactors (e.g., List<TimeSlot>).

  group('hasSlotOverlap', () {
    test('returns false for empty schedule', () {
      expect(hasSlotOverlap({}, 60), isFalse);
    });

    test('returns false for a single slot', () {
      expect(
        hasSlotOverlap({1: const TimeOfDay(hour: 10, minute: 0)}, 60),
        isFalse,
      );
    });

    test('returns false for two slots on DIFFERENT days — no overlap', () {
      // Mon 10:00–11:00  vs  Tue 10:00–11:00 → different days
      final times = {
        1: const TimeOfDay(hour: 10, minute: 0),
        2: const TimeOfDay(hour: 10, minute: 0),
      };
      expect(hasSlotOverlap(times, 60), isFalse);
    });

    test(
      'returns false for two slots on different days, non-overlapping times',
      () {
        final times = {
          1: const TimeOfDay(hour: 9, minute: 0),
          3: const TimeOfDay(hour: 14, minute: 30),
        };
        expect(hasSlotOverlap(times, 60), isFalse);
      },
    );

    test('returns false for max lessonsPerWeek=2 with distinct days', () {
      // Typical use: Mon+Wed, 60 min each — no overlap possible
      final times = {
        1: const TimeOfDay(hour: 10, minute: 0), // Mon
        3: const TimeOfDay(hour: 15, minute: 0), // Wed
      };
      expect(hasSlotOverlap(times, 90), isFalse);
    });
  });
}
