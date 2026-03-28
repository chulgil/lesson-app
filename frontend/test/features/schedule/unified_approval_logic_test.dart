import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';

void main() {
  late MockUnifiedLessonRequestRepository repo;

  setUp(() {
    repo = MockUnifiedLessonRequestRepository();
  });

  group('Teacher accepts one of student 3 preferred slots', () {
    test('approve sets status to approved', () async {
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
        ],
        message: '이 시간대는 어떠세요?',
      );

      expect(result.status, UnifiedRequestStatus.negotiating);
      expect(result.currentRound, 1);

      // Events-based: check event was created
      final events = await repo.getEventsByRequestId('ulr_1');
      final proposeEvent = events.where((e) =>
          e.eventType.name == 'proposeAlternative').toList();
      expect(proposeEvent, isNotEmpty);
      expect(proposeEvent.last.suggestedSlots.length, 2);
      expect(proposeEvent.last.message, '이 시간대는 어떠세요?');
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

      // Selected slot is tracked via event, not preferredDay/Time
      final events = await repo.getEventsByRequestId('ulr_1');
      final acceptEvent = events.lastWhere(
          (e) => e.eventType == RequestEventType.acceptAlternative);
      expect(acceptEvent.selectedSlotIndex, 0);
      expect(acceptEvent.message, '좋아요!');
    });
  });

  group('Unlimited negotiation (maxRounds removed)', () {
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

    test('round 2: student counter-proposes → still negotiating', () async {
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

      expect(result.status, isNot(UnifiedRequestStatus.expired));
      expect(result.status, UnifiedRequestStatus.negotiating);
    });

    test('round 5: still negotiating (no maxRounds limit)', () async {
      // Use ulr_2 which already has round 3
      final original = await repo.getById('ulr_2');
      expect(original!.currentRound, 3);

      final result = await repo.counterPropose(
        'ulr_2',
        slot: TimeSlotOption(
          id: 'counter_round4',
          dayOfWeek: 1,
          startTime: '10:00',
          endTime: '11:00',
        ),
      );

      expect(result.status, UnifiedRequestStatus.negotiating);
      expect(result.currentRound, 4);
    });
  });

  group('PreferredTimeSlot display', () {
    test('regular slots show weekday format', () async {
      // ulr_1 has dayOfWeek-based slots (regular)
      final request = await repo.getById('ulr_1');
      final slot = request!.preferredSlots.first;

      // dayOfWeek-based → "매주 X요일 HH:mm"
      expect(slot.displayLabel, startsWith('매주'));
    });

    test('all slots have priority ordering', () async {
      final request = await repo.getById('ulr_1');
      final priorities =
          request!.preferredSlots.map((s) => s.priority).toList();

      for (var i = 0; i < priorities.length - 1; i++) {
        expect(priorities[i], lessThan(priorities[i + 1]));
      }
    });
  });
}
