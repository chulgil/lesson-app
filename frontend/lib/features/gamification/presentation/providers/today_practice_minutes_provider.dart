// Student gamification P2 daily-satisfaction loop — 오늘 연습 분(分) 파생
// (doc 46 §4). #1269: 이 파일이 갖고 있던 device-local 목표 값
// (`DailyPracticeGoal`)은 features/practice 의 원격 영속 [PracticeGoal] 로
// 통합되었다 — `practice_facade.dart` 의 `effectiveDailyGoalMinutesProvider`
// 참조. 이 파일에는 목표와 무관한, heatmap 파생 "오늘 연습 분" 읽기 전용
// provider 만 남는다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'growth_heatmap_provider.dart';

part 'today_practice_minutes_provider.g.dart';

/// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
///
/// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
/// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
/// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
@riverpod
Future<int> todayPracticeMinutes(Ref ref, String studentId) async {
  final heatmap = await ref.watch(growthHeatmapProvider(studentId).future);
  // Heatmap cells are keyed by the *local* calendar date tagged as UTC
  // (PracticeRecordingService uses occurredAt's local y/m/d), so "today"
  // must derive from local time — the old toUtc() derivation pointed at
  // yesterday's cell between 00:00-08:59 KST.
  final now = DateTime.now();
  final todayKey = DateTime.utc(now.year, now.month, now.day);
  return heatmap.days[todayKey]?.totalMinutes ?? 0;
}
