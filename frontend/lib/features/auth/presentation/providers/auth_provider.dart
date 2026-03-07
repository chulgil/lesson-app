import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../data/repositories/remote_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

/// Auth repository provider.
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  final apiClient = ref.read(apiClientProvider);
  return RemoteAuthRepository(apiClient);
}

/// Auth state notifier that manages authentication lifecycle.
///
/// On app start: checks stored tokens → tries auto-login.
/// USE_MOCK=true: stays unauthenticated (mock mode bypasses auth).
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late final TokenStorage _tokenStorage;
  late final AuthRepository _authRepository;

  /// Whether the user has agreed to terms in this session.
  bool _termsAgreed = false;
  bool get termsAgreed => _termsAgreed;

  /// Mark terms as accepted (in-memory, valid for this session).
  void acceptTerms() {
    _termsAgreed = true;
  }

  @override
  AuthState build() {
    _tokenStorage = ref.read(tokenStorageProvider);
    _authRepository = ref.read(authRepositoryProvider);
    _termsAgreed = false;

    // In mock mode, skip authentication entirely
    if (EnvironmentConfig.useMockData) {
      return const AuthUnauthenticated();
    }

    // Try auto-login with stored tokens
    _tryAutoLogin();
    return const AuthLoading();
  }

  /// Attempt to restore session from stored tokens.
  ///
  /// Only clears tokens on [UnauthorizedException] (401 after refresh failed).
  /// For network/server errors, tokens are preserved for the next attempt.
  Future<void> _tryAutoLogin() async {
    try {
      final hasTokens = await _tokenStorage.hasTokens();
      if (!hasTokens) {
        debugPrint('[Auth] No stored tokens, skipping auto-login');
        state = const AuthUnauthenticated();
        return;
      }

      debugPrint('[Auth] Stored tokens found, attempting auto-login...');
      final user = await _authRepository.getMe();
      debugPrint('[Auth] Auto-login succeeded: ${user.email}');
      state = _stateFromUser(user);
    } on UnauthorizedException {
      // Token is invalid/expired and refresh also failed — must re-login
      debugPrint('[Auth] Token invalid (401), clearing tokens');
      await _tokenStorage.clearTokens();
      state = const AuthUnauthenticated();
    } on NetworkException catch (e) {
      // Network error — preserve tokens for next auto-login attempt
      debugPrint('[Auth] Auto-login failed (network): ${e.message}');
      state = const AuthUnauthenticated();
    } on ApiException catch (e) {
      // Server error — preserve tokens for next auto-login attempt
      debugPrint(
        '[Auth] Auto-login failed (API ${e.statusCode}): ${e.message}',
      );
      state = const AuthUnauthenticated();
    } catch (e) {
      // Unexpected error — preserve tokens
      debugPrint('[Auth] Auto-login failed (unexpected): $e');
      state = const AuthUnauthenticated();
    }
  }

  /// Build the appropriate auth state based on whether user has a role.
  AuthState _stateFromUser(AuthUser user) {
    if (user.role == null) {
      return AuthNeedsRole(
        userId: user.id,
        name: user.name,
        email: user.email,
        profileImageUrl: user.profileImageUrl,
      );
    }
    return AuthAuthenticated(
      userId: user.id,
      name: user.name,
      email: user.email,
      role: user.role!,
      profileImageUrl: user.profileImageUrl,
    );
  }

  /// Login with OAuth provider (google, kakao, apple).
  Future<void> loginWithOAuth({
    required String provider,
    required String idToken,
  }) async {
    state = const AuthLoading();

    try {
      final tokenPair = await _authRepository.loginWithOAuth(
        provider: provider,
        idToken: idToken,
      );

      await _tokenStorage.saveTokens(
        accessToken: tokenPair.accessToken,
        refreshToken: tokenPair.refreshToken,
      );

      final user = await _authRepository.getMe();
      state = _stateFromUser(user);
    } on ApiException {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// Set role for a newly registered OAuth user.
  Future<void> setRole(UserRole role) async {
    final current = state;
    if (current is! AuthNeedsRole) return;

    state = const AuthLoading();
    try {
      final user = await _authRepository.updateRole(role.name);
      state = _stateFromUser(user);
    } on ApiException {
      state = current; // Restore previous state
      rethrow;
    }
  }

  /// Dev-only login (bypasses OAuth for local development).
  Future<void> devLogin({
    required String email,
    required String role,
    String? name,
  }) async {
    state = const AuthLoading();

    try {
      final result = await _authRepository.devLogin(
        email: email,
        role: role,
        name: name,
      );

      await _tokenStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );

      final user = result.user;
      state = _stateFromUser(user);
    } on ApiException {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// Logout and clear tokens.
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      // Best-effort server logout
    }
    await _tokenStorage.clearTokens();
    state = const AuthUnauthenticated();
  }

  /// Get current user role (defaults to teacher for mock mode).
  UserRole get currentRole {
    final s = state;
    if (s is AuthAuthenticated) return s.role;
    return UserRole.teacher;
  }
}
