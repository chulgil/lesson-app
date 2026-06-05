import 'academy_enums.dart';

/// AcademyMember entity — 강사/학원장 소속 정보.
///
/// Spec: docs/specs/web/academy/academy_master.md §3.2,
/// teacher_offboarding_spec §8.1 (access_revoked_at),
/// temporary_delegation_spec §8 (delegate_role).
class AcademyMember {
  final String id;
  final String academyId;
  final String userId;
  final AcademyMemberRole role;
  final bool publicPageConsent;
  final DateTime? onboardingUntil;
  final DateTime createdAt;

  /// 퇴직 시각. null = 활성, datetime = 권한 차단 (강사 퇴직).
  /// teacher_offboarding_spec §8.1.
  final DateTime? accessRevokedAt;

  /// 매니저 영구 위임 패턴. "none" / "trusted_substitute".
  /// trusted_substitute 인 경우 학원장 위임 시 비밀번호 1회만.
  /// temporary_delegation_spec §8.
  final String delegateRole;

  /// delegate_role 부여 시각. null = 미부여.
  final DateTime? delegateRoleGrantedAt;

  const AcademyMember({
    required this.id,
    required this.academyId,
    required this.userId,
    required this.role,
    this.publicPageConsent = false,
    this.onboardingUntil,
    required this.createdAt,
    this.accessRevokedAt,
    this.delegateRole = 'none',
    this.delegateRoleGrantedAt,
  });

  AcademyMember copyWith({
    String? id,
    String? academyId,
    String? userId,
    AcademyMemberRole? role,
    bool? publicPageConsent,
    DateTime? onboardingUntil,
    DateTime? createdAt,
    DateTime? accessRevokedAt,
    String? delegateRole,
    DateTime? delegateRoleGrantedAt,
  }) {
    return AcademyMember(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      publicPageConsent: publicPageConsent ?? this.publicPageConsent,
      onboardingUntil: onboardingUntil ?? this.onboardingUntil,
      createdAt: createdAt ?? this.createdAt,
      accessRevokedAt: accessRevokedAt ?? this.accessRevokedAt,
      delegateRole: delegateRole ?? this.delegateRole,
      delegateRoleGrantedAt:
          delegateRoleGrantedAt ?? this.delegateRoleGrantedAt,
    );
  }

  bool get isOnboarding =>
      onboardingUntil != null && DateTime.now().isBefore(onboardingUntil!);

  /// 강사 퇴직 여부. teacher_offboarding_spec §8.1.
  bool get isAccessRevoked => accessRevokedAt != null;

  /// 매니저 영구 위임 강사 여부. temporary_delegation_spec §8.
  bool get isTrustedSubstitute => delegateRole == 'trusted_substitute';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademyMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          academyId == other.academyId &&
          userId == other.userId &&
          role == other.role &&
          publicPageConsent == other.publicPageConsent &&
          onboardingUntil == other.onboardingUntil &&
          createdAt == other.createdAt &&
          accessRevokedAt == other.accessRevokedAt &&
          delegateRole == other.delegateRole &&
          delegateRoleGrantedAt == other.delegateRoleGrantedAt;

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    userId,
    role,
    publicPageConsent,
    onboardingUntil,
    createdAt,
    accessRevokedAt,
    delegateRole,
    delegateRoleGrantedAt,
  );
}
