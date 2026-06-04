import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_loop_stats.dart';
import 'package:lessonaza/features/practice/presentation/widgets/stats/student_loop_heatmap.dart';

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
      sectionName: id.toUpperCase(),
    );
  }

  testWidgets('renders nothing for empty rows', (tester) async {
    await tester.pumpWidget(host(const StudentLoopHeatmap(rows: [])));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.teacherStatsHardestSections), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders section labels and counts', (tester) async {
    await tester.pumpWidget(
      host(
        StudentLoopHeatmap(
          rows: [row('a', 10, piece: 'Sonata'), row('b', 4, piece: 'Concerto')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.teacherStatsHardestSections), findsOneWidget);
    expect(find.textContaining('Sonata'), findsOneWidget);
    expect(find.textContaining('Concerto'), findsOneWidget);
    expect(
      find.textContaining('10${AppStrings.teacherStatsRepeatsUnit}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly in a narrow viewport', (tester) async {
    await tester.pumpWidget(
      host(
        StudentLoopHeatmap(
          rows: [
            row('a', 10, piece: 'A really long piece name that wraps'),
            row('b', 2),
          ],
        ),
        width: 200,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
