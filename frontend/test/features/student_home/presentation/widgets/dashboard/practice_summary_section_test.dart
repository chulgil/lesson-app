import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_log.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_crud_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_streak_provider.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/dashboard/practice_summary_section.dart';

void main() {
  testWidgets('streak comes from practiceStreakProvider (SSOT), not the logs', (
    tester,
  ) async {
    const studentId = 'student_1';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Two logs on today: a naive inline streak from these logs would be 1.
    // The SSOT provider is overridden to 5 — a value the logs do NOT imply, so
    // rendering "5일" proves the section reads the provider, not its own calc.
    // (45분 = 30 + 15, both within the current Mon–Sun window.)
    final logs = [
      PracticeLog(
        id: 'log_today_a',
        studentId: studentId,
        date: today,
        totalMinutes: 30,
        createdAt: today,
      ),
      PracticeLog(
        id: 'log_today_b',
        studentId: studentId,
        date: today,
        totalMinutes: 15,
        createdAt: today,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          practiceLogsProvider(studentId).overrideWith((ref) async => logs),
          practiceStreakProvider(studentId).overrideWith(
            (ref) async => PracticeStreak(
              id: 'streak_$studentId',
              studentId: studentId,
              currentStreak: 5,
              longestStreak: 9,
              lastPracticeDate: today,
              updatedAt: now,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: PracticeSummarySection(studentId: studentId),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.studentHomePracticeJournal), findsOneWidget);
    expect(find.text(AppStrings.studentHomePracticeStreak), findsOneWidget);
    expect(
      find.text(AppStrings.studentHomePracticeWeeklyTotal),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.studentHomePracticeGoalAchievement),
      findsOneWidget,
    );
    // Streak from the provider (5), not the logs-implied 1.
    expect(find.text('5일'), findsOneWidget);
    expect(find.text('1일'), findsNothing);
    // Weekly total still derived from the logs.
    expect(find.text('45분'), findsOneWidget);
  });
}
