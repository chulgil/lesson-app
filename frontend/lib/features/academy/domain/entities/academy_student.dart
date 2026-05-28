import 'academy_enums.dart';

/// AcademyStudent entity — 학원 학생 정보
class AcademyStudent {
  final String id;
  final String academyId;
  final String? studentUserId;
  final String? parentUserId;
  final String? teacherMemberId;
  final String name;
  final String? instrument;
  final AcademyStudentStatus status;
  final DateTime registeredAt;
  final DateTime? matchedAt;

  const AcademyStudent({
    required this.id,
    required this.academyId,
    this.studentUserId,
    this.parentUserId,
    this.teacherMemberId,
    required this.name,
    this.instrument,
    required this.status,
    required this.registeredAt,
    this.matchedAt,
  });

  AcademyStudent copyWith({
    String? id,
    String? academyId,
    String? studentUserId,
    String? parentUserId,
    String? teacherMemberId,
    String? name,
    String? instrument,
    AcademyStudentStatus? status,
    DateTime? registeredAt,
    DateTime? matchedAt,
  }) {
    return AcademyStudent(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      studentUserId: studentUserId ?? this.studentUserId,
      parentUserId: parentUserId ?? this.parentUserId,
      teacherMemberId: teacherMemberId ?? this.teacherMemberId,
      name: name ?? this.name,
      instrument: instrument ?? this.instrument,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      matchedAt: matchedAt ?? this.matchedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademyStudent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          academyId == other.academyId &&
          studentUserId == other.studentUserId &&
          parentUserId == other.parentUserId &&
          teacherMemberId == other.teacherMemberId &&
          name == other.name &&
          instrument == other.instrument &&
          status == other.status &&
          registeredAt == other.registeredAt &&
          matchedAt == other.matchedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      academyId.hashCode ^
      studentUserId.hashCode ^
      parentUserId.hashCode ^
      teacherMemberId.hashCode ^
      name.hashCode ^
      instrument.hashCode ^
      status.hashCode ^
      registeredAt.hashCode ^
      matchedAt.hashCode;
}
