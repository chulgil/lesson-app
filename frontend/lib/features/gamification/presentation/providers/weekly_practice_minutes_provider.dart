// Student gamification P2 daily-satisfaction loop — 이번 주 연습 분(分) 파생
// (doc 46 §4). #1273: [PracticeGoal] weekly 진행값이 practice-logs(스트릭
// 전용 — `PracticeService.record_practice` 가 1분 minimal log만 남긴다)를
// 소스로 삼아 항상 0에 가깝게 표시되던 결함을 고쳤다. [todayPracticeMinutes]
// (같은 파일 today 버전, gamification/presentation/providers/
// today_practice_minutes_provider.dart)와 짝을 이루는 주간 버전 — 새 트래킹
// 파이프라인을 만들지 않고 동일한 heatmap 소스에서 파생한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'growth_heatmap_provider.dart';

part 'weekly_practice_minutes_provider.g.dart';

/// 이번 주(월요일 시작) 연습 분 총합 — [GrowthHeatmap]과 완전히 동일한
/// 소스에서 파생.
///
/// heatmap 의 day key 는 로컬 날짜를 UTC 자정으로 태깅한 값
/// ([GrowthHeatmap] 문서 참조)이므로, 로컬 기준 "이번 주 월요일"을 UTC
/// 자정으로 정규화한 뒤 [GrowthHeatmap.weekTotal]로 조회한다.
@riverpod
Future<int> weeklyPracticeMinutes(Ref ref, String studentId) async {
  final heatmap = await ref.watch(growthHeatmapProvider(studentId).future);
  final now = DateTime.now();
  final weekStartLocal = now.subtract(Duration(days: now.weekday - 1));
  final weekStartKey = DateTime.utc(
    weekStartLocal.year,
    weekStartLocal.month,
    weekStartLocal.day,
  );
  return heatmap.weekTotal(weekStartKey);
}
