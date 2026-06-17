/// Teacher vacation period entity (#431).
///
/// Spec: docs/specs/schedule/teacher_vacation_mode.md §3.2.
/// Pure value type — no display strings / no presentation imports.
library;

/// 3-option disposition for impacted lessons during a vacation period.
///
/// Glossary: 휴가 / Vacation Mode.
enum VacationDisposition {
  /// (a) 보강 크레딧 자동 적립.
  makeupCredit,

  /// (b) 무료 처리 — 수강권 차감 없이 취소.
  freeCancel,

  /// (c) 다음 회차로 이월 — 수강권 만료일 자동 연장 (autoExtendedDays 누적).
  rollForward,
}

/// Multi-day teacher absence with bulk lesson disposition.
class VacationPeriod {
  final String id;
  final String teacherId;

  /// Inclusive start date.
  final DateTime startDate;

  /// Inclusive end date.
  final DateTime endDate;

  /// Optional reason (예: "여름방학", "시험기간").
  final String? reason;

  /// Default disposition applied to all impacted lessons.
  /// Per-student overrides are a future feature (spec §4.2).
  final VacationDisposition defaultDisposition;

  /// Non-null when the period was rolled back within the 24h Recovery window.
  final DateTime? cancelledAt;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const VacationPeriod({
    required this.id,
    required this.teacherId,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.defaultDisposition = VacationDisposition.rollForward,
    this.cancelledAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Length of the vacation in days (inclusive on both ends).
  int get vacationDays {
    final diff = endDate.difference(startDate).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  /// Whether the vacation is in effect on [reference] (date-only).
  ///
  /// Active means: not cancelled AND the inclusive start date has already begun
  /// AND the inclusive end date has not passed. A vacation that starts in the
  /// future is "scheduled", not active (no banner / no Recovery window yet).
  /// Comparison is date-only so a vacation ending today stays active until the
  /// next calendar day (avoids a midnight off-by-one).
  bool isActiveOn(DateTime reference) {
    if (cancelledAt != null) return false;
    final today = DateTime(reference.year, reference.month, reference.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !start.isAfter(today) && !end.isBefore(today);
  }

  VacationPeriod copyWith({
    String? id,
    String? teacherId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    VacationDisposition? defaultDisposition,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VacationPeriod(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      defaultDisposition: defaultDisposition ?? this.defaultDisposition,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Per-student impact summary (spec §4.1 step 2).
class VacationImpactedStudent {
  final String studentId;
  final String? studentName;
  final int lessonCount;

  const VacationImpactedStudent({
    required this.studentId,
    this.studentName,
    required this.lessonCount,
  });
}

/// Impact preview returned by GET /api/teacher/vacation/impact.
class VacationImpactPreview {
  final DateTime startDate;
  final DateTime endDate;
  final int impactedLessonCount;
  final int impactedStudentCount;
  final List<VacationImpactedStudent> impactedStudents;

  const VacationImpactPreview({
    required this.startDate,
    required this.endDate,
    required this.impactedLessonCount,
    required this.impactedStudentCount,
    this.impactedStudents = const [],
  });
}
