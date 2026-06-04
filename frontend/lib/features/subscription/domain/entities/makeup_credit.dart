/// Makeup credit entity (#432 / Make-up Bank).
///
/// Spec: docs/specs/subscription/makeup_credit_spec.md §3.1.
/// Glossary: 보강 크레딧 / Makeup Credit — 별도 엔티티, 정규 수강권과 독립 관리.
///
/// Pure value type — no display strings / no presentation imports / no Hive.
library;

/// Reason a makeup credit was accrued.
///
/// Glossary §4 매핑. FE/BE 동일 명칭 (MakeupCreditReason).
enum MakeupCreditReason {
  /// (a) 선생님 휴가 (teacher_vacation_mode.md 의존).
  teacherVacation,

  /// (b) 학생 노쇼 면제 (선생님 재량).
  noShowExempt,

  /// (c) 정규 일괄변경 중 손실 회차.
  bulkChangeLoss,

  /// (d) 선생님 수동 지급 (예외 처리 안전망).
  manualGrant,

  /// (e) 일괄변경 결과 새 월에 5주차 발생 시 자동 적립 (spec §7.1).
  fifthWeekBonus,
}

/// A single makeup credit. One credit == one makeup lesson the student may book.
class MakeupCredit {
  final String id;
  final String studentId;
  final String teacherId;

  /// 적립 사유 수강권 (있으면).
  final String? sourceSubscriptionId;

  final MakeupCreditReason reason;

  final DateTime createdAt;

  /// 기본: createdAt + 30일.
  final DateTime expiresAt;

  /// 사용 시각. null 이면 미사용.
  final DateTime? usedAt;

  /// 사용된 레슨 ID.
  final String? usedLessonId;

  /// 휴가 ID / 노쇼 ID / 일괄변경 ID.
  final String? sourceEventId;

  const MakeupCredit({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.sourceSubscriptionId,
    required this.reason,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedLessonId,
    this.sourceEventId,
  });

  /// Whether the credit has been consumed by a booking.
  bool get isUsed => usedAt != null;

  /// Whether the credit is expired relative to [now]. Used credits are never
  /// considered expired (they were already consumed).
  bool isExpired(DateTime now) => !isUsed && expiresAt.isBefore(now);

  /// Whether the credit can still be spent on a new booking.
  bool isAvailable(DateTime now) => !isUsed && !isExpired(now);

  /// Days until expiry from [now] (negative when already expired).
  int daysUntilExpiry(DateTime now) {
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    return to.difference(from).inDays;
  }

  MakeupCredit copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? sourceSubscriptionId,
    MakeupCreditReason? reason,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedLessonId,
    String? sourceEventId,
  }) {
    return MakeupCredit(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      sourceSubscriptionId: sourceSubscriptionId ?? this.sourceSubscriptionId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedLessonId: usedLessonId ?? this.usedLessonId,
      sourceEventId: sourceEventId ?? this.sourceEventId,
    );
  }
}

/// Aggregate summary for a student's makeup credit balance (UI convenience).
class MakeupCreditBalance {
  /// Credits available to spend (not used, not expired).
  final List<MakeupCredit> available;

  const MakeupCreditBalance({this.available = const []});

  int get availableCount => available.length;

  bool get hasAny => available.isNotEmpty;

  /// Earliest upcoming expiry among available credits, or null when none.
  DateTime? get earliestExpiry {
    if (available.isEmpty) return null;
    return available
        .map((c) => c.expiresAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  factory MakeupCreditBalance.fromCredits(
    List<MakeupCredit> credits,
    DateTime now,
  ) {
    final available =
        credits.where((c) => c.isAvailable(now)).toList()
          ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return MakeupCreditBalance(available: available);
  }
}
