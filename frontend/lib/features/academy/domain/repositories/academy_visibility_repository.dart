/// AcademyVisibilityRepository — 강사 공개 페이지 노출 동의 관리
abstract class AcademyVisibilityRepository {
  /// Get teacher's public page consent for a specific academy
  Future<bool> getTeacherAcademyConsent(String academyId, String teacherId);

  /// Update teacher's public page consent for an academy
  /// Returns the updated consent value
  Future<bool> updateTeacherAcademyConsent(
    String academyId,
    String teacherId,
    bool consent,
  );

  /// List all academies where teacher is a member
  /// (Used to show all academies they can toggle visibility for)
  Future<List<TeacherAcademyMembership>> listTeacherAcademies(String teacherId);
}

/// Data class representing a teacher's membership in an academy
class TeacherAcademyMembership {
  final String academyId;
  final String academyName;
  final bool publicPageConsent;

  /// This teacher's per-academy member id (AcademyMember.id, e.g. "member_2").
  /// Both mock and remote implementations already resolve this internally to
  /// look up consent — exposed here so callers can address the academy
  /// activity timeline route (`:actorMemberId`) without a second lookup.
  final String actorMemberId;

  const TeacherAcademyMembership({
    required this.academyId,
    required this.academyName,
    required this.publicPageConsent,
    required this.actorMemberId,
  });

  TeacherAcademyMembership copyWith({
    String? academyId,
    String? academyName,
    bool? publicPageConsent,
    String? actorMemberId,
  }) {
    return TeacherAcademyMembership(
      academyId: academyId ?? this.academyId,
      academyName: academyName ?? this.academyName,
      publicPageConsent: publicPageConsent ?? this.publicPageConsent,
      actorMemberId: actorMemberId ?? this.actorMemberId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherAcademyMembership &&
          runtimeType == other.runtimeType &&
          academyId == other.academyId &&
          academyName == other.academyName &&
          publicPageConsent == other.publicPageConsent &&
          actorMemberId == other.actorMemberId;

  @override
  int get hashCode =>
      academyId.hashCode ^
      academyName.hashCode ^
      publicPageConsent.hashCode ^
      actorMemberId.hashCode;
}
