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

  /// Logout (revoke tokens on server).
  Future<void> logout();
}
