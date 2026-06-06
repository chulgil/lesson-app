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
    final source =
        File(
          'lib/features/auth/presentation/screens/role_select_screen.dart',
        ).readAsStringSync();

    final studentCase = RegExp(
      r'case UserRole\.student:[\s\S]*?context\.go\(AppRoutes\.studentSignupBlocked\);',
      multiLine: true,
    );

    expect(source, matches(studentCase));
  });
}
