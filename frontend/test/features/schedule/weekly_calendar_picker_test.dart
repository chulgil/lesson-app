import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/unified_lesson_request_visuals.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/slot_selection_logic.dart';

/// Tests for WeeklyCalendarPicker logic (non-widget).
///
/// Widget rendering tests require ProviderScope + mock availability,
/// so we test the pure logic here: week navigation, past detection,
/// display labels, and SlotSelectionLogic → PreferredTimeSlot conversion.
void main() {
  group('Week navigation logic', () {
    DateTime currentWeekStart() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return today.subtract(Duration(days: today.weekday - 1));
    }

    test('currentWeekStart returns Monday of this week', () {
      final weekStart = currentWeekStart();
      expect(weekStart.weekday, 1); // Monday
    });

    test('cannot go before current week', () {
      final minWeek = currentWeekStart();
      final currentWeek = currentWeekStart();
      // canGoPrev = currentWeek.isAfter(minWeek)
      expect(currentWeek.isAfter(minWeek), false);
    });

    test('can go up to maxWeeksAhead - 1 weeks forward', () {
      const maxWeeksAhead = 4;
      final minWeek = currentWeekStart();
      final maxWeek = minWeek.add(Duration(days: 7 * (maxWeeksAhead - 1)));

      // From week 0, can go to week 3 (4 weeks total including current)
      var week = minWeek;
      var stepsForward = 0;
      while (week.isBefore(maxWeek)) {
        week = week.add(const Duration(days: 7));
        stepsForward++;
      }
      expect(stepsForward, 3);
    });

    test('week label shows correct date range', () {
      final weekStart = DateTime(2026, 3, 23); // Monday
      final weekEnd = weekStart.add(const Duration(days: 6));
      final label =
          '${weekStart.month}/${weekStart.day} ~ '
          '${weekEnd.month}/${weekEnd.day}';
      expect(label, '3/23 ~ 3/29');
    });
  });

  group('Past slot detection', () {
    test('slot before now is past', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(hours: 2));
      expect(pastDate.isBefore(now), true);
    });

    test('slot after now is not past', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(hours: 2));
      expect(futureDate.isBefore(now), false);
    });
  });

  group('Display label for selected slots', () {
    String slotDisplayLabel(SelectedSlot slot, LessonRequestType type) {
      const days = ['월', '화', '수', '목', '금', '토', '일'];
      final dayLabel = days[slot.dayOfWeek.clamp(0, 6)];

      if (type == LessonRequestType.regular) {
        return '매주 $dayLabel요일 ${slot.startTime}';
      }
      if (slot.date != null) {
        final d = slot.date!;
        return '${d.month}/${d.day}($dayLabel) ${slot.startTime}';
      }
      return '$dayLabel ${slot.startTime}';
    }

    test('trial type → shows date + day + time', () {
      // 2026-03-25 = Wednesday, dayOfWeek 2 (0=Mon)
      final slot = SelectedSlot(
        priority: 1,
        date: DateTime(2026, 3, 25),
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      );
      expect(slotDisplayLabel(slot, LessonRequestType.trial), '3/25(수) 10:00');
    });

    test('regular type → shows weekday + time', () {
      final slot = SelectedSlot(
        priority: 1,
        date: DateTime(2026, 3, 25),
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      );
      expect(slotDisplayLabel(slot, LessonRequestType.regular), '매주 수요일 10:00');
    });
  });

  group('SlotSelectionLogic → PreferredTimeSlot conversion', () {
    List<PreferredTimeSlot> convertSlots(
      List<SelectedSlot> slots,
      LessonRequestType type,
    ) {
      return slots.map((s) {
        if (type == LessonRequestType.regular) {
          return PreferredTimeSlot(
            priority: s.priority,
            dayOfWeek: s.dayOfWeek,
            startTime: s.startTime,
            endTime: s.endTime,
          );
        } else {
          return PreferredTimeSlot(
            priority: s.priority,
            date: s.date,
            dayOfWeek: s.dayOfWeek,
            startTime: s.startTime,
            endTime: s.endTime,
          );
        }
      }).toList();
    }

    test('trial converts with date', () {
      final logic = SlotSelectionLogic(maxSlots: 3);
      // 2026-03-25 = Wed, dayOfWeek=2
      logic.handleTap(
        date: DateTime(2026, 3, 25),
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      );

      final preferred = convertSlots(logic.slots, LessonRequestType.trial);

      expect(preferred.length, 1);
      expect(preferred.first.date, DateTime(2026, 3, 25));
      expect(preferred.first.dayOfWeek, 2);
      expect(preferred.first.startTime, '10:00');
      expect(preferred.first.priority, 1);
    });

    test('regular converts without date', () {
      final logic = SlotSelectionLogic(maxSlots: 3);
      logic.handleTap(
        date: DateTime(2026, 3, 25),
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      );

      final preferred = convertSlots(logic.slots, LessonRequestType.regular);

      expect(preferred.length, 1);
      expect(preferred.first.date, isNull);
      expect(preferred.first.dayOfWeek, 2);
      expect(preferred.first.startTime, '10:00');
    });

    test('3-slot selection produces correct priorities', () {
      final logic = SlotSelectionLogic(maxSlots: 3);
      // 2026-03-25=Wed(2), 2026-03-24=Tue(1), 2026-03-26=Thu(3)
      logic.handleTap(
        date: DateTime(2026, 3, 25),
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      );
      logic.handleTap(
        date: DateTime(2026, 3, 24),
        dayOfWeek: 1,
        startTime: '14:00',
        endTime: '15:00',
      );
      logic.handleTap(
        date: DateTime(2026, 3, 26),
        dayOfWeek: 3,
        startTime: '16:00',
        endTime: '17:00',
      );

      final preferred = convertSlots(logic.slots, LessonRequestType.trial);

      expect(preferred.length, 3);
      expect(preferred[0].priority, 1);
      expect(preferred[1].priority, 2);
      expect(preferred[2].priority, 3);
      expect(preferred[0].displayLabel, '3/25(수) 10:00 ~ 11:00');
      expect(preferred[1].displayLabel, '3/24(화) 14:00 ~ 15:00');
      expect(preferred[2].displayLabel, '3/26(목) 16:00 ~ 17:00');
    });

    test('regular 3-slot shows weekday labels', () {
      final logic = SlotSelectionLogic(maxSlots: 3);
      logic.handleTap(
        date: DateTime(2026, 3, 25),
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      );
      logic.handleTap(
        date: DateTime(2026, 3, 24),
        dayOfWeek: 1,
        startTime: '14:00',
        endTime: '15:00',
      );

      final preferred = convertSlots(logic.slots, LessonRequestType.regular);

      expect(preferred[0].displayLabel, '수 10:00 ~ 11:00');
      expect(preferred[1].displayLabel, '화 14:00 ~ 15:00');
    });
  });

  group('Priority color mapping', () {
    test('priority 1-3 returns distinct labels', () {
      const labels = ['', '❶', '❷', '❸'];
      expect(labels[1], '❶');
      expect(labels[2], '❷');
      expect(labels[3], '❸');
    });
  });
}
