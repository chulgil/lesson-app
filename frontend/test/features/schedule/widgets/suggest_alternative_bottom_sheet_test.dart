import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/suggest_alternative_bottom_sheet.dart';

/// Permissive availability so the #526 window-conflict check never blocks
/// the propose flow in these tests, unless [exceptions] adds a blocker.
TeacherAvailability _availability(
  String teacherId, {
  List<TimeException> exceptions = const [],
}) {
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
    exceptions: exceptions,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));

  Widget buildTestable(
    void Function(SuggestAlternativeResult?) onResult, {
    List<PreferredTimeSlot> preferredSlots = const [],
    bool isStudentView = false,
    List<TimeException> exceptions = const [],
  }) {
    return ProviderScope(
      overrides: [
        weekLessonsWithPreviewProvider((
          weekStart: weekStart,
          teacherId: 'teacher_1',
        )).overrideWith((ref) async => const []),
        teacherAvailabilityProvider('teacher_1').overrideWith(
          (ref) async => _availability('teacher_1', exceptions: exceptions),
        ),
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
                      isStudentView: isStudentView,
                      preferredSlots: preferredSlots,
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
      'opens as a bottom sheet (not a pushed full-screen route) and reject '
      'submits the expected SuggestAlternativeResult shape',
      (tester) async {
        SuggestAlternativeResult? result;
        await tester.pumpWidget(buildTestable((r) => result = r));
        await tester.pumpAndSettle();

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.counterPropose), findsOneWidget);
        expect(find.text(AppStrings.rejectAction), findsOneWidget);

        // Reject step — nested reject-message bottom sheet.
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

    for (final testCase in [
      (name: 'teacher view', isStudentView: false),
      (name: 'student view', isStudentView: true),
    ]) {
      testWidgets(
        'highlights a weekly preferred slot from schedule change comparison '
        'in ${testCase.name}',
        (tester) async {
          await tester.pumpWidget(
            buildTestable(
              (_) {},
              isStudentView: testCase.isStudentView,
              preferredSlots: const [
                PreferredTimeSlot(
                  priority: 1,
                  dayOfWeek: 0,
                  startTime: '18:00',
                  endTime: '19:00',
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          expect(find.text(AppStrings.preferredSlotLabel), findsNothing);

          await tester.tap(find.text('월 18:00 ~ 19:00'));
          await tester.pumpAndSettle();

          expect(find.text(AppStrings.preferredSlotLabel), findsOneWidget);
        },
      );
    }

    testWidgets('returns selected index when accepting a weekly preferred '
        'slot', (tester) async {
      SuggestAlternativeResult? result;
      await tester.pumpWidget(
        buildTestable(
          (r) => result = r,
          preferredSlots: const [
            PreferredTimeSlot(
              priority: 1,
              dayOfWeek: 0,
              startTime: '18:00',
              endTime: '19:00',
            ),
            PreferredTimeSlot(
              priority: 2,
              dayOfWeek: 2,
              startTime: '17:00',
              endTime: '18:00',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수 17:00 ~ 18:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.confirmThisSchedule));
      await tester.pumpAndSettle();

      expect(result?.acceptedSlotIndex, 1);
    });

    // #526 — accepting a preferred slot that falls inside the teacher's
    // vacation must be blocked: the confirm button is disabled and the
    // vacation reason is shown instead of the green "confirm" label.
    testWidgets(
      'blocks accepting a preferred slot inside the teacher vacation',
      (tester) async {
        // Monday of the current week — matches preferred slot dayOfWeek 0.
        final monday = weekStart;

        await tester.pumpWidget(
          buildTestable(
            (_) {},
            preferredSlots: const [
              PreferredTimeSlot(
                priority: 1,
                dayOfWeek: 0,
                startTime: '18:00',
                endTime: '19:00',
              ),
            ],
            exceptions: [
              TimeException(
                id: 'vac-1',
                type: ExceptionType.vacation,
                startDate: monday,
                endDate: monday,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Select the preferred (Monday) slot → enters accept mode.
        await tester.tap(find.text('월 18:00 ~ 19:00'));
        await tester.pumpAndSettle();

        // Confirm button is disabled and shows the vacation reason, not
        // "confirm".
        expect(find.text(AppStrings.confirmThisSchedule), findsNothing);
        expect(find.text(AppStrings.slotVacationConflict), findsWidgets);
      },
    );
  });
}
