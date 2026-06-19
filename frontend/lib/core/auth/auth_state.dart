import '../../features/auth/domain/entities/user_role.dart';

/// Authentication state for the app.
sealed class AuthState {
  const AuthState();
}

/// Initial loading state (checking stored tokens).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Reason why the user is unauthenticated.
///
/// Used to surface meaningful feedback in LoginScreen (#866).
/// [none] = normal (no token / manual logout).
/// [networkError] = auto-login failed due to network/timeout.
/// [serverError] = auto-login failed due to 5xx server error.
enum AuthUnauthenticatedReason { none, networkError, serverError }

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  final AuthUnauthenticatedReason reason;

  const AuthUnauthenticated({this.reason = AuthUnauthenticatedReason.none});
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

/// User has a role but hasn't completed onboarding (profile setup).
class AuthNeedsOnboarding extends AuthState {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;

  const AuthNeedsOnboarding({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });
}

/// User is fully authenticated and onboarding is complete.
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
