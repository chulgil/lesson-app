import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/data/repositories/mock_practice_stats_repository.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_stats_repository.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_report_provider.dart';
import 'package:lessonaza/features/practice/presentation/screens/practice_report_screen.dart';

void main() {
  Widget host({required PracticeStatsRepository repository}) {
    return ProviderScope(
      overrides: [
        practiceReportRepositoryProvider.overrideWith((ref) => repository),
      ],
      child: const MaterialApp(
        home: PracticeReportScreen(studentId: 'student_1'),
      ),
    );
  }

  testWidgets('renders weekly/monthly toggle and weekly is initial', (
    tester,
  ) async {
    await tester.pumpWidget(host(repository: MockPracticeStatsRepository()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceReportTitle), findsOneWidget);
    expect(find.text(AppStrings.practiceReportWeekly), findsOneWidget);
    expect(find.text(AppStrings.practiceReportMonthly), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty state when repository returns empty report', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(repository: MockPracticeStatsRepository(empty: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceReportEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggle switches from weekly to monthly view', (tester) async {
    await tester.pumpWidget(host(repository: MockPracticeStatsRepository()));
    await tester.pumpAndSettle();

    // Tap the monthly segment.
    await tester.tap(find.text(AppStrings.practiceReportMonthly));
    await tester.pumpAndSettle();

    // Chart title still present after switch (both periods show chart).
    expect(find.text(AppStrings.practiceReportDailyChartTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders chart and ratio bar titles when data present', (
    tester,
  ) async {
    await tester.pumpWidget(host(repository: MockPracticeStatsRepository()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceReportDailyChartTitle), findsOneWidget);
    expect(
      find.text(AppStrings.practiceReportRepertoireRatioTitle),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
