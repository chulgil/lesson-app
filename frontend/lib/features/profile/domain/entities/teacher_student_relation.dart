// Teacher-Student relation domain entity
// Moved from lib/models/teacher_student_relation.dart for Clean Architecture

/// Teacher-Student relationship status
enum RelationStatus {
  /// No prior history - first time meeting
  none,

  /// Currently in regular lessons
  active,

  /// Had lessons before but currently inactive
  inactive,
}

/// Available lesson types based on relationship
/// TeacherStudentRelation에서 관계 기반 레슨 타입 필터링에 예약됨.
/// 첫 체험→정기→1회 추가 플로우 UI 구현 시 활용.
// ignore: unused-enum
enum RelationLessonType {
  /// Trial lesson for first meeting
  trial,

  /// Regular recurring lessons
  regular,

  /// One-time additional lesson
  oneTime,
}

/// Teacher-Student relationship model
class TeacherStudentRelation {
  final String teacherId;
  final String studentId;
  final RelationStatus status;
  final DateTime? lastLessonDate;
  final int totalLessonCount;

  const TeacherStudentRelation({
    required this.teacherId,
    required this.studentId,
    required this.status,
    this.lastLessonDate,
    this.totalLessonCount = 0,
  });

  /// Get available lesson types based on relationship status
  List<RelationLessonType> get availableLessonTypes {
    switch (status) {
      case RelationStatus.none:
        return [RelationLessonType.trial];
      case RelationStatus.active:
        return [RelationLessonType.oneTime];
      case RelationStatus.inactive:
        return [RelationLessonType.regular, RelationLessonType.oneTime];
    }
  }

  /// Check if trial lesson is available
  bool get canRequestTrial => status == RelationStatus.none;

  /// Check if regular lesson is available
  bool get canRequestRegular => status == RelationStatus.inactive;

  /// Check if one-time lesson is available
  bool get canRequestOneTime =>
      status == RelationStatus.active || status == RelationStatus.inactive;

  TeacherStudentRelation copyWith({
    String? teacherId,
    String? studentId,
    RelationStatus? status,
    DateTime? lastLessonDate,
    int? totalLessonCount,
  }) {
    return TeacherStudentRelation(
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      lastLessonDate: lastLessonDate ?? this.lastLessonDate,
      totalLessonCount: totalLessonCount ?? this.totalLessonCount,
    );
  }
}
