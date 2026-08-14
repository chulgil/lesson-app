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
      expect(resolveAuthRedirect(state, '/teacher/home'), AppRoutes.roleSelect);
    });

    test('allows roleSelect path itself', () {
      const state = AuthNeedsRole(userId: 'u', name: 'n', email: 'e');
      expect(resolveAuthRedirect(state, AppRoutes.roleSelect), isNull);
    });

    // #1267 — QR 스캔으로 온 신규 사용자는 역할을 고르기 전에 스캐너부터 열 수
    // 있어야 한다 (RoleSelectScreen 을 거치지 않는 대상 역할 사전결정 흐름).
    test('allows /invite/scan before a role is chosen (#1267)', () {
      const state = AuthNeedsRole(userId: 'u', name: 'n', email: 'e');
      expect(resolveAuthRedirect(state, AppRoutes.inviteScan), isNull);
    });

    test('still redirects other invite paths to roleSelect (#1267 scope)', () {
      // Only the scanner itself is whitelisted pre-role; inviteConfirm still
      // requires a role because AuthNeedsRole -> setRole() happens inside
      // ScanInviteScreen before any navigation to inviteConfirm occurs.
      const state = AuthNeedsRole(userId: 'u', name: 'n', email: 'e');
      expect(
        resolveAuthRedirect(state, AppRoutes.inviteConfirm),
        AppRoutes.roleSelect,
      );
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

    test('parentHome NOT whitelisted during onboarding → roleSelect (#582)', () {
      // Contract behind #582: a parent who has not completed onboarding cannot
      // reach /parent-home. The parent invite screen must call
      // completeOnboarding() before navigating, otherwise it bounces here.
      const parentOnboarding = AuthNeedsOnboarding(
        userId: 'u',
        name: 'n',
        email: 'e',
        role: UserRole.parent,
      );
      expect(
        resolveAuthRedirect(parentOnboarding, AppRoutes.parentHome),
        AppRoutes.roleSelect,
      );
    });

    // A2 — teacher phase subdivision (_audits/2026-06-10 §4.2)
    const teacherOnboarding = AuthNeedsOnboarding(
      userId: 'u',
      name: 'n',
      email: 'e',
      role: UserRole.teacher,
    );

    test('teacher phase=profileA → teacherProfileSetup (A2)', () {
      expect(
        resolveAuthRedirect(
          teacherOnboarding,
          '/teacher/home',
          teacherPhase: OnboardingPhase.profileA,
        ),
        AppRoutes.teacherProfileSetup,
      );
    });

    test('teacher phase=firstAvailability → teacherFirstAvailability (A2)', () {
      expect(
        resolveAuthRedirect(
          teacherOnboarding,
          '/teacher/home',
          teacherPhase: OnboardingPhase.firstAvailability,
        ),
        AppRoutes.teacherFirstAvailability,
      );
    });

    test('teacher phase=complete (unknown) falls back to roleSelect (A2)', () {
      // 데이터 로딩 중이면 phase 를 단정하지 않고 기존 폴백 유지.
      expect(
        resolveAuthRedirect(
          teacherOnboarding,
          '/teacher/home',
          teacherPhase: OnboardingPhase.complete,
        ),
        AppRoutes.roleSelect,
      );
    });

    test('parent role ignores teacherPhase param (A2: 학생/학부모 영향 없음)', () {
      const parentOnboarding = AuthNeedsOnboarding(
        userId: 'u',
        name: 'n',
        email: 'e',
        role: UserRole.parent,
      );
      expect(
        resolveAuthRedirect(
          parentOnboarding,
          '/parent-home',
          teacherPhase: OnboardingPhase.profileA,
        ),
        AppRoutes.roleSelect,
      );
    });

    test(
      'authenticated parent reaches parentHome (post-onboarding) (#582)',
      () {
        const authedParent = AuthAuthenticated(
          userId: 'u',
          name: 'n',
          email: 'e',
          role: UserRole.parent,
        );
        // Once onboarding is complete, the gate lets parentHome through.
        expect(resolveAuthRedirect(authedParent, AppRoutes.parentHome), isNull);
      },
    );
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

    // #P1-7 (teacher-journey audit 2026-08-11) — ProfileSetupScreen now
    // navigates to teacherFirstAvailability instead of home right after
    // completeOnboarding() flips auth state to AuthAuthenticated. This must
    // NOT be caught by the AuthAuthenticated splash/login/roleSelect bounce
    // branch, otherwise the new inline step 4 would immediately redirect
    // away before the teacher ever sees it.
    test(
      'authenticated teacher on teacherFirstAvailability is not redirected (#P1-7)',
      () {
        expect(
          resolveAuthRedirect(authed, AppRoutes.teacherFirstAvailability),
          isNull,
        );
      },
    );
  });

  group('resolveAuthRedirect — loading', () {
    test('never redirects while loading', () {
      expect(resolveAuthRedirect(const AuthLoading(), '/teacher/home'), isNull);
    });
  });

  group('resolveAuthRedirect — splash gate (no login flash)', () {
    const teacher = AuthAuthenticated(
      userId: 'u',
      name: 'n',
      email: 'e',
      role: UserRole.teacher,
    );

    test('stays on splash while loading (the flash this fix removes)', () {
      // Router starts at splash. During AuthLoading we must NOT redirect to
      // login — that bounce is the flash.
      expect(
        resolveAuthRedirect(const AuthLoading(), AppRoutes.splash),
        isNull,
      );
    });

    test('authenticated on splash redirects to home (not stranded)', () {
      // Without the splash branch this returns null and the logged-in user is
      // stuck on the loading screen after auth resolves.
      final result = resolveAuthRedirect(teacher, AppRoutes.splash);
      expect(result, isNotNull);
      expect(result, isNot(AppRoutes.splash));
      expect(result, isNot(AppRoutes.login));
    });

    test('unauthenticated on splash redirects to login', () {
      expect(
        resolveAuthRedirect(const AuthUnauthenticated(), AppRoutes.splash),
        AppRoutes.login,
      );
    });

    test('needs-role on splash redirects to roleSelect', () {
      const state = AuthNeedsRole(userId: 'u', name: 'n', email: 'e');
      expect(
        resolveAuthRedirect(state, AppRoutes.splash),
        AppRoutes.roleSelect,
      );
    });
  });
}
