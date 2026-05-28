import '../entities/academy_member.dart';

/// AcademyMemberRepository — 강사/학원장 관리
abstract class AcademyMemberRepository {
  /// Accept academy invitation with consent
  Future<AcademyMember> acceptInvite(
    String token, {
    required bool publicPageConsent,
  });

  /// Reject academy invitation
  Future<void> rejectInvite(String token);

  /// Update member's public page visibility consent
  Future<void> updateVisibility(
    String memberId, {
    required bool publicPageConsent,
  });
}
