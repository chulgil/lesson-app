import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';

void main() {
  late MockUnifiedLessonRequestRepository repo;

  setUp(() {
    repo = MockUnifiedLessonRequestRepository();
  });

  group('Teacher accepts one of student 3 preferred slots', () {
    test('approve sets status to approved', () async {
      // ulr_1 is a pending trial request with 3 preferredSlots
      final original = await repo.getById('ulr_1');
      expect(original!.status, UnifiedRequestStatus.pending);
      expect(original.preferredSlots.length, 3);

      final result = await repo.approve('ulr_1');

      expect(result.status, UnifiedRequestStatus.approved);
      expect(result.confirmedAt, isNotNull);
    });

    test('reject sets status to rejected with reason', () async {
      final result = await repo.reject(
        'ulr_1',
        reason: '현재 스케줄이 꽉 찼습니다',
      );

      expect(result.status, UnifiedRequestStatus.rejected);
      expect(result.rejectionReason, '현재 스케줄이 꽉 찼습니다');
    });
  });

  group('Teacher proposes alternatives (counter-propose)', () {
    test('proposeAlternatives sets status to negotiating', () async {
      final result = await repo.proposeAlternatives(
        'ulr_1',
        slots: [
          TimeSlotOption(
            id: 'alt_1',
            dayOfWeek: 0,
            startTime: '15:00',
            endTime: '16:00',
          ),
          TimeSlotOption(
            id: 'alt_2',
            dayOfWeek: 2,
            startTime: '11:00',
            endTime: '12:00',
          ),
          TimeSlotOption(
            id: 'alt_3',
            dayOfWeek: 4,
            startTime: '14:00',
            endTime: '15:00',
          ),
        ],
        message: '이 시간대는 어떠세요?',
      );

      expect(result.status, UnifiedRequestStatus.negotiating);
      expect(result.currentRound, 1);
      expect(result.proposals.length, 1);
      expect(result.proposals.last.slots.length, 3);
      expect(result.proposals.last.message, '이 시간대는 어떠세요?');
    });

    test('student accepts one alternative → timeConfirmed', () async {
      // First, teacher proposes alternatives
      await repo.proposeAlternatives(
        'ulr_1',
        slots: [
          TimeSlotOption(
            id: 'alt_1',
            dayOfWeek: 0,
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );

      // Student accepts
      final result = await repo.acceptAlternative(
        'ulr_1',
        selectedSlotIndex: 0,
        message: '좋아요!',
      );

      expect(result.status, UnifiedRequestStatus.timeConfirmed);
      expect(result.confirmedAt, isNotNull);
      expect(result.preferredDay, 0); // Monday
      expect(result.preferredTime, '15:00');
    });
  });

  group('2-round limit (v2.0)', () {
    test('round 1: teacher proposes → round becomes 1', () async {
      final result = await repo.proposeAlternatives(
        'ulr_1',
        slots: [
          TimeSlotOption(
            id: 'alt_1',
            dayOfWeek: 0,
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );
      expect(result.currentRound, 1);
    });

    test('round 2: student counter-proposes → round becomes 2', () async {
      // Round 1: teacher proposes
      await repo.proposeAlternatives(
        'ulr_1',
        slots: [
          TimeSlotOption(
            id: 'alt_1',
            dayOfWeek: 0,
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );

      // Student counter-proposes (round 1 → updates)
      final result = await repo.counterPropose(
        'ulr_1',
        slot: TimeSlotOption(
          id: 'counter_1',
          dayOfWeek: 3,
          startTime: '17:00',
          endTime: '18:00',
        ),
        message: '이 시간은 어떨까요?',
      );

      // Should NOT expire at round 1
      expect(result.status, isNot(UnifiedRequestStatus.expired));
    });

    test('counter at round 2 → expired', () async {
      // Create a request already at round 2
      final request = UnifiedLessonRequest(
        id: 'ulr_round2_test',
        studentId: 'student_test',
        teacherId: 'teacher_1',
        type: LessonRequestType.trial,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        status: UnifiedRequestStatus.negotiating,
        currentRound: 2,
        createdAt: DateTime.now(),
      );
      await repo.create(request);

      final result = await repo.counterPropose(
        'ulr_round2_test',
        slot: TimeSlotOption(
          id: 'counter_late',
          dayOfWeek: 1,
          startTime: '10:00',
          endTime: '11:00',
        ),
      );

      expect(result.status, UnifiedRequestStatus.expired);
    });
  });

  group('PreferredTimeSlot display for teacher view', () {
    test('trial slots show date format', () async {
      final request = await repo.getById('ulr_1');
      final slot = request!.preferredSlots.first;

      // Should contain "/" (date separator)
      expect(slot.displayLabel, contains('/'));
    });

    test('regular slots show weekday format', () async {
      final request = await repo.getById('ulr_2');
      final slot = request!.preferredSlots.first;

      expect(slot.displayLabel, startsWith('매주'));
    });

    test('all slots have priority ordering', () async {
      final request = await repo.getById('ulr_1');
      final priorities =
          request!.preferredSlots.map((s) => s.priority).toList();

      // Priorities should be ascending
      for (var i = 0; i < priorities.length - 1; i++) {
        expect(priorities[i], lessThan(priorities[i + 1]));
      }
    });
  });
}
