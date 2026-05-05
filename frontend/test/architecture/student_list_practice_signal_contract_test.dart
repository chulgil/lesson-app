import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'students tab list cards do not render weekly practice sparkline signal',
    () {
      final studentsTab = File(
        'lib/features/students/presentation/screens/students_tab.dart',
      );
      final content = studentsTab.readAsStringSync();

      expect(content, isNot(contains('PracticeSparkline')));
      expect(content, isNot(contains('_PracticeDots')));
      expect(content, isNot(contains('weeklyPracticeProvider')));
      expect(content, isNot(contains('/7일')));
    },
  );

  test('student detail may still show weekly practice summary', () {
    final practiceSection = File(
      'lib/features/students/presentation/widgets/student_detail/student_practice_section.dart',
    );
    final content = practiceSection.readAsStringSync();

    expect(content, contains('weeklyPracticeProvider'));
    expect(content, contains('/7일'));
  });
}
