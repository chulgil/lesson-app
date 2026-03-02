import '../../features/auth/domain/entities/user_role.dart';

/// Authentication state for the app.
sealed class AuthState {
  const AuthState();
}

/// Initial loading state (checking stored tokens).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated but has no role assigned yet (new OAuth signup).
class AuthNeedsRole extends AuthState {
  final String userId;
  final String name;
  final String email;
  final String? profileImageUrl;

  const AuthNeedsRole({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });
}

/// User is authenticated.
class AuthAuthenticated extends AuthState {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;

  const AuthAuthenticated({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });
}
