import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_loop_stats.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_loop_stats_repository.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_loop_stats_provider.dart';
import 'package:lessonaza/features/practice/presentation/screens/practice_loop_stats_screen.dart';

class _StubRepository implements PracticeLoopStatsRepository {
  _StubRepository({
    this.summaryData = const [],
    this.rowsData = const [],
    this.totalRepeatsData = 0,
  });

  List<StudentRepeatStats> summaryData;
  List<PracticeLoopStats> rowsData;
  int totalRepeatsData;

  @override
  Future<({int totalRepeats, List<PracticeLoopStats> rows})> listForStudent({
    required String studentId,
    required PracticeLoopStatsWindow window,
  }) async => (totalRepeats: totalRepeatsData, rows: rowsData);

  @override
  Future<List<StudentRepeatStats>> summary({
    required PracticeLoopStatsWindow window,
  }) async => summaryData;

  @override
  Future<PracticeLoopStatsSyncResult> syncStudent({
    required List<PendingLoopStatsSync> entries,
  }) async => const PracticeLoopStatsSyncResult();
}

void main() {
  Widget host({
    required PracticeLoopStatsRepository repository,
    String? studentId,
  }) {
    return ProviderScope(
      overrides: [
        practiceLoopStatsRepositoryProvider.overrideWith((ref) => repository),
      ],
      child: MaterialApp(home: PracticeLoopStatsScreen(studentId: studentId)),
    );
  }

  testWidgets('renders title and window toggle', (tester) async {
    await tester.pumpWidget(host(repository: _StubRepository()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.teacherStatsTitle), findsOneWidget);
    expect(find.text(AppStrings.teacherStatsWeekly), findsOneWidget);
    expect(find.text(AppStrings.teacherStatsMonthly), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary mode — empty list shows empty state', (tester) async {
    await tester.pumpWidget(host(repository: _StubRepository()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.teacherStatsEmpty), findsOneWidget);
  });

  testWidgets('summary mode — student card visible and tappable', (
    tester,
  ) async {
    final repo = _StubRepository(
      summaryData: const [
        StudentRepeatStats(
          studentId: 's-1',
          studentName: 'Alice',
          totalRepeats: 12,
        ),
      ],
      rowsData: [
        PracticeLoopStats(
          id: 'row-a',
          studentId: 's-1',
          teacherId: 't-1',
          sectionId: 'sec-1',
          repeatCount: 12,
          lastPlayedAt: DateTime(2026, 6, 4),
          pieceName: 'Etude',
          sectionName: '1악장',
        ),
      ],
      totalRepeatsData: 12,
    );
    await tester.pumpWidget(host(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(
      find.textContaining('12${AppStrings.teacherStatsRepeatsUnit}'),
      findsWidgets,
    );

    // Tap the student card to drill down.
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.teacherStatsChartTitle), findsOneWidget);
    expect(find.text(AppStrings.teacherStatsHardestSections), findsOneWidget);
  });

  testWidgets('drilldown mode — direct studentId argument', (tester) async {
    final repo = _StubRepository(
      rowsData: [
        PracticeLoopStats(
          id: 'row-a',
          studentId: 's-1',
          teacherId: 't-1',
          sectionId: 'sec-1',
          repeatCount: 7,
          lastPlayedAt: DateTime(2026, 6, 4),
        ),
      ],
      totalRepeatsData: 7,
    );
    await tester.pumpWidget(host(repository: repo, studentId: 's-1'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.teacherStatsChartTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drilldown mode — empty rows shows empty state', (tester) async {
    await tester.pumpWidget(
      host(repository: _StubRepository(), studentId: 's-1'),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.teacherStatsStudentEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
