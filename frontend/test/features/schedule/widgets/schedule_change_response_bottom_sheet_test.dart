import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_change_response_bottom_sheet.dart';

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
  group('showScheduleChangeResponseBottomSheet reject confirmation', () {
    testWidgets(
      'reject shows a confirm dialog and only resolves after confirming',
      (tester) async {
        ScheduleChangeResponseResult? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await showScheduleChangeResponseBottomSheet(
                        context,
                        proposedSlots: [
                          TimeSlotOption(
                            id: 'slot_1',
                            dayOfWeek: 0,
                            startTime: '16:00',
                            endTime: '17:00',
                          ),
                        ],
                        changeType: ScheduleChangeType.singleLesson,
                        durationMinutes: 60,
                      );
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('거절'));
        await tester.pumpAndSettle();

        // Confirm dialog blocks the sheet from resolving until confirmed.
        expect(find.text('제안 거절'), findsOneWidget);
        expect(result, isNull);

        // Cancel keeps the sheet open with no result.
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        expect(result, isNull);

        // Re-open and confirm this time — the dialog's confirm action is a
        // TextButton, distinct from the sheet's OutlinedButton reject CTA.
        await tester.tap(find.text('거절'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, '거절'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.action, ScheduleChangeResponseAction.reject);
      },
    );
  });

  group('counter-propose (M-2 bottom-sheet migration)', () {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    Widget buildTestable() {
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
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showScheduleChangeResponseBottomSheet(
                      context,
                      proposedSlots: [
                        TimeSlotOption(
                          id: 'slot_1',
                          dayOfWeek: 0,
                          startTime: '16:00',
                          endTime: '17:00',
                        ),
                      ],
                      changeType: ScheduleChangeType.singleLesson,
                      durationMinutes: 60,
                      teacherId: 'teacher_1',
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('다른 시간 제안 opens the counter-propose bottom sheet, not a pushed '
        'full-screen route', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.scheduleChangeCounter));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text(AppStrings.rejectAction), findsOneWidget);
    });

    testWidgets(
      'rejecting from the nested sheet resolves as a counter result with '
      'the same shape as before the migration',
      (tester) async {
        ScheduleChangeResponseResult? result;

        await tester.pumpWidget(
          ProviderScope(
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
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () async {
                        result = await showScheduleChangeResponseBottomSheet(
                          context,
                          proposedSlots: [
                            TimeSlotOption(
                              id: 'slot_1',
                              dayOfWeek: 0,
                              startTime: '16:00',
                              endTime: '17:00',
                            ),
                          ],
                          changeType: ScheduleChangeType.singleLesson,
                          durationMinutes: 60,
                          teacherId: 'teacher_1',
                        );
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.scheduleChangeCounter));
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.rejectAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.rejectSendAndClose));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.action, ScheduleChangeResponseAction.counter);
        expect(result!.counterSlots, isEmpty);
        expect(result!.message, AppStrings.declineDefaultMessage);
      },
    );

    testWidgets('dismissing the nested sheet leaves the response sheet open '
        'with no result', (tester) async {
      ScheduleChangeResponseResult? result;
      var resultCaptured = false;

      await tester.pumpWidget(
        ProviderScope(
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
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await showScheduleChangeResponseBottomSheet(
                        context,
                        proposedSlots: [
                          TimeSlotOption(
                            id: 'slot_1',
                            dayOfWeek: 0,
                            startTime: '16:00',
                            endTime: '17:00',
                          ),
                        ],
                        changeType: ScheduleChangeType.singleLesson,
                        durationMinutes: 60,
                        teacherId: 'teacher_1',
                      );
                      resultCaptured = true;
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.scheduleChangeCounter));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(resultCaptured, isFalse);
      expect(result, isNull);
      // Response sheet is still open underneath the closed nested sheet.
      expect(find.text(AppStrings.scheduleChangeCounter), findsOneWidget);
    });
  });
}
