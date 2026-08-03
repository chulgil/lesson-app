// Student gamification P3a daily-satisfaction loop — 오늘의 미션(고정1+로테이션2,
// doc 46 §4④). [DailyMissionsCard](presentation/widgets) 가 소비한다.
//
// 서버 quest 시스템을 새로 두지 않고, P2 가 이미 채우는 관측 신호
// ([todayPracticeMinutesProvider]와 같은 패턴으로 [growthHeatmapProvider]의
// 오늘 cell 에서 파생한 메트로놈/튜너/녹음 신호)만으로 미션 진행을 계산한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/daily_mission.dart';
import '../../domain/entities/daily_mission_kind.dart';
import '../../domain/services/daily_mission_rotation.dart';
import 'daily_practice_goal_provider.dart';
import 'growth_heatmap_provider.dart';

part 'daily_missions_provider.g.dart';

/// [growthHeatmapProvider]의 오늘 cell 을 찾는 key. [todayPracticeMinutesProvider]
/// 와 정확히 동일한 파생식 — 이 provider 들이 서로 다른 "오늘"을 가리키면
/// 같은 카드 안에서 미션 진행이 [DailyGoalCard] 진행과 어긋나 보인다. (참고:
/// 이 key 는 실제로는 UTC 달력일이라 KST 자정과는 다르게 구르지만, 그 어긋남
/// 은 P2 부터 있던 기존 동작 — 이 미션 기능의 범위가 아니다. 로테이션/
/// 완료원장의 KST 자정 계약은 [DailyMissionRotation.kstCalendarDate] 가
/// 별도로 담당한다.)
DateTime _heatmapTodayKey() {
  final now = DateTime.now().toUtc();
  return DateTime.utc(now.year, now.month, now.day);
}

/// 오늘 메트로놈 연습 분 — [todayPracticeMinutesProvider]와 동일 소스
/// ([growthHeatmapProvider]의 오늘 cell)에서 필드만 다르게 읽는다. 새
/// 트래킹 파이프라인 없음.
@riverpod
Future<int> todayMetronomeMinutes(Ref ref, String studentId) async {
  final heatmap = await ref.watch(growthHeatmapProvider(studentId).future);
  return heatmap.days[_heatmapTodayKey()]?.metronomeMinutes ?? 0;
}

/// 오늘 튜너 연습 분 — 위와 동일 소스.
@riverpod
Future<int> todayTunerMinutes(Ref ref, String studentId) async {
  final heatmap = await ref.watch(growthHeatmapProvider(studentId).future);
  return heatmap.days[_heatmapTodayKey()]?.tunerMinutes ?? 0;
}

/// 오늘 녹음 횟수 — 위와 동일 소스. 분이 아니라 횟수([DailyPractice.
/// recordingCount])이므로 target=1(1회 이상)로 소비한다.
@riverpod
Future<int> todayRecordingCount(Ref ref, String studentId) async {
  final heatmap = await ref.watch(growthHeatmapProvider(studentId).future);
  return heatmap.days[_heatmapTodayKey()]?.recordingCount ?? 0;
}

/// 데일리 미션 완료 원장 — 로컬 Hive, 멱등 (doc 46 §4④).
///
/// 관측 신호(progress)가 흔들려도(예: [DailyPracticeGoal] 를 상향 조정)
/// 한 번 완료된 미션은 그날(KST) 안에서는 계속 완료 상태를 유지한다 —
/// derived-only 라면 15/15 로 채운 뒤 목표를 30분으로 올리면 이미 채운
/// 스탬프가 되돌아가는 회귀가 생긴다. [DailyGoalCard]/`daily_practice_goal_
/// provider.dart` 와 동일하게 lazy-open Hive box 패턴을 따른다.
///
/// box key = `student:<id>:missions:<dateKey>`, value = 완료된
/// [DailyMissionKind.name] CSV. 쓰기는 [DailyMissionsCard] 가 프레임 이후
/// (post-frame) 시점에 호출한다 — provider build 도중 자기 자신이 아닌
/// 다른 provider 를 동기적으로 mutate 하는 패턴을 피하기 위함.
@Riverpod(keepAlive: true)
class DailyMissionLedger extends _$DailyMissionLedger {
  static const _boxName = 'daily_mission_ledger_storage';

  @override
  Future<Set<DailyMissionKind>> build(
    String studentId,
    DateTime dateKst,
  ) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final raw = box.get(_keyFor(studentId, dateKst));
      if (raw == null || raw.isEmpty) return const {};
      final result = <DailyMissionKind>{};
      for (final name in raw.split(',')) {
        if (DailyMissionKind.values.any((k) => k.name == name)) {
          result.add(DailyMissionKind.values.byName(name));
        }
      }
      return result;
    } catch (_) {
      // Hive 미초기화(테스트 등) — 빈 원장으로 graceful degradation.
      return const {};
    }
  }

  /// [kind] 를 완료로 기록 — 이미 기록되어 있으면 아무 것도 하지 않는다
  /// (멱등, 중복 Hive 쓰기 없음).
  Future<void> markCompleted(DailyMissionKind kind) async {
    final current = state.valueOrNull ?? const <DailyMissionKind>{};
    if (current.contains(kind)) return;
    final updated = {...current, kind};
    state = AsyncData(updated);
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(
        _keyFor(studentId, dateKst),
        updated.map((k) => k.name).join(','),
      );
    } catch (_) {
      // 영속 실패는 조용히 무시 — 메모리 상태(state)는 이미 갱신되어 이번
      // 세션에서는 유효하다 (DailyPracticeGoal 과 동일 best-effort).
    }
  }

  static String _keyFor(String studentId, DateTime dateKst) =>
      'student:$studentId:missions:${dateKst.year}-${dateKst.month}-${dateKst.day}';
}

/// 오늘의 미션 3종(고정1+로테이션2) — 로테이션 + 진행값 + 완료 원장을
/// 조합한 최종 표시 데이터.
///
/// [DailyGoalCard]/`daily_practice_goal_provider.dart` 와 동일하게 각 의존
/// provider 를 `.valueOrNull ?? 기본값` 으로 읽는다(watch 는 하되 future 를
/// await 하지 않음) — Hive 기반 provider(목표/원장)의 `.future` 를 그대로
/// await 하면 위젯 테스트의 synthetic time 안에서 실제 파일 I/O 가 끝내
/// resolve 되지 않아 화면이 영원히 loading 에 멈추는 문제가 있었다(회귀
/// 확인됨). sync 조합이면 첫 프레임은 기본값(0진행/기본목표)으로 그리고,
/// 각 provider 가 실제로 resolve 되는 순간 자동 재계산된다.
@riverpod
List<DailyMission> dailyMissions(Ref ref, String studentId) {
  final now = DateTime.now();
  final dateKst = DailyMissionRotation.kstCalendarDate(now);
  final kinds = DailyMissionRotation.missionsFor(studentId, now);

  final goal =
      ref.watch(dailyPracticeGoalProvider(studentId)).valueOrNull ??
      DailyPracticeGoal.defaultGoalMinutes;
  final practiceMinutes =
      ref.watch(todayPracticeMinutesProvider(studentId)).valueOrNull ?? 0;
  final metronomeMinutes =
      ref.watch(todayMetronomeMinutesProvider(studentId)).valueOrNull ?? 0;
  final tunerMinutes =
      ref.watch(todayTunerMinutesProvider(studentId)).valueOrNull ?? 0;
  final recordingCount =
      ref.watch(todayRecordingCountProvider(studentId)).valueOrNull ?? 0;
  final ledger =
      ref.watch(dailyMissionLedgerProvider(studentId, dateKst)).valueOrNull ??
      const <DailyMissionKind>{};

  return [
    for (final kind in kinds)
      _toMission(
        kind,
        goal: goal,
        practiceMinutes: practiceMinutes,
        metronomeMinutes: metronomeMinutes,
        tunerMinutes: tunerMinutes,
        recordingCount: recordingCount,
        ledger: ledger,
      ),
  ];
}

DailyMission _toMission(
  DailyMissionKind kind, {
  required int goal,
  required int practiceMinutes,
  required int metronomeMinutes,
  required int tunerMinutes,
  required int recordingCount,
  required Set<DailyMissionKind> ledger,
}) {
  final (target, progress) = switch (kind) {
    DailyMissionKind.practice15m => (goal, practiceMinutes),
    DailyMissionKind.metronome1 => (1, metronomeMinutes),
    DailyMissionKind.tuner1 => (1, tunerMinutes),
    DailyMissionKind.recording1 => (1, recordingCount),
  };
  final derivedDone = target > 0 && progress >= target;
  return DailyMission(
    kind: kind,
    target: target,
    progress: progress,
    completed: derivedDone || ledger.contains(kind),
  );
}
