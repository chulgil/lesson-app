import '../../../practice/domain/entities/practice_log.dart';
import '../../../practice/domain/entities/practice_streak.dart';
import '../entities/streak_freeze.dart';

/// 결과 타입 — [StreakWithFreezeCalculator.compute] 의 반환값.
///
/// 순수 함수가 반환하는 표시값 + 권고 정보. 실제 freeze 차감 (apply) 은
/// 호출자 (presentation provider) 의 책임 — calculator 는 side-effect 0.
class StreakWithFreezeResult {
  /// 화면에 표시할 스트릭. freeze 로 이어진 공백을 건너뛰고 센 값.
  final int effectiveCurrentStreak;

  /// 아직 차감되지 않은 결석일이 있고, 잔여 freeze 로 전부 덮을 수 있음.
  final bool freezeShouldApply;

  final DateTime? absenceDate;
  final bool streakBroken;
  final bool examModeDormant;

  /// [freezeShouldApply] 일 때 차감해야 할 결석일 목록 (오래된 날짜부터).
  final List<DateTime> pendingFreezeDates;

  /// 잔여 freeze 개수 — 보호권 배지 표시용.
  final int freezeBalance;

  const StreakWithFreezeResult({
    required this.effectiveCurrentStreak,
    required this.freezeShouldApply,
    required this.absenceDate,
    required this.streakBroken,
    required this.examModeDormant,
    this.pendingFreezeDates = const [],
    this.freezeBalance = 0,
  });
}

/// Raw [PracticeStreak] + [StreakFreeze] 종합 — 표시용 effective streak 와
/// 자동 freeze 차감 권고를 산출.
///
/// 스펙 §6.5 / §14.1 / §14.2 (`.harness/spec/2026-06-11-student-gamification.md`),
/// `docs/specs/practice/streak_ssot.md` §1 Phase 3. 순수 함수 — side-effect 0.
///
/// 정규 스트릭(streak_ssot §1)은 공백 하루에 끊긴다. freeze 는 그 공백을
/// **이어주기만** 하고 일수를 늘리지는 않는다 (§14.2 "스트릭 유지").
class StreakWithFreezeCalculator {
  StreakWithFreezeCalculator._();

  /// [raw] 와 [freeze] 를 종합해 결과 반환.
  ///
  /// 5 시나리오 분기:
  /// 1. 연습 이력 없음 → 결석 판정 X
  /// 2. 어제/오늘 활동 → 공백 없음, freeze 무관
  /// 3. 결석일 전부 차감 완료 → 스트릭 유지 (재차감 X)
  /// 4. 미차감 결석일 <= balance → freezeShouldApply=true, 스트릭 유지
  /// 5. 미차감 결석일 > balance → streakBroken=true (freeze 1개 = 결석 1일)
  ///
  /// [practiceLogs] 가 비어 있으면 [raw] 의 값을 그대로 신뢰한다 (로그 미조회).
  static StreakWithFreezeResult compute({
    required PracticeStreak raw,
    required StreakFreeze freeze,
    required DateTime now,
    Iterable<PracticeLog> practiceLogs = const [],
  }) {
    final lastDate = raw.lastPracticeDate;

    // 시나리오 1: 연습 이력 없는 신규 학생 — 결석 판정 X, 끊김 0
    if (lastDate == null) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: raw.currentStreak,
        freezeShouldApply: false,
        absenceDate: null,
        streakBroken: false,
        examModeDormant: false,
        freezeBalance: freeze.balance,
      );
    }

    final today = _dateOnly(now);
    final lastDay = _dateOnly(lastDate);
    final daysSinceLastPractice = today.difference(lastDay).inDays;

    // freeze 로 이어진 공백을 건너뛴 스트릭. 모든 분기가 이 값을 쓴다 —
    // raw.currentStreak 은 공백에서 이미 0 으로 끊겨 있기 때문.
    final bridged = _bridgedStreak(
      raw: raw,
      freeze: freeze,
      logs: practiceLogs,
      anchor: lastDay,
    );

    // 시나리오 2: 활동 hot (오늘 또는 어제 연습) — 공백 없음
    if (daysSinceLastPractice <= 1) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: bridged,
        freezeShouldApply: false,
        absenceDate: null,
        streakBroken: false,
        examModeDormant: false,
        freezeBalance: freeze.balance,
      );
    }

    // 결석 구간 = 마지막 연습일 다음날 ~ 어제. 오늘은 아직 끝나지 않아 제외.
    final missedDates = <DateTime>[
      for (var i = 1; i < daysSinceLastPractice; i++)
        lastDay.add(Duration(days: i)),
    ];
    final frozen = _frozenDays(freeze);
    final uncovered = missedDates
        .where((date) => !frozen.contains(date))
        .toList();
    final yesterday = today.subtract(const Duration(days: 1));

    // 시나리오 3: 결석일이 전부 이미 차감됨 → 유지 (재차감 금지 — 멱등)
    if (uncovered.isEmpty) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: bridged,
        freezeShouldApply: false,
        absenceDate: yesterday,
        streakBroken: false,
        examModeDormant: false,
        freezeBalance: freeze.balance,
      );
    }

    // 시험 모드 (§14.3): 스트릭 동결 + freeze 차감 0
    final examUntil = freeze.examModeUntil;
    if (examUntil != null && now.isBefore(examUntil)) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: bridged,
        freezeShouldApply: false,
        absenceDate: yesterday,
        streakBroken: false,
        examModeDormant: true,
        freezeBalance: freeze.balance,
      );
    }

    // 시나리오 4 (§14.2): freeze 1개 = 결석 1일. 전부 덮을 수 있을 때만 유지.
    if (freeze.balance >= uncovered.length) {
      return StreakWithFreezeResult(
        effectiveCurrentStreak: bridged,
        freezeShouldApply: true,
        absenceDate: yesterday,
        streakBroken: false,
        examModeDormant: false,
        pendingFreezeDates: uncovered,
        freezeBalance: freeze.balance,
      );
    }

    // 시나리오 5: 공백이 잔여 freeze 보다 길다 → 끊김
    return StreakWithFreezeResult(
      effectiveCurrentStreak: 0,
      freezeShouldApply: false,
      absenceDate: yesterday,
      streakBroken: true,
      examModeDormant: false,
      freezeBalance: freeze.balance,
    );
  }

  /// [anchor] (마지막 연습일) 에서 역방향으로 센 스트릭.
  ///
  /// streak_ssot §1 의 역방향 카운트에 freeze 브리지를 더한 것 — 차감된 결석일
  /// (`usedAt`) 은 체인을 **잇되 일수에 더하지 않는다**. 연습 로그가 없으면
  /// (미조회) [raw] 값을 그대로 신뢰.
  static int _bridgedStreak({
    required PracticeStreak raw,
    required StreakFreeze freeze,
    required Iterable<PracticeLog> logs,
    required DateTime anchor,
  }) {
    final practiced = <DateTime>{
      for (final log in logs)
        if (log.totalMinutes > 0) _dateOnly(log.date),
    };
    if (practiced.isEmpty) return raw.currentStreak;

    final frozen = _frozenDays(freeze);
    var count = 0;
    var cursor = anchor;
    while (practiced.contains(cursor) || frozen.contains(cursor)) {
      if (practiced.contains(cursor)) count += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  static Set<DateTime> _frozenDays(StreakFreeze freeze) => {
    for (final date in freeze.usedAt) _dateOnly(date),
  };

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
