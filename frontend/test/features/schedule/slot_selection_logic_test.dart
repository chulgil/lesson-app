import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/slot_selection_logic.dart';

void main() {
  group('SlotSelectionLogic', () {
    late SlotSelectionLogic logic;

    setUp(() {
      logic = SlotSelectionLogic(maxSlots: 3);
    });

    group('tap cycling', () {
      test('first tap → priority 1', () {
        final result = logic.handleTap(
          date: DateTime(2026, 3, 26),
          dayOfWeek: 2,
          startTime: '10:00',
          endTime: '11:00',
        );

        expect(result.length, 1);
        expect(result.first.priority, 1);
        expect(result.first.startTime, '10:00');
      });

      test('second different tap → priority 2', () {
        logic.handleTap(
          date: DateTime(2026, 3, 26),
          dayOfWeek: 2,
          startTime: '10:00',
          endTime: '11:00',
        );
        final result = logic.handleTap(
          date: DateTime(2026, 3, 25),
          dayOfWeek: 1,
          startTime: '11:00',
          endTime: '12:00',
        );

        expect(result.length, 2);
        expect(result[0].priority, 1);
        expect(result[1].priority, 2);
      });

      test('third different tap → priority 3', () {
        logic.handleTap(
            date: DateTime(2026, 3, 26),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');
        logic.handleTap(
            date: DateTime(2026, 3, 25),
            dayOfWeek: 1,
            startTime: '11:00',
            endTime: '12:00');
        final result = logic.handleTap(
            date: DateTime(2026, 3, 27),
            dayOfWeek: 3,
            startTime: '14:00',
            endTime: '15:00');

        expect(result.length, 3);
        expect(result[2].priority, 3);
      });

      test('fourth tap → reset to priority 1 only', () {
        logic.handleTap(
            date: DateTime(2026, 3, 26),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');
        logic.handleTap(
            date: DateTime(2026, 3, 25),
            dayOfWeek: 1,
            startTime: '11:00',
            endTime: '12:00');
        logic.handleTap(
            date: DateTime(2026, 3, 27),
            dayOfWeek: 3,
            startTime: '14:00',
            endTime: '15:00');
        final result = logic.handleTap(
            date: DateTime(2026, 3, 28),
            dayOfWeek: 4,
            startTime: '09:00',
            endTime: '10:00');

        expect(result.length, 1);
        expect(result.first.priority, 1);
        expect(result.first.startTime, '09:00');
      });
    });

    group('same slot re-tap → remove', () {
      test('re-tap selected slot → removes it', () {
        logic.handleTap(
            date: DateTime(2026, 3, 26),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');
        logic.handleTap(
            date: DateTime(2026, 3, 25),
            dayOfWeek: 1,
            startTime: '11:00',
            endTime: '12:00');

        // Re-tap first slot
        final result = logic.handleTap(
            date: DateTime(2026, 3, 26),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');

        expect(result.length, 1);
        expect(result.first.priority, 1); // renumbered
        expect(result.first.startTime, '11:00');
      });
    });

    group('duplicate prevention', () {
      test('same dayOfWeek + startTime is blocked', () {
        logic.handleTap(
            date: DateTime(2026, 3, 26),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');

        // Same dayOfWeek+time, different date
        final result = logic.handleTap(
            date: DateTime(2026, 4, 2),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');

        // Should treat as re-tap (remove), not add
        expect(result.length, 0);
      });
    });

    group('clear', () {
      test('clear removes all selections', () {
        logic.handleTap(
            date: DateTime(2026, 3, 26),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');
        logic.clear();

        expect(logic.slots, isEmpty);
      });
    });

    group('removeAt', () {
      test('removeAt renumbers remaining slots', () {
        logic.handleTap(
            date: DateTime(2026, 3, 26),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00');
        logic.handleTap(
            date: DateTime(2026, 3, 25),
            dayOfWeek: 1,
            startTime: '11:00',
            endTime: '12:00');
        logic.handleTap(
            date: DateTime(2026, 3, 27),
            dayOfWeek: 3,
            startTime: '14:00',
            endTime: '15:00');

        logic.removeAt(0); // Remove priority 1

        expect(logic.slots.length, 2);
        expect(logic.slots[0].priority, 1); // was 2, now renumbered to 1
        expect(logic.slots[1].priority, 2); // was 3, now 2
      });
    });
  });
}
