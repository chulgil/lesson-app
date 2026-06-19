import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/remote_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

/// Auth repository provider.
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  final apiClient = ref.read(apiClientProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  return RemoteAuthRepository(apiClient, tokenStorage);
}

/// Retry policy contract for [AuthNotifier.loginWithOAuth].
///
/// 일시적 장애(네트워크 끊김, 서버 5xx)는 재시도하고 클라이언트 오류는 즉시 종료한다.
/// "구글 로그인 후 잠깐의 네트워크 끊김으로 SnackBar만 뜨고 화면이 그대로 멈추는"
/// 회귀(#676 후속)를 방지한다.
bool isRetryableApiError(ApiException error) {
  final status = error.statusCode;
  if (status == null) return true;
  return status >= 500 && status < 600;
}

/// Auth state notifier that manages authentication lifecycle.
///
/// On app start: checks stored tokens → tries auto-login.
/// USE_MOCK=true: stays unauthenticated (mock mode bypasses auth).
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late final TokenStorage _tokenStorage;
  late final AuthRepository _authRepository;

  /// Whether the user has agreed to required terms in this session.
  bool _termsAgreed = false;
  bool get termsAgreed => _termsAgreed;

  /// Whether the user opted into marketing communications.
  ///
  /// 정보통신망법 제50조에 따라 마케팅 정보 수신은 별도 동의로 관리한다.
  bool _marketingConsent = false;
  bool get marketingConsent => _marketingConsent;

  /// Mark required terms as accepted with optional marketing consent.
  ///
  /// 정책: `docs/specs/user/phone_verification_policy.md §2.3` — 필수
  /// 묶음(서비스 이용약관 + 개인정보 처리방침)과 마케팅 동의는 별도로 기록.
  /// 로컬 state 를 즉시 갱신하고 백엔드에는 POST /auth/consent 로 영속
  /// 저장 (실패해도 UX 는 차단하지 않음 — 다음 진입 시 재시도 가능).
  void acceptTerms({bool marketingConsent = false}) {
    _termsAgreed = true;
    _marketingConsent = marketingConsent;
    // Fire-and-forget — 백엔드 저장 실패는 가입 흐름을 차단하지 않는다.
    // (인증 토큰 없는 상태 등에서 호출되면 조용히 실패한다.)
    unawaited(_persistConsent(marketingConsent: marketingConsent));
  }

  Future<void> _persistConsent({required bool marketingConsent}) async {
    try {
      await _authRepository.acceptTerms(marketingConsent: marketingConsent);
    } catch (e) {
      debugPrint('[Auth] consent persist failed: $e');
    }
  }

  @override
  AuthState build() {
    _tokenStorage = ref.read(tokenStorageProvider);
    _authRepository = ref.read(authRepositoryProvider);
    _termsAgreed = false;
    _marketingConsent = false;

    // In mock mode at startup, skip auto-login (no stored tokens to check).
    // Uses ref.read (not watch) so mode changes after login don't reset auth state.
    if (ref.read(mockDataModeProvider)) {
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
      // data-privacy: 개인정보(email)를 로그에 출력하지 않는다
      debugPrint('[Auth] Auto-login succeeded (role=${user.role})');
      state = _stateFromUser(user);
    } on UnauthorizedException {
      // Token is invalid/expired and refresh also failed — must re-login
      debugPrint('[Auth] Token invalid (401), clearing tokens');
      await _tokenStorage.clearTokens();
      state = const AuthUnauthenticated();
    } on NetworkException catch (e) {
      // Network error — preserve tokens for next auto-login attempt
      debugPrint('[Auth] Auto-login failed (network): ${e.message}');
      state = const AuthUnauthenticated(
        reason: AuthUnauthenticatedReason.networkError,
      );
    } on ApiException catch (e) {
      // Server error — preserve tokens for next auto-login attempt
      debugPrint(
        '[Auth] Auto-login failed (API ${e.statusCode}): ${e.message}',
      );
      final reason = (e.statusCode != null && e.statusCode! >= 500)
          ? AuthUnauthenticatedReason.serverError
          : AuthUnauthenticatedReason.none;
      state = AuthUnauthenticated(reason: reason);
    } catch (e) {
      // Unexpected error — preserve tokens
      debugPrint('[Auth] Auto-login failed (unexpected): $e');
      state = const AuthUnauthenticated();
    }
  }

  /// Build the appropriate auth state based on user's role and onboarding status.
  AuthState _stateFromUser(AuthUser user) {
    if (user.role == null) {
      return AuthNeedsRole(
        userId: user.id,
        name: user.name,
        email: user.email,
        profileImageUrl: user.profileImageUrl,
      );
    }
    if (!user.onboardingCompleted) {
      return AuthNeedsOnboarding(
        userId: user.id,
        name: user.name,
        email: user.email,
        role: user.role!,
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

  /// Mark onboarding as completed on the server.
  Future<void> completeOnboarding() async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.patch('/users/me/onboarding-complete');

    // Refresh user state
    final user = await _authRepository.getMe();
    state = _stateFromUser(user);
  }

  /// Login with OAuth provider (google, kakao, apple).
  ///
  /// 토큰 교환 단계만 일시 장애(네트워크 끊김, 서버 5xx)에 대해 최대 3회 재시도
  /// (지수 백오프 500ms → 1000ms). 클라이언트 오류(4xx)는 즉시 종료.
  /// [isRetryableApiError] 가 정책을 결정한다.
  Future<void> loginWithOAuth({
    required String provider,
    required String idToken,
  }) async {
    state = const AuthLoading();

    try {
      final tokenPair = await _exchangeOAuthTokenWithRetry(
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

  Future<TokenPair> _exchangeOAuthTokenWithRetry({
    required String provider,
    required String idToken,
  }) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _authRepository.loginWithOAuth(
          provider: provider,
          idToken: idToken,
        );
      } on ApiException catch (error) {
        if (!isRetryableApiError(error) || attempt == maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    throw StateError('unreachable');
  }

  /// Set role for a newly registered OAuth user.
  Future<void> setRole(UserRole role) async {
    final current = state;
    if (current is! AuthNeedsRole && current is! AuthNeedsOnboarding) return;

    state = const AuthLoading();
    try {
      final user = await _authRepository.updateRole(role.name);
      state = _stateFromUser(user);
    } on ApiException {
      state = current; // Restore previous state
      rethrow;
    }
  }

  /// 사용자가 RoleSelectScreen 으로 되돌아가도록 frontend state 를 reset.
  ///
  /// #430 G1 B1 — 학생 직접 가입 차단 화면에서 "부모님 계정으로 시작하기"
  /// 를 눌렀을 때 호출. 백엔드 role 갱신은 다음에 setRole 호출 시 수행되며,
  /// 본 메서드는 로컬 state 만 AuthNeedsRole 로 되돌린다.
  Future<void> clearRole() async {
    final current = state;
    if (current is AuthNeedsOnboarding) {
      state = AuthNeedsRole(
        userId: current.userId,
        name: current.name,
        email: current.email,
        profileImageUrl: current.profileImageUrl,
      );
    }
    // AuthNeedsRole 이면 이미 역할 선택 상태이므로 noop.
  }

  /// Dev-only login (bypasses OAuth for local development).
  ///
  /// In mock mode: creates a local [AuthAuthenticated] state without API call.
  /// In remote mode: calls `POST /auth/dev-login` on the backend.
  Future<void> devLogin({
    required String email,
    required String role,
    String? name,
  }) async {
    state = const AuthLoading();

    final isMock = ref.read(mockDataModeProvider);

    if (isMock) {
      // Mock mode: bypass API, create local auth state directly
      final mockRole = UserRole.values.firstWhere(
        (r) => r.name == role,
        orElse: () => UserRole.teacher,
      );
      final mockUserId = switch (mockRole) {
        UserRole.teacher => 'teacher_1',
        UserRole.student => 'student_1',
        UserRole.parent => 'parent_1',
      };
      state = AuthAuthenticated(
        userId: mockUserId,
        name: name ?? email,
        email: email,
        role: mockRole,
      );
      return;
    }

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
    // Clear per-user Hive data so the next login does not inherit previous
    // user's notification settings (privacy: data-privacy.md §Level-2).
    try {
      if (Hive.isBoxOpen('notification_settings')) {
        await Hive.box('notification_settings').clear();
      }
    } catch (_) {
      // Best-effort: Hive may not be open during unit tests.
    }
    state = const AuthUnauthenticated();
  }

  /// Get current user role (defaults to teacher for mock mode).
  UserRole get currentRole {
    final s = state;
    if (s is AuthAuthenticated) return s.role;
    return UserRole.teacher;
  }
}
