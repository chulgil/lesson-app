import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_log.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_crud_provider.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/dashboard/practice_summary_section.dart';

void main() {
  testWidgets('shows journal title and positive summary labels', (
    tester,
  ) async {
    const studentId = 'student_1';
    final now = DateTime.now();
    // Anchor both logs to today so the test is deterministic regardless of
    // which day of the week it runs.  Two logs on the same date give:
    //   streak = 1일  (today has practice)
    //   weekly total = 45분  (30 + 15, both within the current Mon–Sun window)
    final today = DateTime(now.year, now.month, now.day);
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
    expect(find.text('1일'), findsOneWidget);
    expect(find.text('45분'), findsOneWidget);
  });
}
