// Student gamification P2 — effective streak (raw streak + freeze) provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../practice/practice_facade.dart'
    show practiceLogsProvider, practiceStreakProvider;
import '../../domain/services/streak_with_freeze_calculator.dart';
import 'streak_freeze_provider.dart';

part 'effective_streak_provider.g.dart';

/// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
///
/// 스펙 §6.5 / §14.1 / §14.2. 표시용 SSOT — 학생 화면의 모든 스트릭 숫자는
/// 이 provider 를 통한다 (`docs/specs/practice/streak_ssot.md` §1 Phase 3).
///
/// 읽기 시 두 가지 부수효과가 일어난다. 둘 다 멱등이라 재빌드에 안전하다.
/// 1. §14.1 주간 발급 — `lastGrantedAt` 게이트 (주 1회만 +2)
/// 2. §14.2 결석일 차감 — `usedAt` 게이트 (같은 날짜 재차감 X)
@riverpod
Future<StreakWithFreezeResult> effectiveStreak(
  Ref ref,
  String studentId,
) async {
  final now = DateTime.now();
  final service = ref.watch(streakFreezeServiceProvider);
  final repository = ref.watch(streakFreezeRepositoryProvider);

  // §14.1 — 일요일 00:00 KST 기준 주간 발급 (자격 없으면 no-op).
  await service.weeklyGrantIfDue(studentId: studentId, now: now);

  final raw = await ref.watch(practiceStreakProvider(studentId).future);
  final logs = await ref.watch(practiceLogsProvider(studentId).future);

  var freeze = await repository.getOrCreate(studentId);
  var result = StreakWithFreezeCalculator.compute(
    raw: raw,
    freeze: freeze,
    now: now,
    practiceLogs: logs,
  );

  // §14.2 — 결석일 자동 차감 후 재계산. 차감된 날짜는 `usedAt` 에 기록되어
  // 재계산 시 "이미 덮인 공백" 으로 잡히므로 스트릭이 유지된다.
  if (result.freezeShouldApply) {
    freeze = await service.applyForAbsences(
      studentId: studentId,
      missedDates: result.pendingFreezeDates,
    );
    result = StreakWithFreezeCalculator.compute(
      raw: raw,
      freeze: freeze,
      now: now,
      practiceLogs: logs,
    );
  }

  return result;
}
