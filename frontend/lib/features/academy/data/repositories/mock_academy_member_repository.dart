import '../../domain/entities/academy_member.dart';
import '../../domain/repositories/academy_member_repository.dart';

/// Mock implementation of AcademyMemberRepository
class MockAcademyMemberRepository implements AcademyMemberRepository {
  final Map<String, AcademyMember> _members = {};
  final Map<String, String> _tokenToMemberId = {};

  @override
  Future<AcademyMember> acceptInvite(
    String token, {
    required bool publicPageConsent,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final memberId = _tokenToMemberId[token];
    if (memberId == null) {
      throw Exception('Invalid or expired invite token');
    }

    final member = _members[memberId];
    if (member == null) {
      throw Exception('Member not found');
    }

    final updatedMember = member.copyWith(publicPageConsent: publicPageConsent);

    _members[memberId] = updatedMember;
    _tokenToMemberId.remove(token);

    return updatedMember;
  }

  @override
  Future<void> rejectInvite(String token) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    final memberId = _tokenToMemberId[token];
    if (memberId == null) {
      throw Exception('Invalid or expired invite token');
    }

    _members.remove(memberId);
    _tokenToMemberId.remove(token);
  }

  @override
  Future<void> updateVisibility(
    String memberId, {
    required bool publicPageConsent,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    final member = _members[memberId];
    if (member == null) {
      throw Exception('Member not found');
    }

    final updatedMember = member.copyWith(publicPageConsent: publicPageConsent);

    _members[memberId] = updatedMember;
  }

  /// For testing: Add a pending invite
  void addPendingInvite(String memberId, String token, AcademyMember member) {
    _members[memberId] = member;
    _tokenToMemberId[token] = memberId;
  }

  /// For testing: Get a member
  AcademyMember? getMember(String memberId) {
    return _members[memberId];
  }
}
