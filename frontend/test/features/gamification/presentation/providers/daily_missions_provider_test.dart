// dailyMissionsProvider + DailyMissionLedger 멱등 완료 테스트 — doc 46 §4④ (P3a).
//
// [DailyGoalCard]/[DailyPracticeGoal] 와 동일하게 lazy-open Hive box 를 쓰므로
// [daily_goal_card_test.dart] 와 같은 real-Hive tempDir 패턴을 따른다.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_mission.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_mission_kind.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/domain/repositories/growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/domain/services/daily_mission_rotation.dart';
import 'package:lessonaza/features/gamification/presentation/providers/daily_missions_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/daily_practice_goal_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';

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
  // Heatmap cells are keyed by the *local* calendar date tagged as UTC —
  // same derivation as _heatmapTodayKey in daily_missions_provider.dart.
  final now = DateTime.now();
  final key = DateTime.utc(now.year, now.month, now.day);
  return GrowthHeatmap(studentId: studentId, days: {key: today});
}

/// [dailyMissionsProvider]는 동기 조합(각 의존을 `.valueOrNull ?? 기본값`
/// 으로 읽음, [daily_missions_provider.dart] 참고) — 위젯 테스트의 synthetic
/// time 안에서 실제 Hive I/O 가 resolve 되지 않는 문제를 피하기 위한
/// 설계다. 그래서 순수 provider 테스트에서도 의존 provider(모두 autoDispose)
/// 들이 중간에 dispose 되지 않도록 [dailyMissionsProvider] 자체에
/// `container.listen` 으로 durable listener 를 먼저 걸어 둔 다음 — watch
/// 체인이 살아있는 상태에서 — 각 의존의 `.future` 를 await 해 "실제로
/// resolve 된 뒤" 최신 재계산 값을 읽어야 최종 진행값을 검증할 수 있다.
Future<List<DailyMission>> _settledMissions(
  ProviderContainer container,
  String studentId,
) async {
  final dateKst = DailyMissionRotation.kstCalendarDate(DateTime.now());
  final subscription = container.listen(
    dailyMissionsProvider(studentId),
    (_, __) {},
  );
  addTearDown(subscription.close);

  await container.read(dailyPracticeGoalProvider(studentId).future);
  await container.read(todayPracticeMinutesProvider(studentId).future);
  await container.read(todayMetronomeMinutesProvider(studentId).future);
  await container.read(todayTunerMinutesProvider(studentId).future);
  await container.read(todayRecordingCountProvider(studentId).future);
  await container.read(dailyMissionLedgerProvider(studentId, dateKst).future);
  return container.read(dailyMissionsProvider(studentId));
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('daily_missions_provider_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('dailyMissionsProvider — 진행/목표 파생 (doc 46 §4④)', () {
    test(
      'practice15m 은 dailyPracticeGoalProvider 목표 + heatmap 오늘 분을 반영',
      () async {
        final heatmap = _todayHeatmap(
          's1',
          const DailyPractice(manualMinutes: 7),
        );
        final container = ProviderContainer(
          overrides: [
            growthHeatmapRepositoryProvider.overrideWithValue(
              _StubGrowthHeatmapRepository(heatmap),
            ),
          ],
        );
        addTearDown(container.dispose);

        final missions = await _settledMissions(container, 's1');
        final practice = missions.firstWhere(
          (m) => m.kind == DailyMissionKind.practice15m,
        );
        expect(practice.target, DailyPracticeGoal.defaultGoalMinutes);
        expect(practice.progress, 7);
        expect(practice.completed, isFalse);
      },
    );

    test('metronome1/tuner1/recording1 은 heatmap 의 해당 필드에서 파생', () async {
      final heatmap = _todayHeatmap(
        's_tools',
        const DailyPractice(
          metronomeMinutes: 3,
          tunerMinutes: 0,
          recordingCount: 2,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          growthHeatmapRepositoryProvider.overrideWithValue(
            _StubGrowthHeatmapRepository(heatmap),
          ),
        ],
      );
      addTearDown(container.dispose);

      final missions = await _settledMissions(container, 's_tools');
      final byKind = {for (final m in missions) m.kind: m};

      if (byKind.containsKey(DailyMissionKind.metronome1)) {
        expect(byKind[DailyMissionKind.metronome1]!.progress, 3);
        expect(byKind[DailyMissionKind.metronome1]!.target, 1);
        expect(byKind[DailyMissionKind.metronome1]!.completed, isTrue);
      }
      if (byKind.containsKey(DailyMissionKind.tuner1)) {
        expect(byKind[DailyMissionKind.tuner1]!.progress, 0);
        expect(byKind[DailyMissionKind.tuner1]!.completed, isFalse);
      }
      if (byKind.containsKey(DailyMissionKind.recording1)) {
        expect(byKind[DailyMissionKind.recording1]!.progress, 2);
        expect(byKind[DailyMissionKind.recording1]!.completed, isTrue);
      }
    });

    test('항상 practice15m + 서로 다른 2개, 총 3개', () async {
      final heatmap = _todayHeatmap('s_shape', const DailyPractice());
      final container = ProviderContainer(
        overrides: [
          growthHeatmapRepositoryProvider.overrideWithValue(
            _StubGrowthHeatmapRepository(heatmap),
          ),
        ],
      );
      addTearDown(container.dispose);

      final missions = await _settledMissions(container, 's_shape');
      expect(missions.length, 3);
      expect(
        missions.where((m) => m.kind == DailyMissionKind.practice15m).length,
        1,
      );
      expect(missions.map((m) => m.kind).toSet().length, 3, reason: '중복 없음');
    });
  });

  group('DailyMissionLedger — 멱등 완료 원장 (doc 46 §4④)', () {
    test('목표를 나중에 올려도 원장에 기록된 완료는 유지된다', () async {
      final heatmap = _todayHeatmap(
        's_sticky',
        const DailyPractice(manualMinutes: 15),
      );
      final container = ProviderContainer(
        overrides: [
          growthHeatmapRepositoryProvider.overrideWithValue(
            _StubGrowthHeatmapRepository(heatmap),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 기본 목표 15분 → practice15m derived 완료.
      var missions = await _settledMissions(container, 's_sticky');
      var practice = missions.firstWhere(
        (m) => m.kind == DailyMissionKind.practice15m,
      );
      expect(practice.completed, isTrue);

      // DailyMissionsCard 의 post-frame lock 을 시뮬레이션 — 완료 원장 기록.
      final dateKst = DailyMissionRotation.kstCalendarDate(DateTime.now());
      await container
          .read(dailyMissionLedgerProvider('s_sticky', dateKst).notifier)
          .markCompleted(DailyMissionKind.practice15m);

      // 목표를 30분으로 올리면 derived(15>=30)는 false 이지만, 원장 때문에
      // completed 는 유지되어야 한다 — 이미 채운 스탬프가 되돌아가지 않음.
      await container
          .read(dailyPracticeGoalProvider('s_sticky').notifier)
          .setGoal(30);
      missions = await _settledMissions(container, 's_sticky');
      practice = missions.firstWhere(
        (m) => m.kind == DailyMissionKind.practice15m,
      );
      expect(practice.target, 30);
      expect(practice.progress, 15, reason: '진행값 자체는 변하지 않음');
      expect(
        practice.completed,
        isTrue,
        reason: '원장에 기록된 완료는 목표 상향 조정에도 되돌아가지 않는다',
      );
    });

    test('markCompleted 는 멱등 — 같은 kind 재호출해도 원장 내용 불변', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dateKst = DateTime(2026, 7, 30);
      final notifier = container.read(
        dailyMissionLedgerProvider('s_idem', dateKst).notifier,
      );
      // 프로덕션 불변식과 동일하게, 첫 build 가 끝난 뒤에만 mutate 한다 —
      // 그렇지 않으면 in-flight build() 완료 시점의 값이 markCompleted 의
      // 낙관적 쓰기를 덮어써 레이스가 난다. [DailyMissionsCard] 도
      // [dailyMissionsProvider]가 이미 이 future 를 await 한 뒤에만
      // notifier 를 읽는다.
      await container.read(
        dailyMissionLedgerProvider('s_idem', dateKst).future,
      );

      await notifier.markCompleted(DailyMissionKind.tuner1);
      final afterFirst = await container.read(
        dailyMissionLedgerProvider('s_idem', dateKst).future,
      );
      expect(afterFirst, {DailyMissionKind.tuner1});

      await notifier.markCompleted(DailyMissionKind.tuner1);
      final afterSecond = await container.read(
        dailyMissionLedgerProvider('s_idem', dateKst).future,
      );
      expect(afterSecond, {DailyMissionKind.tuner1});
    });

    test('완료 원장은 (학생, 날짜) 로 격리 — 다른 날짜는 영향 없음', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final day1 = DateTime(2026, 7, 30);
      final day2 = DateTime(2026, 7, 31);

      await container.read(
        dailyMissionLedgerProvider('s_isolate', day1).future,
      );
      await container
          .read(dailyMissionLedgerProvider('s_isolate', day1).notifier)
          .markCompleted(DailyMissionKind.recording1);

      final ledgerDay2 = await container.read(
        dailyMissionLedgerProvider('s_isolate', day2).future,
      );
      expect(ledgerDay2, isEmpty);
    });
  });
}
