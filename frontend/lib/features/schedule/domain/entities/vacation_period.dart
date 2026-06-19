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

// ──────────────────────────────────────────────────────────────
// Multi-segment vacation (#768 ②).
// ──────────────────────────────────────────────────────────────

/// One vacation segment in a multi-segment registration.
///
/// 보상옵션([disposition])은 구간별. 사유/학생별 예외는 폼 전체가 공유한다.
/// Pure value type — no display strings / no presentation imports.
class VacationSegment {
  final DateTime startDate;
  final DateTime endDate;
  final VacationDisposition disposition;

  const VacationSegment({
    required this.startDate,
    required this.endDate,
    this.disposition = VacationDisposition.rollForward,
  });

  /// Inclusive day count (both ends), date-only. Never negative.
  int get days {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = e.difference(s).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  VacationSegment copyWith({
    DateTime? startDate,
    DateTime? endDate,
    VacationDisposition? disposition,
  }) {
    return VacationSegment(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      disposition: disposition ?? this.disposition,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VacationSegment &&
      _sameDay(other.startDate, startDate) &&
      _sameDay(other.endDate, endDate) &&
      other.disposition == disposition;

  @override
  int get hashCode => Object.hash(
    startDate.year,
    startDate.month,
    startDate.day,
    endDate.year,
    endDate.month,
    endDate.day,
    disposition,
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// True if any two segments share a calendar day (inclusive ranges).
///
/// 겹치는 구간은 같은 레슨을 두 번 처리해 차감/연장 무결성을 깨므로 등록 전에 차단한다.
bool vacationSegmentsOverlap(List<VacationSegment> segments) {
  if (segments.length < 2) return false;
  final ordered = [...segments]
    ..sort((a, b) => _dateOnly(a.startDate).compareTo(_dateOnly(b.startDate)));
  for (var i = 1; i < ordered.length; i++) {
    final prevEnd = _dateOnly(ordered[i - 1].endDate);
    final curStart = _dateOnly(ordered[i].startDate);
    if (!curStart.isAfter(prevEnd)) return true; // curStart <= prevEnd
  }
  return false;
}
