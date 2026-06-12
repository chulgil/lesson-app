import '../entities/streak_freeze.dart';

/// 스트릭 동결 저장소 인터페이스.
///
/// 스펙 §6.5 / 플랜 Job 3 Task 3.1. 구현체: [MockStreakFreezeRepository] (테스트),
/// [HiveStreakFreezeRepository] (런타임 — `Box<String>` + JSON 직렬화).
abstract class StreakFreezeRepository {
  /// [studentId] 의 freeze record 조회. 없으면 [StreakFreeze.empty] 생성 후 영속.
  Future<StreakFreeze> getOrCreate(String studentId);

  /// 주간 자동 발급 — balance + [amount], clamp [StreakFreeze.maxBalance].
  ///
  /// 호출 빈도/타이밍 (Sunday 00:00 KST 정렬) 결정은 서비스 레이어 책임 (Job 4
  /// `StreakFreezeService.weeklyGrantIfDue`).
  Future<StreakFreeze> grantWeekly(String studentId, {int amount = 2});

  /// 결석일 [date] 에 freeze 1개 차감 + usedAt 추가.
  ///
  /// balance == 0 또는 examMode 활성 시 변경 없이 현재 record 반환 (no-op).
  /// examMode/balance 사전 검증은 서비스 레이어 책임 (Job 4
  /// `StreakFreezeService.applyOnAbsence`).
  Future<StreakFreeze> apply(String studentId, DateTime date);

  /// 시험 모드 설정 — `examModeUntil` = [until] (학부모/선생님 발급).
  ///
  /// [until] = null 이면 즉시 해제.
  Future<StreakFreeze> setExamMode(String studentId, DateTime? until);
}
