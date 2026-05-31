import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote app router rebuilds when auth state changes', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('ref.watch(authNotifierProvider)'));
  });

  test('student profile logout clears auth state before navigating away', () {
    final source =
        File(
          'lib/features/student_home/presentation/screens/student_profile_tab.dart',
        ).readAsStringSync();

    expect(source, contains('authNotifierProvider.notifier).logout()'));
  });

  test('student role selection requires profile setup before invite flow', () {
    final source =
        File(
          'lib/features/auth/presentation/screens/role_select_screen.dart',
        ).readAsStringSync();

    final studentCase = RegExp(
      r'case UserRole\.student:\s*context\.go\(AppRoutes\.studentProfileSetup\);',
      multiLine: true,
    );

    expect(source, matches(studentCase));
  });
}
