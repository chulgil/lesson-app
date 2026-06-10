import '../../domain/exceptions/academy_invite_exceptions.dart';
import '../../domain/repositories/academy_invite_repository.dart';

/// Mock implementation of AcademyInviteRepository
class MockAcademyInviteRepository implements AcademyInviteRepository {
  final Map<String, AcademyInvitePreview> _previews = {};
  final Set<String> _expiredTokens = {};
  final Set<String> _rejectedTokens = {};

  @override
  Future<AcademyInvitePreview> getInvitePreview(String token) async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (_expiredTokens.contains(token)) {
      throw const AcademyInviteExpiredException();
    }

    if (_rejectedTokens.contains(token)) {
      throw const AcademyInviteAlreadyUsedException();
    }

    final preview = _previews[token];
    if (preview == null) {
      throw const AcademyInviteNotFoundException();
    }

    return preview;
  }

  @override
  Future<void> acceptInvite(
    String token, {
    required bool publicPageConsent,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_expiredTokens.contains(token)) {
      throw const AcademyInviteExpiredException();
    }

    if (_rejectedTokens.contains(token)) {
      throw const AcademyInviteAlreadyUsedException();
    }

    final preview = _previews[token];
    if (preview == null) {
      throw const AcademyInviteNotFoundException();
    }

    // Simulate acceptance by removing token
    _previews.remove(token);
  }

  @override
  Future<void> rejectInvite(String token, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (_expiredTokens.contains(token)) {
      throw const AcademyInviteExpiredException();
    }

    final preview = _previews[token];
    if (preview == null) {
      throw const AcademyInviteNotFoundException();
    }

    // Mark as rejected
    _rejectedTokens.add(token);
    _previews.remove(token);
  }

  /// For testing: Add an invite preview
  void addInvitePreview(String token, AcademyInvitePreview preview) {
    _previews[token] = preview;
  }

  /// For testing: Mark token as expired
  void expireToken(String token) {
    _expiredTokens.add(token);
    _previews.remove(token);
  }

  /// For testing: Check if token was rejected
  bool wasTokenRejected(String token) {
    return _rejectedTokens.contains(token);
  }

  /// For testing: Reset all state
  void reset() {
    _previews.clear();
    _expiredTokens.clear();
    _rejectedTokens.clear();
  }
}
