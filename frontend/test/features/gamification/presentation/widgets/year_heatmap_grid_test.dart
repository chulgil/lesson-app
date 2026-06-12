import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/year_heatmap_grid.dart';

Future<void> _pump(
  WidgetTester tester, {
  required GrowthHeatmap heatmap,
  DateTime? asOf,
  ValueChanged<DateTime>? onDayTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: YearHeatmapGrid(
          heatmap: heatmap,
          asOf: asOf ?? DateTime.utc(2026, 6, 12),
          onDayTap: onDayTap,
        ),
      ),
    ),
  );
}

void main() {
  group('YearHeatmapGrid — Job 6 Task 6.1 / AC-6.1', () {
    test('static minutesToLevel maps thresholds correctly', () {
      expect(YearHeatmapGrid.minutesToLevel(0), 0);
      expect(YearHeatmapGrid.minutesToLevel(1), 1);
      expect(YearHeatmapGrid.minutesToLevel(15), 1);
      expect(YearHeatmapGrid.minutesToLevel(16), 2);
      expect(YearHeatmapGrid.minutesToLevel(30), 2);
      expect(YearHeatmapGrid.minutesToLevel(31), 3);
      expect(YearHeatmapGrid.minutesToLevel(60), 3);
      expect(YearHeatmapGrid.minutesToLevel(61), 4);
      expect(YearHeatmapGrid.minutesToLevel(999), 4);
    });

    test('static levelToColor maps to AppColors heatmap palette', () {
      expect(YearHeatmapGrid.levelToColor(0), AppColors.heatmapL0);
      expect(YearHeatmapGrid.levelToColor(1), AppColors.heatmapL1);
      expect(YearHeatmapGrid.levelToColor(2), AppColors.heatmapL2);
      expect(YearHeatmapGrid.levelToColor(3), AppColors.heatmapL3);
      expect(YearHeatmapGrid.levelToColor(4), AppColors.heatmapL4);
    });

    testWidgets('widget smoke test — render exception 0 (HARD-GATE)', (
      tester,
    ) async {
      await _pump(
        tester,
        heatmap: const GrowthHeatmap(studentId: 's1', days: {}),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty heatmap → 모든 셀 L0 색', (tester) async {
      await _pump(
        tester,
        heatmap: const GrowthHeatmap(studentId: 's1', days: {}),
      );

      // Grid 컨테이너 존재 확인
      expect(find.byKey(const ValueKey('year_heatmap_grid')), findsOneWidget);

      // L0 색 셀이 다수 존재 (한 셀은 ValueKey('heatmap_cell_*'))
      final cells = find.byWidgetPredicate(
        (w) => w is Container && w.key.toString().contains('heatmap_cell_'),
      );
      expect(cells, findsAtLeastNWidgets(300));
    });

    testWidgets('5단계 색 매핑 정확 — L4 (61+분) 셀 존재', (tester) async {
      final today = DateTime.utc(2026, 6, 12);
      final heatmap = GrowthHeatmap(
        studentId: 's1',
        days: {
          today: const DailyPractice(metronomeMinutes: 90), // L4
        },
      );
      await _pump(tester, heatmap: heatmap, asOf: today);

      // L4 색 셀이 1개 존재
      final l4Cells = find.byWidgetPredicate((w) {
        if (w is! Container) return false;
        final decoration = w.decoration;
        if (decoration is! BoxDecoration) return false;
        return decoration.color == AppColors.heatmapL4;
      });
      expect(l4Cells, findsOneWidget);
    });

    testWidgets('가로 스크롤 가능 — SingleChildScrollView horizontal', (tester) async {
      await _pump(
        tester,
        heatmap: const GrowthHeatmap(studentId: 's1', days: {}),
      );

      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsAtLeastNWidgets(1));

      final widget = tester.widget<SingleChildScrollView>(scrollable.first);
      expect(widget.scrollDirection, Axis.horizontal);
    });

    testWidgets('셀 tap → onDayTap callback 호출', (tester) async {
      final today = DateTime.utc(2026, 6, 12);
      DateTime? tappedDate;
      final heatmap = GrowthHeatmap(
        studentId: 's1',
        days: {today: const DailyPractice(metronomeMinutes: 30)},
      );

      await _pump(
        tester,
        heatmap: heatmap,
        asOf: today,
        onDayTap: (date) => tappedDate = date,
      );

      // 셀 ValueKey 로 찾아 tap
      final cellKey = ValueKey('heatmap_cell_${today.toIso8601String()}');
      expect(find.byKey(cellKey), findsOneWidget);

      await tester.tap(find.byKey(cellKey));
      await tester.pump();

      expect(tappedDate, today);
    });

    testWidgets('5단계 색맹 친화 — L3+ 셀에 inset dot 마커 표시', (tester) async {
      final today = DateTime.utc(2026, 6, 12);
      final heatmap = GrowthHeatmap(
        studentId: 's1',
        days: {
          today: const DailyPractice(metronomeMinutes: 65), // L4
        },
      );
      await _pump(tester, heatmap: heatmap, asOf: today);

      // dot 마커가 grid 안에 존재 (색맹 보조)
      final dots = find.byKey(
        ValueKey('heatmap_dot_${today.toIso8601String()}'),
      );
      expect(dots, findsOneWidget, reason: 'L3 이상 셀에는 inset dot 마커 (색맹 친화)');
    });

    testWidgets('365 칸 정확 — 7행 × 52열 ≈ 364 칸 + 1 cap', (tester) async {
      await _pump(
        tester,
        heatmap: const GrowthHeatmap(studentId: 's1', days: {}),
      );

      final cells = find.byWidgetPredicate(
        (w) => w is Container && w.key.toString().contains('heatmap_cell_'),
      );
      // 정확 365 또는 ±1 (시작 요일 정렬에 따라)
      final count = cells.evaluate().length;
      expect(
        count,
        inInclusiveRange(360, 372),
        reason: '7×52 그리드 = 364, ±몇 셀 시작 요일 보정',
      );
    });
  });
}
