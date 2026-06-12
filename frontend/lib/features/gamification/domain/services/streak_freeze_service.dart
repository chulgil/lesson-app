import '../entities/streak_freeze.dart';
import '../repositories/streak_freeze_repository.dart';

/// 스트릭 동결 서비스 — 자동 발급/적용 + 시험 모드.
///
/// 스펙 §6.5 / §14 / 플랜 Job 4 Task 4.1.
///
/// **타임존**: 모든 학생 동일 — `Asia/Seoul` (UTC+9 고정, DST 없음).
/// 글로벌 익명 리더보드 (P4) 동기화 일관성을 위해 `package:timezone` 의존
/// 없이 단순 산술 변환.
class StreakFreezeService {
  StreakFreezeService({required this.repository});

  final StreakFreezeRepository repository;

  /// KST 시간대 오프셋 — `Asia/Seoul` UTC+9 고정 (DST 없음).
  static const Duration _kstOffset = Duration(hours: 9);

  /// [now] (UTC) 시점에서 직전 일요일 자정 KST 의 UTC instant 를 반환.
  ///
  /// 예: now = 2026-06-12 09:00 KST (= 2026-06-12 00:00 UTC) →
  /// 결과 = 2026-06-07 00:00 KST (= 2026-06-06 15:00 UTC).
  ///
  /// 일요일 자정 정각 직전 (sat 23:59 KST) → 같은 주 일요일.
  /// 일요일 00:00:01 KST → 그 일요일 (직전 주가 아님).
  static DateTime previousSundayMidnightKstAsUtc(DateTime now) {
    final kst = now.toUtc().add(_kstOffset);
    // DateTime.weekday: Mon=1, Tue=2, ..., Sun=7
    // Sun=0 으로 재매핑 → 일요일부터의 days back
    final daysSinceSunday = kst.weekday % 7;
    final ksDateOnly = DateTime.utc(kst.year, kst.month, kst.day);
    final sundayKstMidnight = ksDateOnly.subtract(
      Duration(days: daysSinceSunday),
    );
    return sundayKstMidnight.subtract(_kstOffset);
  }

  /// [now] 시점에 [lastGrantedAt] 기준으로 grant 자격이 있는지 판정.
  ///
  /// 자격 조건: [lastGrantedAt] == null OR [lastGrantedAt] < 이번 주 일요일 자정.
  /// 경계 정각 일치 시 false (이미 이번 주 발급으로 간주).
  static bool isGrantDue({
    required DateTime? lastGrantedAt,
    required DateTime now,
  }) {
    if (lastGrantedAt == null) return true;
    final sunday = previousSundayMidnightKstAsUtc(now);
    return lastGrantedAt.isBefore(sunday);
  }

  /// 주간 자동 발급 — 자격 있는 경우만 +[amount].
  ///
  /// 스펙 §6.5 / §14.1 — Sunday 00:00 KST 자동 +2, max 4.
  Future<StreakFreeze> weeklyGrantIfDue({
    required String studentId,
    required DateTime now,
    int amount = 2,
  }) async {
    final current = await repository.getOrCreate(studentId);
    if (!isGrantDue(lastGrantedAt: current.lastGrantedAt, now: now)) {
      return current;
    }
    return repository.grantWeekly(studentId, amount: amount, asOf: now);
  }

  /// 결석일 freeze 자동 적용 — balance/examMode 검증은 repository 위임.
  ///
  /// 스펙 §6.5 / §14.2. 호출 결정 (어제 결석 판정) 은
  /// `practice_streak_provider` (Job 5) 책임.
  Future<StreakFreeze> applyOnAbsence({
    required String studentId,
    required DateTime missedDate,
  }) async {
    return repository.apply(studentId, missedDate);
  }

  /// 시험 모드 발급/해제. 학부모/선생님 발급 (스펙 §14.3).
  Future<StreakFreeze> setExamMode({
    required String studentId,
    required DateTime? until,
  }) async {
    return repository.setExamMode(studentId, until);
  }
}
