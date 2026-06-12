// Student gamification P2 — effective streak (raw streak + freeze) provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../practice/presentation/providers/practice_streak_provider.dart';
import '../../domain/services/streak_with_freeze_calculator.dart';
import 'streak_freeze_provider.dart';

part 'effective_streak_provider.g.dart';

/// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
///
/// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. side-effect 0 — 자동 freeze
/// 적용 trigger 는 Task 5.1.b (recordPractice 진입 시).
@riverpod
Future<StreakWithFreezeResult> effectiveStreak(
  Ref ref,
  String studentId,
) async {
  final raw = await ref.watch(practiceStreakProvider(studentId).future);
  final freeze = await ref.watch(studentStreakFreezeProvider(studentId).future);
  return StreakWithFreezeCalculator.compute(
    raw: raw,
    freeze: freeze,
    now: DateTime.now(),
  );
}
