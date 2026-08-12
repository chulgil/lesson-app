// docs/specs/schedule/schedule_change_unification_spec.md §3.2/§4 (M-4) —
// dayOfWeek indexing regression coverage for the single TimeSlot <->
// PreferredTimeSlot/TimeSlotOption mapper (request_detail_screen.dart:529
// pre-M-4 manually did `dayOfWeek: s.dayOfWeek - 1`; the mapper replaces
// every such inline conversion).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/mappers/time_slot_mapper.dart';

void main() {
  TimeSlot slotAt(int dayOfWeek, {DateTime? specificDate}) => TimeSlot(
    id: 'slot_$dayOfWeek',
    dayOfWeek: dayOfWeek,
    startTime: const ClockTime(hour: 10, minute: 0),
    endTime: const ClockTime(hour: 11, minute: 0),
    specificDate: specificDate,
  );

  group('TimeSlot -> TimeSlotOption (AlternativeTimeGrid selection)', () {
    test('Monday: 1-indexed 1 -> 0-indexed 0', () {
      final option = slotAt(1).toTimeSlotOption();
      expect(option.dayOfWeek, 0);
    });

    test('Sunday: 1-indexed 7 -> 0-indexed 6', () {
      final option = slotAt(7).toTimeSlotOption();
      expect(option.dayOfWeek, 6);
    });

    test('carries id, HH:mm times, and specificDate through unchanged', () {
      final date = DateTime(2026, 8, 17); // a Monday
      final option = slotAt(1, specificDate: date).toTimeSlotOption();

      expect(option.id, 'slot_1');
      expect(option.startTime, '10:00');
      expect(option.endTime, '11:00');
      expect(option.date, date);
    });
  });

  group('TimeSlot -> PreferredTimeSlot (priority-ranked selection)', () {
    test('Monday: 1-indexed 1 -> 0-indexed 0, with given priority', () {
      final preferred = slotAt(1).toPreferredTimeSlot(priority: 2);
      expect(preferred.dayOfWeek, 0);
      expect(preferred.priority, 2);
    });

    test('Sunday: 1-indexed 7 -> 0-indexed 6', () {
      final preferred = slotAt(7).toPreferredTimeSlot(priority: 1);
      expect(preferred.dayOfWeek, 6);
    });
  });

  group('PreferredTimeSlot -> TimeSlot (WeeklyCalendarPicker output)', () {
    test('Monday: 0-indexed 0 -> 1-indexed 1', () {
      final slot =
          const PreferredTimeSlot(
            priority: 1,
            dayOfWeek: 0,
            startTime: '10:00',
            endTime: '11:00',
          ).toTimeSlot();
      expect(slot.dayOfWeek, 1);
    });

    test('Sunday: 0-indexed 6 -> 1-indexed 7', () {
      final slot =
          const PreferredTimeSlot(
            priority: 1,
            dayOfWeek: 6,
            startTime: '10:00',
            endTime: '11:00',
          ).toTimeSlot();
      expect(slot.dayOfWeek, 7);
    });

    test('falls back to date.weekday when dayOfWeek is null', () {
      final sunday = DateTime(2026, 8, 16); // a Sunday
      final slot =
          PreferredTimeSlot(
            priority: 1,
            date: sunday,
            startTime: '10:00',
            endTime: '11:00',
          ).toTimeSlot();
      // DateTime.weekday is already 1=Mon..7=Sun, matching TimeSlot directly
      // (no extra shift) — same precedence as dateForPreferredSlot's reverse
      // lookup (suggest_alternative_conflict.dart).
      expect(slot.dayOfWeek, 7);
    });

    test('parses HH:mm strings back into ClockTime', () {
      final slot =
          const PreferredTimeSlot(
            priority: 1,
            dayOfWeek: 0,
            startTime: '09:30',
            endTime: '10:15',
          ).toTimeSlot();
      expect(slot.startTime, const ClockTime(hour: 9, minute: 30));
      expect(slot.endTime, const ClockTime(hour: 10, minute: 15));
    });
  });

  group('roundtrip', () {
    test(
      'TimeSlot -> PreferredTimeSlot -> TimeSlot preserves dayOfWeek (Monday)',
      () {
        final original = slotAt(1);
        final roundTripped = original
            .toPreferredTimeSlot(priority: 1)
            .toTimeSlot(id: original.id);
        expect(roundTripped.dayOfWeek, original.dayOfWeek);
      },
    );

    test(
      'TimeSlot -> PreferredTimeSlot -> TimeSlot preserves dayOfWeek (Sunday)',
      () {
        final original = slotAt(7);
        final roundTripped = original
            .toPreferredTimeSlot(priority: 1)
            .toTimeSlot(id: original.id);
        expect(roundTripped.dayOfWeek, original.dayOfWeek);
      },
    );

    test('TimeSlot -> PreferredTimeSlot -> TimeSlot preserves times', () {
      final original = slotAt(3);
      final roundTripped = original
          .toPreferredTimeSlot(priority: 1)
          .toTimeSlot(id: original.id);
      expect(roundTripped.startTime, original.startTime);
      expect(roundTripped.endTime, original.endTime);
    });
  });
}
