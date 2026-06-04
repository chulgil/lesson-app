import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_report.dart';
import 'package:lessonaza/features/practice/presentation/widgets/report/practice_chart.dart';

void main() {
  Widget host(Widget child, {double width = 360}) {
    return MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );
  }

  testWidgets('shows empty message when no daily entries', (tester) async {
    await tester.pumpWidget(host(const PracticeChart(dailyEntries: [])));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceReportDailyChartTitle), findsOneWidget);
    expect(find.text(AppStrings.practiceReportEmptyChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty message when all entries are zero', (tester) async {
    final entries = List.generate(
      7,
      (i) => DailyReportEntry(
        date: DateTime(2026, 6, 1).add(Duration(days: i)),
        practiceSeconds: 0,
      ),
    );
    await tester.pumpWidget(host(PracticeChart(dailyEntries: entries)));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceReportEmptyChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders bar chart for weekly 7 entries', (tester) async {
    final entries = List.generate(
      7,
      (i) => DailyReportEntry(
        date: DateTime(2026, 6, 1).add(Duration(days: i)),
        practiceSeconds: (i + 1) * 600,
      ),
    );
    await tester.pumpWidget(host(PracticeChart(dailyEntries: entries)));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceReportDailyChartTitle), findsOneWidget);
    expect(find.text(AppStrings.practiceReportEmptyChart), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles narrow width without layout exception', (tester) async {
    final entries = List.generate(
      30,
      (i) => DailyReportEntry(
        date: DateTime(2026, 6, 1).add(Duration(days: i)),
        practiceSeconds: (i % 4) * 600,
      ),
    );
    await tester.pumpWidget(
      host(PracticeChart(dailyEntries: entries), width: 220),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
