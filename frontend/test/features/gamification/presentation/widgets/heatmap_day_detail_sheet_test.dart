import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/heatmap_day_detail_sheet.dart';

Future<void> _pump(
  WidgetTester tester, {
  required DateTime date,
  required DailyPractice daily,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: HeatmapDayDetailSheet(date: date, daily: daily)),
    ),
  );
}

void main() {
  group('HeatmapDayDetailSheet — Job 6 Task 6.2 / AC-6.2', () {
    final date = DateTime.utc(2026, 6, 12);

    testWidgets('widget smoke test — render exception 0 (HARD-GATE)', (
      tester,
    ) async {
      await _pump(tester, date: date, daily: const DailyPractice());
      expect(tester.takeException(), isNull);
    });

    testWidgets('5필드 모두 표시 — 메트로놈/튜너/YouTube/수동/녹음', (tester) async {
      await _pump(
        tester,
        date: date,
        daily: const DailyPractice(
          metronomeMinutes: 12,
          tunerMinutes: 5,
          youtubeMinutes: 8,
          recordingCount: 3,
          manualMinutes: 7,
        ),
      );

      expect(
        find.byKey(const ValueKey('heatmap_day_detail_sheet')),
        findsOneWidget,
      );
      expect(find.text('메트로놈'), findsOneWidget);
      expect(find.text('12분'), findsOneWidget);
      expect(find.text('튜너'), findsOneWidget);
      expect(find.text('5분'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('8분'), findsOneWidget);
      expect(find.text('수동'), findsOneWidget);
      expect(find.text('7분'), findsOneWidget);
      expect(find.text('녹음'), findsOneWidget);
      expect(find.text('3회'), findsOneWidget);
    });

    testWidgets('총 분 합산 표시 — totalMinutes', (tester) async {
      await _pump(
        tester,
        date: date,
        daily: const DailyPractice(
          metronomeMinutes: 10,
          tunerMinutes: 5,
          youtubeMinutes: 5,
          manualMinutes: 5,
        ),
      );

      expect(
        find.byKey(const ValueKey('heatmap_day_detail_total')),
        findsOneWidget,
      );
      expect(
        find.text('25분'),
        findsAtLeastNWidgets(1),
        reason: '10+5+5+5 = 25분 합산',
      );
    });

    testWidgets('빈 데이터 (0분) → 빈 상태 메시지', (tester) async {
      await _pump(tester, date: date, daily: const DailyPractice());

      expect(
        find.byKey(const ValueKey('heatmap_day_detail_empty')),
        findsOneWidget,
      );
    });

    testWidgets('일부 필드만 활동 → 활동 필드만 강조 (0분 행 hide)', (tester) async {
      await _pump(
        tester,
        date: date,
        daily: const DailyPractice(metronomeMinutes: 20),
      );

      // 메트로놈 행은 노출 (행 + 총 합산 = '20분' 2개 노출)
      expect(find.text('메트로놈'), findsOneWidget);
      expect(find.text('20분'), findsAtLeastNWidgets(1));
      // 0분 필드들은 hide
      expect(find.text('튜너'), findsNothing);
      expect(find.text('YouTube'), findsNothing);
      expect(find.text('수동'), findsNothing);
      expect(find.text('녹음'), findsNothing);
    });

    testWidgets('날짜 표시 — YYYY-MM-DD 또는 한글', (tester) async {
      await _pump(
        tester,
        date: date,
        daily: const DailyPractice(metronomeMinutes: 10),
      );

      // 날짜가 어떤 형태로든 노출됨 (헤더)
      final dateTextMatches = find.byKey(
        const ValueKey('heatmap_day_detail_date'),
      );
      expect(dateTextMatches, findsOneWidget);
    });
  });
}
