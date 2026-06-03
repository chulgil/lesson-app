import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';

/// Mirrors ScheduleChangeSlotBottomSheet._addSlotFromGrid slot construction so
/// the day-of-week + late-hour edge cases are covered without pumping the sheet.
TimeSlot _buildSlotFromCell({
  required DateTime date,
  required int hour,
  required int minute,
  required int durationMinutes,
}) {
  final startTotalMinutes = hour * 60 + minute;
  final endTotalMinutes = startTotalMinutes + durationMinutes;
  return TimeSlot(
    id: 'slot_test',
    dayOfWeek: date.weekday,
    startTime: ClockTime.fromMinutes(startTotalMinutes),
    endTime: ClockTime.fromMinutes(endTotalMinutes),
    isActive: true,
    specificDate: date,
  );
}

void main() {
  group('schedule change slot — day-of-week + late hour', () {
    // 2026-06-07 is a Sunday → DateTime.weekday == 7.
    final sunday = DateTime(2026, 6, 7);

    test('weekday is Sunday (7) for the chosen reference date', () {
      expect(sunday.weekday, DateTime.sunday);
      expect(sunday.weekday, 7);
    });

    // Regression (#bug1): Sunday cell previously used `weekday % 7` => 0,
    // making dayName lookup index [-1] and throwing RangeError.
    test('Sunday slot renders displayLabel without RangeError', () {
      final slot = _buildSlotFromCell(
        date: sunday,
        hour: 14,
        minute: 0,
        durationMinutes: 60,
      );

      expect(slot.dayOfWeek, 7);
      late final String label;
      expect(() => label = slot.displayLabel, returnsNormally);
      expect(label, contains('(일)'));
      expect(label, contains('14:00 - 15:00'));
    });

    // Red-Green proof: the OLD `weekday % 7` convention (Sunday => 0) makes
    // displayLabel throw, confirming the dayOfWeek fix is load-bearing.
    test('legacy weekday%7 dayOfWeek=0 throws (the bug being fixed)', () {
      final buggySlot = TimeSlot(
        id: 'buggy',
        dayOfWeek: sunday.weekday % 7, // == 0, the old code
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 15, minute: 0),
        isActive: true,
        specificDate: sunday,
      );
      expect(buggySlot.dayOfWeek, 0);
      expect(() => buggySlot.displayLabel, throwsRangeError);
    });

    // Regression (#bug3): a 23:30 start + 60min would compute endHour == 24,
    // which violated the ClockTime(hour < 24) assert. fromMinutes normalizes.
    test('late slot crossing midnight normalizes end time (00:30)', () {
      final slot = _buildSlotFromCell(
        date: sunday,
        hour: 23,
        minute: 30,
        durationMinutes: 60,
      );

      expect(slot.endTime.hour, 0);
      expect(slot.endTime.minute, 30);
      expect(slot.endTime.format24Hour(), '00:30');
      expect(() => slot.displayLabel, returnsNormally);
    });

    test('exactly midnight end (23:00 + 60min) normalizes to 00:00', () {
      final slot = _buildSlotFromCell(
        date: sunday,
        hour: 23,
        minute: 0,
        durationMinutes: 60,
      );

      expect(slot.endTime.hour, 0);
      expect(slot.endTime.minute, 0);
    });
  });
}
