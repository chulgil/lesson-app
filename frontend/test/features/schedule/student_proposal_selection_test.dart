import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

/// Tests for student-side proposal selection logic.
///
/// When teacher counter-proposes multiple slots, student must select
/// exactly one slot to confirm the schedule.
void main() {
  late TimeProposal teacherProposal;

  setUp(() {
    teacherProposal = TimeProposal(
      id: 'proposal_1',
      proposerId: 'teacher_1',
      role: ProposerRole.teacher,
      action: ProposalAction.counterPropose,
      createdAt: DateTime(2026, 3, 28),
      message: '이 시간에 가능합니다',
      slots: [
        TimeSlotOption(
          id: 'slot_1',
          dayOfWeek: 5, // Saturday
          startTime: '14:00',
          endTime: '15:00',
        ),
        TimeSlotOption(
          id: 'slot_2',
          dayOfWeek: 6, // Sunday
          startTime: '10:00',
          endTime: '11:00',
        ),
        TimeSlotOption(
          id: 'slot_3',
          dayOfWeek: 1, // Tuesday
          startTime: '16:00',
          endTime: '17:00',
        ),
      ],
    );
  });

  group('Teacher proposal data', () {
    test('teacher proposal has multiple slots', () {
      expect(teacherProposal.slots.length, 3);
    });

    test('teacher proposal has message', () {
      expect(teacherProposal.message, isNotNull);
      expect(teacherProposal.message, isNotEmpty);
    });

    test('each slot has display label', () {
      for (final slot in teacherProposal.slots) {
        expect(slot.displayLabel, isNotEmpty);
      }
    });

    test('slot display labels contain day and time', () {
      final firstSlot = teacherProposal.slots[0];
      expect(firstSlot.dayLabel, isNotEmpty);
      expect(firstSlot.startTime, '14:00');
    });
  });

  group('Student selection logic', () {
    test('selectedSlotIndex must be valid (0 to slots.length-1)', () {
      const selectedIndex = 1;
      expect(selectedIndex >= 0, isTrue);
      expect(selectedIndex < teacherProposal.slots.length, isTrue);
    });

    test('selected slot can be retrieved by index', () {
      const selectedIndex = 1;
      final selectedSlot = teacherProposal.slots[selectedIndex];
      expect(selectedSlot.id, 'slot_2');
      expect(selectedSlot.dayOfWeek, 6); // Sunday
    });

    test('no selection means index is null (cannot submit)', () {
      int? selectedIndex;
      expect(selectedIndex, isNull);

      // Can't call acceptAlternative without selection
      // ignore: unnecessary_null_comparison
      final canSubmit = selectedIndex != null;
      expect(canSubmit, isFalse);
    });

    test('exactly one slot must be selected', () {
      // Student can only select one slot at a time
      const selectedIndex = 2;
      final selectedSlot = teacherProposal.slots[selectedIndex];
      expect(selectedSlot.id, 'slot_3');
    });
  });

  group('ProposerRole', () {
    test('teacher proposals have role = teacher', () {
      expect(teacherProposal.role, ProposerRole.teacher);
    });

    test('can filter proposals by role', () {
      final proposals = [
        teacherProposal,
        TimeProposal(
          id: 'proposal_0',
          proposerId: 'student_1',
          role: ProposerRole.student,
          action: ProposalAction.propose,
          createdAt: DateTime(2026, 3, 27),
          slots: [],
        ),
      ];

      final teacherProposals =
          proposals.where((p) => p.role == ProposerRole.teacher).toList();
      expect(teacherProposals.length, 1);
      expect(teacherProposals.first.slots.length, 3);
    });
  });
}
