import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_loop_stats.dart';
import 'package:lessonaza/features/practice/presentation/widgets/stats/student_repeat_chart.dart';

void main() {
  Widget host(Widget child, {double width = 360}) {
    return MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );
  }

  PracticeLoopStats row(String id, int count, {String? piece}) {
    return PracticeLoopStats(
      id: 'row-$id',
      studentId: 's1',
      teacherId: 't1',
      sectionId: 'sec-$id',
      repeatCount: count,
      lastPlayedAt: DateTime(2026, 6, 4),
      pieceName: piece,
    );
  }

  testWidgets('renders empty state for no rows', (tester) async {
    await tester.pumpWidget(host(const StudentRepeatChart(rows: [])));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.teacherStatsChartTitle), findsOneWidget);
    expect(find.text(AppStrings.teacherStatsStudentEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders empty state when all counts are zero', (tester) async {
    await tester.pumpWidget(
      host(StudentRepeatChart(rows: [row('a', 0), row('b', 0)])),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.teacherStatsStudentEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders chart for non-empty rows', (tester) async {
    await tester.pumpWidget(
      host(StudentRepeatChart(rows: [row('a', 12), row('b', 5)])),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.teacherStatsChartTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly in narrow viewport (regression)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        StudentRepeatChart(rows: [row('a', 8), row('b', 6), row('c', 3)]),
        width: 200,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
