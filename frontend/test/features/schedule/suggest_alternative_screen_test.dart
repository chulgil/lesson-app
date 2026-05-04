import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/screens/suggest_alternative_screen.dart';

void main() {
  for (final testCase in [
    (name: 'teacher view', isStudentView: false),
    (name: 'student view', isStudentView: true),
  ]) {
    testWidgets(
      'highlights a weekly preferred slot from schedule change comparison in ${testCase.name}',
      (tester) async {
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              weekLessonsWithPreviewProvider((
                weekStart: weekStart,
                teacherId: 'teacher_1',
              )).overrideWith((ref) async => const []),
            ],
            child: MaterialApp(
              home: SuggestAlternativeScreen(
                message: '',
                durationMinutes: 60,
                teacherId: 'teacher_1',
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
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.preferredSlotLabel), findsNothing);

        await tester.tap(find.text('월 18:00 ~ 19:00'));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.preferredSlotLabel), findsOneWidget);
      },
    );
  }

  testWidgets('returns selected index when accepting a weekly preferred slot', (
    tester,
  ) async {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    SuggestAlternativeResult? result;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekLessonsWithPreviewProvider((
            weekStart: weekStart,
            teacherId: 'teacher_1',
          )).overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          home: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.push<SuggestAlternativeResult>(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const SuggestAlternativeScreen(
                              message: '',
                              durationMinutes: 60,
                              teacherId: 'teacher_1',
                              preferredSlots: [
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
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
          ),
        ),
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
}
