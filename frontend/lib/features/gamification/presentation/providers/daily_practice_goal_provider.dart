// Student gamification P2 daily-satisfaction loop — 오늘의 연습 목표(분) + 잔디
// 연동 (doc 46 §4). [DailyGoalCard] (presentation/widgets) 가 소비한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'growth_heatmap_provider.dart';

part 'daily_practice_goal_provider.g.dart';

/// 학생별 "오늘의 연습 목표"(분) — 로컬 전용 설정, 기본 15분.
///
/// [PracticeGoal](features/practice)의 다차원(일/주 × 시간/구간) 목표 CRUD와는
/// 별개다. 이 provider 는 대시보드 상단의 가벼운 ESL 스타일 카드 전용 —
/// 원격 저장 없이 기기 로컬에만 남으며, `GoalAchievementStorage` 와 동일하게
/// lazy-open Hive box 패턴을 따른다 (박스 사전 오픈 불필요).
@Riverpod(keepAlive: true)
class DailyPracticeGoal extends _$DailyPracticeGoal {
  static const _boxName = 'daily_practice_goal_storage';

  /// 최초 표시 목표(분) — 사용자가 조절하기 전 기본값.
  static const int defaultGoalMinutes = 15;

  /// 조절 하한 — [DailyGoalCard] stepper 와 동일 범위.
  static const int minGoalMinutes = 5;

  /// 조절 상한 — [DailyGoalCard] stepper 와 동일 범위.
  static const int maxGoalMinutes = 60;

  @override
  Future<int> build(String studentId) async {
    try {
      final box = await Hive.openBox<int>(_boxName);
      return box.get(_keyFor(studentId)) ?? defaultGoalMinutes;
    } catch (_) {
      // Hive 미초기화(테스트 등) — 기본값으로 graceful degradation.
      return defaultGoalMinutes;
    }
  }

  /// 목표(분) 변경 — [minGoalMinutes]~[maxGoalMinutes] 로 clamp 후 영속.
  Future<void> setGoal(int minutes) async {
    final clamped = minutes.clamp(minGoalMinutes, maxGoalMinutes);
    state = AsyncData(clamped);
    try {
      final box = await Hive.openBox<int>(_boxName);
      await box.put(_keyFor(studentId), clamped);
    } catch (_) {
      // 영속 실패는 조용히 무시 — 메모리 상태(state)는 이미 갱신되어 이번
      // 세션에서는 유효하다. GoalAchievementStorage와 동일한 best-effort.
    }
  }

  static String _keyFor(String studentId) =>
      'student:$studentId:dailyPracticeGoal';
}

/// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
///
/// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
/// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
/// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
@riverpod
Future<int> todayPracticeMinutes(Ref ref, String studentId) async {
  final heatmap = await ref.watch(growthHeatmapProvider(studentId).future);
  final now = DateTime.now().toUtc();
  final todayKey = DateTime.utc(now.year, now.month, now.day);
  return heatmap.days[todayKey]?.totalMinutes ?? 0;
}
