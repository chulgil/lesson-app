import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';

/// Regression for the two midnight-boundary bugs:
/// - #fix5: building a slot ending exactly at midnight (1440 min) must use
///   ClockTime.fromMinutes (wraps to 00:00) and never assert on
///   ClockTime(hour: 24).
/// - #fix3: a slot ending at midnight must display its end as 24:00 (day-end),
///   not 00:00 (which read as a backwards 23:00 - 00:00 range).
void main() {
  group('ClockTime.fromMinutes at day boundary (#fix5)', () {
    test('1440 minutes wraps to 00:00 without asserting', () {
      final t = ClockTime.fromMinutes(1440);
      expect(t.hour, 0);
      expect(t.minute, 0);
    });

    test('23:00 + 60 min end builds without throwing', () {
      const startMinutes = 23 * 60; // 23:00
      const durationMinutes = 60;
      // Previously: ClockTime(hour: 24) → assert failure.
      final end = ClockTime.fromMinutes(startMinutes + durationMinutes);
      expect(end.inMinutes, 0); // wrapped midnight
    });
  });

  group('TimeSlot.timeRange midnight display (#fix3)', () {
    TimeSlot slot(int startMin, int endMin) => TimeSlot(
      id: 's',
      dayOfWeek: 1,
      startTime: ClockTime.fromMinutes(startMin),
      endTime: ClockTime.fromMinutes(endMin),
    );

    test('23:00 -> midnight shows 24:00 as end (not 00:00)', () {
      expect(slot(23 * 60, 1440).timeRange, '23:00 - 24:00');
    });

    test('regular daytime slot is unaffected', () {
      expect(slot(14 * 60, 15 * 60).timeRange, '14:00 - 15:00');
    });

    test('true midnight-start slot keeps a real end label', () {
      // start 00:00, end 01:00 — start is midnight, so no 24:00 substitution.
      expect(slot(0, 60).timeRange, '00:00 - 01:00');
    });
  });
}
