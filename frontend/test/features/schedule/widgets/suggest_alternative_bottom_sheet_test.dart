import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/screens/suggest_alternative_screen.dart'
    show SuggestAlternativeResult, SuggestAlternativeScreen;
import 'package:lessonaza/features/schedule/presentation/widgets/suggest_alternative_bottom_sheet.dart';

/// Permissive availability so the #526 window-conflict check never blocks
/// the propose flow in these tests.
TeacherAvailability _availability(String teacherId) {
  return TeacherAvailability(
    id: teacherId,
    teacherId: teacherId,
    weeklySchedules: [
      for (var d = 0; d < 7; d++)
        WeeklySchedule(
          id: 'ws-$d',
          dayOfWeek: d,
          startTime: '09:00',
          endTime: '21:00',
          createdAt: DateTime(2026, 1, 1),
        ),
    ],
    exceptions: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));

  Widget buildTestable(void Function(SuggestAlternativeResult?) onResult) {
    return ProviderScope(
      overrides: [
        weekLessonsWithPreviewProvider((
          weekStart: weekStart,
          teacherId: 'teacher_1',
        )).overrideWith((ref) async => const []),
        teacherAvailabilityProvider(
          'teacher_1',
        ).overrideWith((ref) async => _availability('teacher_1')),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed: () async {
                    final result = await showSuggestAlternativeBottomSheet(
                      context,
                      message: '',
                      durationMinutes: 60,
                      teacherId: 'teacher_1',
                    );
                    onResult(result);
                  },
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );
  }

  group('showSuggestAlternativeBottomSheet', () {
    testWidgets(
      'opens as a bottom sheet (not the old full-screen route) and reject '
      'submits the same SuggestAlternativeResult shape as the screen',
      (tester) async {
        SuggestAlternativeResult? result;
        await tester.pumpWidget(buildTestable((r) => result = r));
        await tester.pumpAndSettle();

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Migrated to a bottom sheet — the old full-screen widget must never
        // be pushed for this flow.
        expect(find.byType(SuggestAlternativeScreen), findsNothing);
        expect(find.text(AppStrings.counterPropose), findsOneWidget);
        expect(find.text(AppStrings.rejectAction), findsOneWidget);

        // Reject step — same nested reject-message bottom sheet + result
        // shape (empty slots, null acceptedSlotIndex) as the full-screen flow.
        await tester.tap(find.text(AppStrings.rejectAction));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.rejectBottomSheetTitle), findsOneWidget);

        await tester.tap(find.text(AppStrings.rejectSendAndClose));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.slots, isEmpty);
        expect(result!.acceptedSlotIndex, isNull);
        expect(result!.message, AppStrings.declineDefaultMessage);
      },
    );

    testWidgets('dismissing via the close button leaves the result null', (
      tester,
    ) async {
      SuggestAlternativeResult? result;
      var resultCaptured = false;
      await tester.pumpWidget(
        buildTestable((r) {
          result = r;
          resultCaptured = true;
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(resultCaptured, isTrue);
      expect(result, isNull);
    });
  });
}
