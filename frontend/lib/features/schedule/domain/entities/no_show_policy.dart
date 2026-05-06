// No-Show Policy entity
// Spec: docs/specs/lesson/lesson_schedule.md - 노쇼 정책 시스템

/// 노쇼 정책 - 선생님이 설정
enum NoShowPolicy {
  deductCredit, // 기본값: 회차 차감

  halfCredit, // 0.5회 차감

  noDeduction, // 차감 없음 (관대한 정책)

  reschedule; // 보강으로 전환

  /// 차감 비율 (회차권 기준)
  double get deductionRate {
    switch (this) {
      case NoShowPolicy.deductCredit:
        return 1.0;
      case NoShowPolicy.halfCredit:
        return 0.5;
      case NoShowPolicy.noDeduction:
        return 0.0;
      case NoShowPolicy.reschedule:
        return 0.0; // 보강으로 전환되므로 차감 없음
    }
  }

  /// 보강 생성 여부
  bool get createsMakeup => this == NoShowPolicy.reschedule;
}

/// 노쇼 기록
class NoShowRecord {
  final String id;

  final String lessonId;

  final String studentId;

  final String teacherId;

  final DateTime lessonDate;

  final NoShowPolicy appliedPolicy;

  /// 차감된 회차 (0, 0.5, 1)
  final double deductedCredits;

  /// 생성된 보강 ID (reschedule 정책인 경우)
  final String? makeupLessonId;

  final DateTime createdAt;

  /// 노쇼 처리 담당자 (자동 또는 선생님 ID)
  final String processedBy;

  /// 추가 메모
  final String? note;

  NoShowRecord({
    required this.id,
    required this.lessonId,
    required this.studentId,
    required this.teacherId,
    required this.lessonDate,
    required this.appliedPolicy,
    required this.deductedCredits,
    this.makeupLessonId,
    required this.createdAt,
    required this.processedBy,
    this.note,
  });

  NoShowRecord copyWith({
    String? id,
    String? lessonId,
    String? studentId,
    String? teacherId,
    DateTime? lessonDate,
    NoShowPolicy? appliedPolicy,
    double? deductedCredits,
    String? makeupLessonId,
    DateTime? createdAt,
    String? processedBy,
    String? note,
  }) {
    return NoShowRecord(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      lessonDate: lessonDate ?? this.lessonDate,
      appliedPolicy: appliedPolicy ?? this.appliedPolicy,
      deductedCredits: deductedCredits ?? this.deductedCredits,
      makeupLessonId: makeupLessonId ?? this.makeupLessonId,
      createdAt: createdAt ?? this.createdAt,
      processedBy: processedBy ?? this.processedBy,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoShowRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
