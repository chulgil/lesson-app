import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';

/// #101: currentUserId 가 미인증/온보딩 상태에서 공용 mock ID('teacher_1' 등)로
/// 폴백하면 사용자별 Hive 키(coachmark/quest/dismiss)가 교차오염된다.
/// remote 모드에서는 userId 를 가진 모든 auth 상태(온보딩 포함)에서 실제 ID 를
/// 반환해야 한다.

class _StubAuth extends AuthNotifier {
  _StubAuth(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

ProviderContainer _container({required bool mock, AuthState? auth}) {
  final container = ProviderContainer(
    overrides: [
      mockDataModeProvider.overrideWithValue(mock),
      if (auth != null)
        authNotifierProvider.overrideWith(() => _StubAuth(auth)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('currentUserId', () {
    test('remote + AuthNeedsOnboarding → 실제 userId (mock 폴백 아님)', () {
      final container = _container(
        mock: false,
        auth: const AuthNeedsOnboarding(
          userId: 'real-onboarding-123',
          name: '온보딩중',
          email: 'o@test.com',
          role: UserRole.teacher,
        ),
      );
      expect(container.read(currentUserIdProvider), 'real-onboarding-123');
    });

    test('remote + AuthNeedsRole → 실제 userId', () {
      final container = _container(
        mock: false,
        auth: const AuthNeedsRole(
          userId: 'real-needsrole-456',
          name: '역할선택중',
          email: 'r@test.com',
        ),
      );
      expect(container.read(currentUserIdProvider), 'real-needsrole-456');
    });

    test('remote + AuthAuthenticated → 실제 userId (기존 동작 유지)', () {
      final container = _container(
        mock: false,
        auth: const AuthAuthenticated(
          userId: 'real-authed-789',
          name: '인증완료',
          email: 'a@test.com',
          role: UserRole.student,
        ),
      );
      expect(container.read(currentUserIdProvider), 'real-authed-789');
    });

    test('mock 모드 → 역할 기반 mock ID 유지', () {
      final container = _container(mock: true);
      expect(container.read(currentUserIdProvider), 'teacher_1');
    });
  });
}
