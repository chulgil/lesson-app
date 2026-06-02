import '../entities/auth_user.dart';

/// Repository interface for authentication operations.
abstract class AuthRepository {
  /// Exchange OAuth authorization code for tokens.
  Future<TokenPair> loginWithOAuth({
    required String provider,
    required String idToken,
  });

  /// Refresh access token using refresh token.
  Future<TokenPair> refreshToken(String refreshToken);

  /// Get current authenticated user info.
  Future<AuthUser> getMe();

  /// Dev-only login (bypasses OAuth for local development).
  Future<({TokenPair tokens, AuthUser user})> devLogin({
    required String email,
    required String role,
    String? name,
  });

  /// Update current user's role (for new OAuth signups).
  Future<AuthUser> updateRole(String role);

  /// #430 G1 B2 — 약관 동의 영속 저장.
  ///
  /// 호출 자체가 필수 묶음(서비스 이용약관 + 개인정보 처리방침) 동의를
  /// 의미한다. [marketingConsent] 는 정보통신망법 제50조에 따라 별도로
  /// 기록된다.
  Future<AuthUser> acceptTerms({required bool marketingConsent});

  /// Logout (revoke tokens on server).
  Future<void> logout();
}
