import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote app router re-evaluates redirect on auth state changes', () {
    // Contract: auth state changes must drive GoRouter redirect re-evaluation
    // via refreshListenable, NOT by rebuilding the whole router on every
    // `build`. The previous `ref.watch(authNotifierProvider)` in build caused
    // the router to be re-created on each auth/mode change (losing nav state
    // and re-running the deep-link handler).
    final source = File('lib/main.dart').readAsStringSync();

    // Router must be a single reused instance fed by a refresh listenable.
    expect(source, contains('GoRouterRefreshStream'));
    expect(source, contains('refreshListenable:'));
    // The old per-build router re-creation hack must be gone.
    expect(
      source.contains('ref.watch(authNotifierProvider)'),
      isFalse,
      reason: 'auth changes flow through refreshListenable, not build re-watch',
    );
  });

  test('student profile logout clears auth state before navigating away', () {
    final source =
        File(
          'lib/features/student_home/presentation/screens/student_profile_tab.dart',
        ).readAsStringSync();

    expect(source, contains('authNotifierProvider.notifier).logout()'));
  });

  test('student role selection routes to signup-blocked until age-14 PASS', () {
    // Contract: a student picking the student role is sent straight to the
    // signup-blocked screen until carrier-based age-14 identity verification
    // (PASS) is integrated. Direct student signup is blocked, NOT routed to
    // profile setup. Policy: phone_verification_policy.md §3.2.
    //
    // #977: the role -> onboarding mapping is the SSOT UserRole.onboardingRoute,
    // shared by RoleSelectScreen's discipline gate and DisciplineSelectionScreen.
    // The student arm must still resolve to studentSignupBlocked, and
    // RoleSelectScreen must route onboarding through that SSOT (no bypass).
    final mapping =
        File(
          'lib/features/auth/presentation/extensions/user_role_visuals.dart',
        ).readAsStringSync();

    final studentCase = RegExp(
      r'case UserRole\.student:[\s\S]*?return AppRoutes\.studentSignupBlocked;',
      multiLine: true,
    );

    expect(
      mapping,
      matches(studentCase),
      reason: 'onboardingRoute student arm must stay studentSignupBlocked',
    );

    final roleSelect =
        File(
          'lib/features/auth/presentation/screens/role_select_screen.dart',
        ).readAsStringSync();

    expect(
      roleSelect.contains('context.go(role.onboardingRoute)'),
      isTrue,
      reason: 'RoleSelectScreen must route onboarding through the SSOT',
    );
  });

  test('auth identity changes clear the offline response cache', () {
    // Cross-user privacy (offline-first plan D2; data-privacy §Level-2): the
    // offline HTTP read cache must be dropped when the authenticated identity
    // changes, so user A's cached GET responses are never served to user B.
    // Wiring must exist at logout, explicit login (oauth + dev), and session
    // expiry — NOT on auto-login success (same-user restore) or token refresh.
    final source =
        File(
          'lib/features/auth/presentation/providers/auth_provider.dart',
        ).readAsStringSync();

    expect(source, contains('_clearOfflineReadCache'));
    // 1 helper definition + 4 call sites (logout, oauth login, dev login,
    // session expiry) = 5 occurrences.
    final occurrences = '_clearOfflineReadCache'.allMatches(source).length;
    expect(
      occurrences,
      greaterThanOrEqualTo(5),
      reason:
          'offline cache clear must be wired at logout, oauth/dev login, and '
          'session expiry',
    );
  });
}
