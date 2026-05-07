import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_streak_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_streak_card.dart';

void main() {
  testWidgets('renders journal-centered labels', (tester) async {
    const studentId = 'student_1';
    final now = DateTime(2026, 5, 7);
    final streak = PracticeStreak(
      id: 'streak_1',
      studentId: studentId,
      currentStreak: 8,
      longestStreak: 21,
      lastPracticeDate: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          practiceStreakProvider(studentId).overrideWith((ref) async => streak),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: PracticeStreakCard(studentId: studentId)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceJournalTitle), findsOneWidget);
    expect(find.text(AppStrings.practiceJournalContinuousDays), findsOneWidget);
    expect(
      find.text('${AppStrings.practiceJournalBestRun}: 21일'),
      findsOneWidget,
    );
    expect(find.text('연습 일지가 8일째 이어지고 있어요.'), findsOneWidget);
  });
}
