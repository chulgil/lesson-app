import '../../../practice/domain/entities/practice_streak.dart';
import '../entities/streak_freeze.dart';

/// 결과 타입 — [StreakWithFreezeCalculator.compute] 의 반환값.
///
/// 순수 함수가 반환하는 권고/판정 정보. 실제 freeze 적용 (apply) 은
/// 호출자 (Job 5 Task 5.1.b) 의 책임 — calculator 는 side-effect 0.
class StreakWithFreezeResult {
  final int effectiveCurrentStreak;
  final bool freezeShouldApply;
  final DateTime? absenceDate;
  final bool streakBroken;
  final bool examModeDormant;

  const StreakWithFreezeResult({
    required this.effectiveCurrentStreak,
    required this.freezeShouldApply,
    required this.absenceDate,
    required this.streakBroken,
    required this.examModeDormant,
  });
}

/// Raw [PracticeStreak] + [StreakFreeze] 종합 — UI 표시용 effective streak 와
/// 자동 freeze 적용 권고를 산출.
///
/// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. 순수 함수 — side-effect 0.
class StreakWithFreezeCalculator {
  StreakWithFreezeCalculator._();

  /// [raw] 와 [freeze] 를 종합해 결과 반환.
  ///
  /// 4 시나리오 분기:
  /// 1. 어제/오늘 활동 → freeze 적용 X, raw 그대로
  /// 2. 어제 결석 + balance>0 + examMode 비활성 → freezeShouldApply=true
  /// 3. 어제 결석 + balance=0 → streakBroken=true
  /// 4. 어제 결석 + examMode 활성 → examModeDormant=true, streak 유지
  static StreakWithFreezeResult compute({
    required PracticeStreak raw,
    required StreakFreeze freeze,
    required DateTime now,
  }) {
    final lastDate = raw.lastPracticeDate;

    // 연습 이력 없는 신규 학생 — 결석 판정 X, 끊김 0
    if (lastDate == null) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: raw.currentStreak,
        freezeShouldApply: false,
        absenceDate: null,
        streakBroken: false,
        examModeDormant: false,
      );
    }

    // 활동 hot 판정: lastDate 가 어제 또는 오늘 (KST 자정 정렬)
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final daysSinceLastPractice = today.difference(lastDay).inDays;

    if (daysSinceLastPractice <= 1) {
      // 시나리오 1: 활동 hot — freeze 무관
      return StreakWithFreezeResult(
        effectiveCurrentStreak: raw.currentStreak,
        freezeShouldApply: false,
        absenceDate: null,
        streakBroken: false,
        examModeDormant: false,
      );
    }

    // 어제 결석 (daysSinceLastPractice >= 2)
    final yesterday = today.subtract(const Duration(days: 1));

    // 시나리오 4: examMode 활성 — freeze 차감 X, streak 동결
    if (!freeze.canApply(asOf: now) &&
        freeze.examModeUntil != null &&
        now.isBefore(freeze.examModeUntil!)) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: raw.currentStreak,
        freezeShouldApply: false,
        absenceDate: yesterday,
        streakBroken: false,
        examModeDormant: true,
      );
    }

    // 시나리오 2: balance>0 → freeze 적용 권고
    if (freeze.canApply(asOf: now)) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: raw.currentStreak,
        freezeShouldApply: true,
        absenceDate: yesterday,
        streakBroken: false,
        examModeDormant: false,
      );
    }

    // 시나리오 3: balance=0 → streak 끊김
    return StreakWithFreezeResult(
      effectiveCurrentStreak: raw.currentStreak,
      freezeShouldApply: false,
      absenceDate: yesterday,
      streakBroken: true,
      examModeDormant: false,
    );
  }
}
