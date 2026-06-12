import 'package:json_annotation/json_annotation.dart';

part 'streak_freeze.g.dart';

/// 스트릭 동결 — 학생 결석일에 자동 적용되어 streak 유지.
///
/// 스펙 §6.5 / §14.1 — Sunday 00:00 KST 자동 +2, max 4.
/// 시험 모드 (`examModeUntil`) 활성 동안 차감 0.
///
/// [lastGrantedAt] (Job 4) — `StreakFreezeService.weeklyGrantIfDue` 가 이번 주
/// grant 여부 판정 시 사용. nullable (P2 D-day 마이그레이션 이전 학생 = null).
@JsonSerializable()
class StreakFreeze {
  static const int maxBalance = 4;

  final String studentId;
  final int balance;
  final List<DateTime> usedAt;
  final DateTime? examModeUntil;
  final DateTime? lastGrantedAt;

  StreakFreeze({
    required this.studentId,
    required int balance,
    required this.usedAt,
    required this.examModeUntil,
    this.lastGrantedAt,
  }) : balance = balance.clamp(0, maxBalance);

  factory StreakFreeze.empty(String studentId) => StreakFreeze(
    studentId: studentId,
    balance: 0,
    usedAt: const [],
    examModeUntil: null,
    lastGrantedAt: null,
  );

  /// examMode 비활성 + balance > 0 → 자동 적용 가능.
  bool canApply({required DateTime asOf}) {
    if (balance <= 0) return false;
    final exam = examModeUntil;
    if (exam != null && asOf.isBefore(exam)) return false;
    return true;
  }

  /// 결석일 1회 차감 — balance -1 + usedAt 추가.
  ///
  /// balance == 0 시 [StateError]. examMode 검증은 호출자 책임 (서비스 레이어).
  StreakFreeze apply(DateTime date) {
    if (balance <= 0) {
      throw StateError('Cannot apply: balance is 0 for $studentId');
    }
    return StreakFreeze(
      studentId: studentId,
      balance: balance - 1,
      usedAt: [...usedAt, date],
      examModeUntil: examModeUntil,
      lastGrantedAt: lastGrantedAt,
    );
  }

  /// 주간 자동 발급 — balance + amount, clamp maxBalance.
  ///
  /// [asOf] 가 주어지면 [lastGrantedAt] 도 갱신 (서비스 레이어가 KST 자정 정렬
  /// 후 호출). null 이면 [lastGrantedAt] 보존 (수동/dev 호출 호환).
  StreakFreeze grantWeekly({int amount = 2, DateTime? asOf}) => StreakFreeze(
    studentId: studentId,
    balance: balance + amount,
    usedAt: usedAt,
    examModeUntil: examModeUntil,
    lastGrantedAt: asOf ?? lastGrantedAt,
  );

  StreakFreeze copyWith({
    int? balance,
    List<DateTime>? usedAt,
    DateTime? examModeUntil,
    DateTime? lastGrantedAt,
    bool clearExamMode = false,
    bool clearLastGrantedAt = false,
  }) => StreakFreeze(
    studentId: studentId,
    balance: balance ?? this.balance,
    usedAt: usedAt ?? this.usedAt,
    examModeUntil: clearExamMode ? null : (examModeUntil ?? this.examModeUntil),
    lastGrantedAt:
        clearLastGrantedAt ? null : (lastGrantedAt ?? this.lastGrantedAt),
  );

  factory StreakFreeze.fromJson(Map<String, dynamic> json) =>
      _$StreakFreezeFromJson(json);

  Map<String, dynamic> toJson() => _$StreakFreezeToJson(this);
}
