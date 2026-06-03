import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/router/app_router.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';

/// Regression tests for the auth-aware redirect guard (remote mode).
///
/// Covers:
///  - HIGH: redirect guard actually evaluates auth state (was a no-op before
///    refreshListenable wiring).
///  - HIGH: deep-link invite (/invite/code) survives the onboarding gate
///    instead of being silently dropped.
void main() {
  group('resolveAuthRedirect — unauthenticated guard', () {
    test('blocks protected path → /login', () {
      expect(
        resolveAuthRedirect(const AuthUnauthenticated(), '/teacher/home'),
        AppRoutes.login,
      );
    });

    test('allows /login itself', () {
      expect(
        resolveAuthRedirect(const AuthUnauthenticated(), AppRoutes.login),
        isNull,
      );
    });

    test('allows public share prefix', () {
      expect(
        resolveAuthRedirect(
          const AuthUnauthenticated(),
          '/student/summary/abc123',
        ),
        isNull,
      );
    });
  });

  group('resolveAuthRedirect — needs role', () {
    test('redirects to roleSelect when role missing', () {
      const state = AuthNeedsRole(userId: 'u', name: 'n', email: 'e');
      expect(
        resolveAuthRedirect(state, '/teacher/home'),
        AppRoutes.roleSelect,
      );
    });

    test('allows roleSelect path itself', () {
      const state = AuthNeedsRole(userId: 'u', name: 'n', email: 'e');
      expect(resolveAuthRedirect(state, AppRoutes.roleSelect), isNull);
    });
  });

  group('resolveAuthRedirect — onboarding gate whitelist', () {
    const onboarding = AuthNeedsOnboarding(
      userId: 'u',
      name: 'n',
      email: 'e',
      role: UserRole.student,
    );

    test('redirects arbitrary path to roleSelect', () {
      expect(
        resolveAuthRedirect(onboarding, '/teacher/home'),
        AppRoutes.roleSelect,
      );
    });

    test('deep-link invite /invite/code survives onboarding gate', () {
      // Regression: invite deep link was dropped because inviteCode was missing
      // from the onboarding whitelist.
      expect(resolveAuthRedirect(onboarding, AppRoutes.inviteCode), isNull);
    });

    test('/invite/confirm survives onboarding gate', () {
      // Regression: code submission pushes to inviteConfirm with an Invite
      // extra; redirecting here would drop the extra and break the flow.
      expect(resolveAuthRedirect(onboarding, AppRoutes.inviteConfirm), isNull);
    });

    test('student invite code path allowed', () {
      expect(
        resolveAuthRedirect(onboarding, AppRoutes.studentInviteCode),
        isNull,
      );
    });

    test('parent invite code path allowed', () {
      expect(
        resolveAuthRedirect(onboarding, AppRoutes.parentInviteCode),
        isNull,
      );
    });

    test('onboarding-prefixed path allowed', () {
      expect(
        resolveAuthRedirect(onboarding, AppRoutes.studentProfileSetup),
        isNull,
      );
    });
  });

  group('resolveAuthRedirect — authenticated', () {
    const authed = AuthAuthenticated(
      userId: 'u',
      name: 'n',
      email: 'e',
      role: UserRole.teacher,
    );

    test('bounces away from /login to home', () {
      final result = resolveAuthRedirect(authed, AppRoutes.login);
      expect(result, isNotNull);
      expect(result, isNot(AppRoutes.login));
    });

    test('allows staying on a normal authenticated path', () {
      expect(resolveAuthRedirect(authed, '/teacher/home'), isNull);
    });
  });

  group('resolveAuthRedirect — loading', () {
    test('never redirects while loading', () {
      expect(
        resolveAuthRedirect(const AuthLoading(), '/teacher/home'),
        isNull,
      );
    });
  });
}
