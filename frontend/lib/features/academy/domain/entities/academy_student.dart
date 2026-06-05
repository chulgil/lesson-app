import 'academy_enums.dart';

/// AcademyStudent entity — 학원 학생 정보.
///
/// Spec: docs/specs/web/academy/academy_master.md §3.2,
/// payment_matching_spec §3.5 (deposit_code).
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

  /// 라이프사이클 status 마지막 변경 시각.
  /// active → paused 같은 전이 audit 용.
  final DateTime? statusChangedAt;

  /// 학원장이 학생 등록 시 입력하는 사전 정보 (학년·연락처 등).
  /// 학생 본인 가입 전 임시 메모.
  final String? intakeNotes;

  /// 입금자 매칭 보조 메모 코드 (payment_matching_spec §3.5).
  /// 무통장입금 fuzzy 매칭이 실패할 때 학원장 수동 매핑 보조.
  final String? depositCode;

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
    this.statusChangedAt,
    this.intakeNotes,
    this.depositCode,
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
    DateTime? statusChangedAt,
    String? intakeNotes,
    String? depositCode,
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
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      intakeNotes: intakeNotes ?? this.intakeNotes,
      depositCode: depositCode ?? this.depositCode,
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
          matchedAt == other.matchedAt &&
          statusChangedAt == other.statusChangedAt &&
          intakeNotes == other.intakeNotes &&
          depositCode == other.depositCode;

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    studentUserId,
    parentUserId,
    teacherMemberId,
    name,
    instrument,
    status,
    registeredAt,
    matchedAt,
    statusChangedAt,
    intakeNotes,
    depositCode,
  );
}
