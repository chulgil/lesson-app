/// 선생님 공지 (휴강/일반) — v3 공지 시스템.
///
/// Spec: docs/specs/student/bulk_teacher_actions_spec.md §4
class TeacherAnnouncement {
  final String id;
  final String teacherId;
  final AnnouncementType type;
  final List<DateTime> dates;
  final String message;
  final DateTime createdAt;

  /// 휴강 타입일 때, 해당 날짜에 수업이 있는 학생 정보.
  final List<AffectedLesson> affectedLessons;

  const TeacherAnnouncement({
    required this.id,
    required this.teacherId,
    required this.type,
    this.dates = const [],
    required this.message,
    required this.createdAt,
    this.affectedLessons = const [],
  });
}

enum AnnouncementType {
  dayOff,
  general,
}

/// 휴강일에 영향받는 레슨 정보 (공지 결과에서 사용).
class AffectedLesson {
  final String studentId;
  final String studentName;
  final String instrument;
  final String startTime;
  final int? sessionNumber;
  final String? subscriptionId;

  const AffectedLesson({
    required this.studentId,
    required this.studentName,
    required this.instrument,
    required this.startTime,
    this.sessionNumber,
    this.subscriptionId,
  });
}
