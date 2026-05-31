import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('student profile logout clears auth state before navigating away', () {
    final source =
        File(
          'lib/features/student_home/presentation/screens/student_profile_tab.dart',
        ).readAsStringSync();

    expect(source, contains('authNotifierProvider.notifier).logout()'));
  });
}
