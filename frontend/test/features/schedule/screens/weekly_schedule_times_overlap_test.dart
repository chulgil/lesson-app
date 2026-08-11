// weeklyScheduleTimesOverlap 단위 테스트 — "다른 요일에도 적용" 겹침 판정
// 로직(half-open interval)만 위젯 트리 없이 검증한다.
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_availability_split_page.dart';

WeeklySchedule _schedule(String start, String end, {int dayOfWeek = 0}) =>
    WeeklySchedule(
      id: 's',
      dayOfWeek: dayOfWeek,
      startTime: start,
      endTime: end,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('weeklyScheduleTimesOverlap', () {
    test('returns true for identical ranges', () {
      final a = _schedule('14:00', '18:00');
      final b = _schedule('14:00', '18:00');
      expect(weeklyScheduleTimesOverlap(a, b), isTrue);
    });

    test('returns true for partially overlapping ranges', () {
      final a = _schedule('14:00', '18:00');
      final b = _schedule('16:00', '20:00');
      expect(weeklyScheduleTimesOverlap(a, b), isTrue);
    });

    test('returns false for a touching boundary (end == start)', () {
      // Half-open interval: adjacent slots are not a conflict.
      final a = _schedule('14:00', '16:00');
      final b = _schedule('16:00', '18:00');
      expect(weeklyScheduleTimesOverlap(a, b), isFalse);
    });

    test('returns false for non-overlapping ranges', () {
      final a = _schedule('09:00', '10:00');
      final b = _schedule('14:00', '18:00');
      expect(weeklyScheduleTimesOverlap(a, b), isFalse);
    });

    test('is symmetric regardless of argument order', () {
      final a = _schedule('14:00', '18:00');
      final b = _schedule('16:00', '20:00');
      expect(
        weeklyScheduleTimesOverlap(a, b),
        weeklyScheduleTimesOverlap(b, a),
      );
    });
  });
}
