/// 학원 일괄 휴강 (G15).
///
/// 학원장이 휴원일을 지정하면 영향 레슨을 자동 산출. 1시간 의견 윈도우 동안
/// 강사가 의견 제출 가능. 적용 후 강사가 레슨별 보강 일정을 입력한다.
class BulkClosure {
  final String id;
  final String academyId;
  final DateTime closureDate;
  final String reason;
  final ClosureStatus status;

  /// 의견 윈도우 만료 시각 (적용 전).
  final DateTime? opinionWindowEndsAt;

  /// 적용 시각 (status == applied 일 때).
  final DateTime? appliedAt;

  /// 영향 받는 레슨 리스트.
  final List<AffectedLesson> affectedLessons;

  /// 강사가 제출한 의견 (1h window 이내).
  final String? teacherComment;

  const BulkClosure({
    required this.id,
    required this.academyId,
    required this.closureDate,
    required this.reason,
    required this.status,
    this.opinionWindowEndsAt,
    this.appliedAt,
    this.affectedLessons = const [],
    this.teacherComment,
  });

  /// 의견 윈도우가 아직 열려 있는가.
  bool get isOpinionWindowOpen {
    if (opinionWindowEndsAt == null) return false;
    return DateTime.now().isBefore(opinionWindowEndsAt!);
  }

  /// 보강 입력이 끝난 레슨 수.
  int get makeupCompletedCount =>
      affectedLessons.where((l) => l.makeupAt != null).length;

  BulkClosure copyWith({
    String? id,
    String? academyId,
    DateTime? closureDate,
    String? reason,
    ClosureStatus? status,
    DateTime? opinionWindowEndsAt,
    DateTime? appliedAt,
    List<AffectedLesson>? affectedLessons,
    String? teacherComment,
  }) {
    return BulkClosure(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      closureDate: closureDate ?? this.closureDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      opinionWindowEndsAt: opinionWindowEndsAt ?? this.opinionWindowEndsAt,
      appliedAt: appliedAt ?? this.appliedAt,
      affectedLessons: affectedLessons ?? this.affectedLessons,
      teacherComment: teacherComment ?? this.teacherComment,
    );
  }
}

enum ClosureStatus {
  /// 의견 윈도우 진행 중 (강사 의견 가능).
  proposed,

  /// 적용됨 — 강사가 보강 일정 입력 대기.
  applied,

  /// 강사가 모든 보강 일정 입력 완료.
  makeupCompleted,

  /// 취소됨.
  cancelled,
}

/// 휴강 영향을 받는 레슨 (강사 시점).
class AffectedLesson {
  final String lessonId;
  final String studentId;
  final String studentName;
  final DateTime originalStartAt;
  final DateTime originalEndAt;

  /// 강사가 입력한 보강 시각. null = 아직 미입력.
  final DateTime? makeupAt;

  const AffectedLesson({
    required this.lessonId,
    required this.studentId,
    required this.studentName,
    required this.originalStartAt,
    required this.originalEndAt,
    this.makeupAt,
  });

  AffectedLesson copyWith({
    String? lessonId,
    String? studentId,
    String? studentName,
    DateTime? originalStartAt,
    DateTime? originalEndAt,
    DateTime? makeupAt,
  }) {
    return AffectedLesson(
      lessonId: lessonId ?? this.lessonId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      originalStartAt: originalStartAt ?? this.originalStartAt,
      originalEndAt: originalEndAt ?? this.originalEndAt,
      makeupAt: makeupAt ?? this.makeupAt,
    );
  }
}
