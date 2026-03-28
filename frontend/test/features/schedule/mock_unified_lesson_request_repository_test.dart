import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

void main() {
  late MockUnifiedLessonRequestRepository repo;

  setUp(() {
    repo = MockUnifiedLessonRequestRepository();
  });

  group('v2.0 seed data — preferredSlots migration', () {
    test('pending trial request has preferredSlots', () async {
      final request = await repo.getById('ulr_1');

      expect(request, isNotNull);
      expect(request!.preferredSlots, isNotEmpty);
      expect(request.preferredSlots.length, greaterThanOrEqualTo(1));
      expect(request.preferredSlots.first.priority, 1);
    });

    test('trial request preferredSlots have date (not null)', () async {
      final request = await repo.getById('ulr_1');

      for (final slot in request!.preferredSlots) {
        expect(slot.date, isNotNull,
            reason: 'Trial slots must have specific dates');
      }
    });

    test('regular request preferredSlots have dayOfWeek (no date)', () async {
      final request = await repo.getById('ulr_2');

      expect(request, isNotNull);
      expect(request!.preferredSlots, isNotEmpty);
      for (final slot in request.preferredSlots) {
        expect(slot.dayOfWeek, isNotNull,
            reason: 'Regular slots must have dayOfWeek');
        expect(slot.date, isNull,
            reason: 'Regular slots should not have specific date');
      }
    });

    test('pending request has 3 preferred slots', () async {
      final request = await repo.getById('ulr_1');

      expect(request!.preferredSlots.length, 3);
      expect(request.preferredSlots[0].priority, 1);
      expect(request.preferredSlots[1].priority, 2);
      expect(request.preferredSlots[2].priority, 3);
    });

    test('preferredSlots have valid startTime format (HH:mm)', () async {
      final request = await repo.getById('ulr_1');

      for (final slot in request!.preferredSlots) {
        expect(
          RegExp(r'^\d{2}:\d{2}$').hasMatch(slot.startTime),
          isTrue,
          reason: 'startTime should be HH:mm format, got: ${slot.startTime}',
        );
        expect(
          RegExp(r'^\d{2}:\d{2}$').hasMatch(slot.endTime),
          isTrue,
          reason: 'endTime should be HH:mm format, got: ${slot.endTime}',
        );
      }
    });

    test('returning student request has preferredSlots', () async {
      final request = await repo.getById('ulr_4');

      expect(request, isNotNull);
      expect(request!.preferredSlots, isNotEmpty);
      expect(request.isReturningStudent, isTrue);
    });

    test('negotiating request preserves preferredSlots from initial request',
        () async {
      final request = await repo.getById('ulr_5');

      expect(request, isNotNull);
      expect(request!.preferredSlots, isNotEmpty);
      expect(request.status, UnifiedRequestStatus.negotiating);
    });

    test('displayLabel is correct for trial slot', () async {
      final request = await repo.getById('ulr_1');
      final slot = request!.preferredSlots.first;

      // Trial slots show "M/D(요일) HH:mm"
      expect(slot.displayLabel, contains('/'));
      expect(slot.displayLabel, contains(':'));
    });

    test('displayLabel is correct for regular slot', () async {
      final request = await repo.getById('ulr_2');
      final slot = request!.preferredSlots.first;

      // Regular slots show "매주 X요일 HH:mm"
      expect(slot.displayLabel, startsWith('매주'));
    });
  });

  group('v2.0 maxRounds = 2', () {
    test('counterPropose expires at round 2 (not 3)', () async {
      // Create a request at round 1
      final request = UnifiedLessonRequest(
        id: 'ulr_round_test',
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

      // Round 2 counter-propose should expire
      final result = await repo.counterPropose(
        'ulr_round_test',
        slot: TimeSlotOption(
          id: 'ts_test',
          dayOfWeek: 0,
          startTime: '10:00',
          endTime: '11:00',
        ),
      );

      expect(result.status, UnifiedRequestStatus.expired);
    });
  });
}
