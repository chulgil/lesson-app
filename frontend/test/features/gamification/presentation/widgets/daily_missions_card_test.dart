// DailyMissionsCard 위젯 테스트 — doc 46 §4④ (P3a 데일리 만족 루프).
//
// 0/부분/전부완료 3상태 스모크 테스트 (widget smoke test HARD-GATE).
// [daily_goal_card_test.dart] 패턴 미러 — DailyPracticeGoal/DailyMissionLedger
// 모두 lazy-open Hive box 를 쓰므로 real-Hive tempDir 초기화가 필요하다.
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
import 'package:lessonaza/features/gamification/presentation/widgets/daily_missions_card.dart';

/// 메모리 stub — [daily_goal_card_test.dart] 패턴 미러.
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

GrowthHeatmap _todayHeatmap(String studentId, DailyPractice today) {
  final now = DateTime.now().toUtc();
  final key = DateTime.utc(now.year, now.month, now.day);
  return GrowthHeatmap(studentId: studentId, days: {key: today});
}

Future<void> _pump(WidgetTester tester, {required DailyPractice today}) async {
  final stub = _StubGrowthHeatmapRepository(_todayHeatmap('m1', today));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [growthHeatmapRepositoryProvider.overrideWithValue(stub)],
      child: const MaterialApp(
        home: Scaffold(body: DailyMissionsCard(studentId: 'm1')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('daily_missions_card_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DailyMissionsCard — doc 46 §4④ (P3a 데일리 만족 루프)', () {
    testWidgets('0진행 — 3칸 모두 미완료, 보너스 미노출 (widget smoke test HARD-GATE)', (
      tester,
    ) async {
      await _pump(tester, today: const DailyPractice());
      expect(tester.takeException(), isNull);

      expect(find.byKey(const ValueKey('daily_missions_card')), findsOneWidget);
      expect(
        find.text(AppStrings.dailyMissionsProgressLabel(0, 3)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('daily_mission_stamp_pending')),
        findsNWidgets(3),
      );
      expect(
        find.byKey(const ValueKey('daily_mission_stamp_done')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('daily_missions_bonus_label')),
        findsNothing,
      );
    });

    testWidgets('부분 진행 — 고정 코어(연습 15분)만 완료, 로테이션 2개는 미완료', (tester) async {
      // 고정 코어(practice15m, 기본 목표 15분)만 채우고, 로테이션 후보
      // (메트로놈/튜너/녹음)는 모두 0 — 어느 2개가 로테이션되어도 미완료.
      await _pump(tester, today: const DailyPractice(manualMinutes: 15));
      expect(tester.takeException(), isNull);

      expect(
        find.text(AppStrings.dailyMissionsProgressLabel(1, 3)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('daily_mission_stamp_done')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('daily_mission_stamp_pending')),
        findsNWidgets(2),
      );
      expect(
        find.byKey(const ValueKey('daily_missions_bonus_label')),
        findsNothing,
      );
    });

    testWidgets('전부 완료 — 3/3 + 보너스 문구 노출', (tester) async {
      // 고정 코어 + 로테이션 후보 3종(메트로놈/튜너/녹음) 전부를 목표 이상
      // 채워, 어떤 2개가 로테이션되어도 전부 완료가 되도록 한다.
      await _pump(
        tester,
        today: const DailyPractice(
          manualMinutes: 15,
          metronomeMinutes: 2,
          tunerMinutes: 2,
          recordingCount: 1,
        ),
      );
      expect(tester.takeException(), isNull);

      expect(
        find.text(AppStrings.dailyMissionsProgressLabel(3, 3)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('daily_mission_stamp_done')),
        findsNWidgets(3),
      );
      expect(
        find.byKey(const ValueKey('daily_mission_stamp_pending')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('daily_missions_bonus_label')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.dailyMissionsAllDoneBonus), findsOneWidget);
    });
  });
}
