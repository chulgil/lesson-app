import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/domain/repositories/growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/daily_goal_card.dart';

/// 메모리 stub — [student_growth_detail_screen_test.dart] 패턴 미러.
class _StubGrowthHeatmapRepository implements GrowthHeatmapRepository {
  _StubGrowthHeatmapRepository(this._heatmap);
  final GrowthHeatmap _heatmap;

  @override
  Future<GrowthHeatmap> getHeatmap(
    String studentId, {
    int yearsBack = 1,
  }) async => _heatmap;

  @override
  Future<void> recordPractice(
    String studentId,
    DateTime date,
    DailyPractice evidence,
  ) async {}
}

GrowthHeatmap _todayHeatmap(String studentId, int todayMinutes) {
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  return GrowthHeatmap(
    studentId: studentId,
    days:
        todayMinutes > 0
            ? {today: DailyPractice(manualMinutes: todayMinutes)}
            : const {},
  );
}

Future<void> _pump(WidgetTester tester, {required int todayMinutes}) async {
  final stub = _StubGrowthHeatmapRepository(_todayHeatmap('s1', todayMinutes));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [growthHeatmapRepositoryProvider.overrideWithValue(stub)],
      child: const MaterialApp(
        home: Scaffold(body: DailyGoalCard(studentId: 's1')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // DailyPracticeGoal.setGoal 이 Hive box 를 열므로, 초기화 없이 두면 tap →
  // 조절 시트 confirm 경로가 미초기화 HiveError 를 던진다 (student_dashboard_
  // layout_test.dart 와 동일 패턴 — 실제 부팅과 가장 가까운 real Hive 사용).
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('daily_goal_card_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DailyGoalCard — doc 46 §4 (데일리 만족 루프 P2)', () {
    testWidgets('0분 — 진행바 0, 시작 유도 문구 (widget smoke test HARD-GATE)', (
      tester,
    ) async {
      await _pump(tester, todayMinutes: 0);
      expect(tester.takeException(), isNull);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('daily_goal_progress_bar')),
      );
      expect(bar.value, 0.0);
      expect(find.text(AppStrings.dailyGoalStartPrompt), findsOneWidget);
      expect(find.text('0/15분'), findsOneWidget);
    });

    testWidgets('부분 진행(7/15) — 진행바 비율 + 잔여 문구', (tester) async {
      await _pump(tester, todayMinutes: 7);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('daily_goal_progress_bar')),
      );
      expect(bar.value, closeTo(7 / 15, 0.001));
      expect(find.text('7/15분'), findsOneWidget);
      expect(find.text(AppStrings.dailyGoalRemainingLabel(8)), findsOneWidget);
    });

    testWidgets('100% 초과(30/15) — 진행바 상한 1.0, 라벨은 실제 분 유지', (tester) async {
      await _pump(tester, todayMinutes: 30);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('daily_goal_progress_bar')),
      );
      expect(bar.value, 1.0, reason: '진행바는 100% 상한 — 밀린/초과분 누적 표시 없음');
      expect(find.text('30/15분'), findsOneWidget, reason: '라벨은 실제 연습분을 유지');
      expect(find.text(AppStrings.dailyGoalAchievedLabel), findsOneWidget);
    });

    testWidgets('tap → 조절 시트에서 stepper 증가 + 확인 → provider 갱신', (tester) async {
      await _pump(tester, todayMinutes: 0);

      await tester.tap(find.byKey(const ValueKey('daily_goal_card')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('daily_goal_stepper_value')),
        findsOneWidget,
      );
      expect(find.text('15분'), findsOneWidget);

      // 5분씩 2회 증가 → 25분.
      await tester.tap(
        find.byKey(const ValueKey('daily_goal_stepper_increase')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('daily_goal_stepper_increase')),
      );
      await tester.pump();
      expect(find.text('25분'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('daily_goal_stepper_confirm')),
      );
      await tester.pumpAndSettle();

      // 시트가 닫히고 카드가 새 목표(25분)를 반영해야 한다.
      expect(find.text('0/25분'), findsOneWidget);
    });
  });
}
