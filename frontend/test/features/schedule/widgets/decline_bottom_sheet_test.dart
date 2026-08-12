import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/decline_bottom_sheet.dart';

/// M-2 bottom-sheet migration — decline_bottom_sheet's "다른 시간 제안" CTA
/// used to push the full-screen SuggestAlternativeScreen; it now opens
/// showSuggestAlternativeBottomSheet as a nested sheet instead.
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

  Widget buildTestable(void Function(DeclineResult?) onResult) {
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
                    final result = await showDeclineBottomSheet(
                      context,
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

  group('showDeclineBottomSheet counter-propose CTA', () {
    testWidgets('제안하기 opens the counter-propose bottom sheet, not a pushed '
        'full-screen route', (tester) async {
      DeclineResult? result;
      await tester.pumpWidget(buildTestable((r) => result = r));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.counterPropose));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text(AppStrings.rejectAction), findsOneWidget);
      expect(result, isNull); // still open, nothing submitted yet
    });

    testWidgets(
      'rejecting from the nested sheet closes the decline sheet with the '
      'same DeclineResult shape as before the migration',
      (tester) async {
        DeclineResult? result;
        await tester.pumpWidget(buildTestable((r) => result = r));
        await tester.pumpAndSettle();

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.counterPropose));
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.rejectAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.rejectSendAndClose));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.suggestedSlots, isEmpty);
        expect(result!.message, AppStrings.declineDefaultMessage);
      },
    );

    testWidgets(
      'dismissing the nested sheet leaves the decline sheet open with no '
      'result',
      (tester) async {
        DeclineResult? result;
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

        await tester.tap(find.text(AppStrings.counterPropose));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(resultCaptured, isFalse);
        expect(result, isNull);
        // Decline sheet is still open underneath the closed nested sheet.
        expect(find.text(AppStrings.messageOnly), findsOneWidget);
      },
    );
  });
}
