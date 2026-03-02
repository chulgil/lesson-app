import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/calendar/domain/entities/calendar_event.dart';

void main() {
  group('CalendarEventType', () {
    test('lesson has correct label', () {
      expect(CalendarEventType.lesson.label, '레슨');
    });

    test('practice has correct label', () {
      expect(CalendarEventType.practice.label, '연습');
    });

    test('break_ has correct label', () {
      expect(CalendarEventType.break_.label, '휴강');
    });

    test('all types have unique labels', () {
      final labels = CalendarEventType.values.map((t) => t.label).toSet();
      expect(labels.length, CalendarEventType.values.length);
    });
  });

  group('CalendarViewType', () {
    test('month has correct label', () {
      expect(CalendarViewType.month.label, '월');
    });

    test('week has correct label', () {
      expect(CalendarViewType.week.label, '주');
    });

    test('day has correct label', () {
      expect(CalendarViewType.day.label, '일');
    });

    test('all view types have unique labels', () {
      final labels = CalendarViewType.values.map((v) => v.label).toSet();
      expect(labels.length, CalendarViewType.values.length);
    });

    test('default view type should be month', () {
      // Most calendars default to month view
      expect(CalendarViewType.values.first, CalendarViewType.month);
    });
  });
}
