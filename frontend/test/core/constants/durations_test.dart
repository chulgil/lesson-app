import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/constants/durations.dart';

void main() {
  group('durations.dart 공통 Duration 상수', () {
    test('kQuestGraduationGrace == 7 days', () {
      expect(kQuestGraduationGrace, const Duration(days: 7));
    });

    test('kCategoryNewBadgeWindow == 7 days', () {
      expect(kCategoryNewBadgeWindow, const Duration(days: 7));
    });
  });
}
