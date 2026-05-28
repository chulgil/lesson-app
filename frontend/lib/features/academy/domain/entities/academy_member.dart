import 'academy_enums.dart';

/// AcademyMember entity — 강사/학원장 소속 정보
class AcademyMember {
  final String id;
  final String academyId;
  final String userId;
  final AcademyMemberRole role;
  final bool publicPageConsent;
  final DateTime? onboardingUntil;
  final DateTime createdAt;

  const AcademyMember({
    required this.id,
    required this.academyId,
    required this.userId,
    required this.role,
    this.publicPageConsent = false,
    this.onboardingUntil,
    required this.createdAt,
  });

  AcademyMember copyWith({
    String? id,
    String? academyId,
    String? userId,
    AcademyMemberRole? role,
    bool? publicPageConsent,
    DateTime? onboardingUntil,
    DateTime? createdAt,
  }) {
    return AcademyMember(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      publicPageConsent: publicPageConsent ?? this.publicPageConsent,
      onboardingUntil: onboardingUntil ?? this.onboardingUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOnboarding =>
      onboardingUntil != null && DateTime.now().isBefore(onboardingUntil!);

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
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      academyId.hashCode ^
      userId.hashCode ^
      role.hashCode ^
      publicPageConsent.hashCode ^
      onboardingUntil.hashCode ^
      createdAt.hashCode;
}
