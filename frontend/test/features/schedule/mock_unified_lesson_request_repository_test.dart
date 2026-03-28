import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

void main() {
  late MockUnifiedLessonRequestRepository repo;

  setUp(() {
    repo = MockUnifiedLessonRequestRepository();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // v4.0 seed data — 10 scenarios
  // ═══════════════════════════════════════════════════════════════════════════

  group('seed data count', () {
    test('10개 요청 시드', () async {
      final requests = await repo.getByTeacherId('teacher_1');
      expect(requests.length, 10);
    });
  });

  group('scenario 1: 대기 중 (희망시간 3개)', () {
    test('pending + 3 slots + 1 event', () async {
      final request = await repo.getById('ulr_1');
      expect(request!.status, UnifiedRequestStatus.pending);
      expect(request.preferredSlots.length, 3);
      expect(request.type, LessonRequestType.regular);

      final events = await repo.getEventsByRequestId('ulr_1');
      expect(events.length, 1);
      expect(events.first.eventType, RequestEventType.initialRequest);
    });
  });

  group('scenario 2: 협상 중 라운드 3', () {
    test('negotiating + round 3 + 6 events', () async {
      final request = await repo.getById('ulr_2');
      expect(request!.status, UnifiedRequestStatus.negotiating);
      expect(request.currentRound, 3);

      final events = await repo.getEventsByRequestId('ulr_2');
      expect(events.length, 6);
      // Verify alternating actor types
      expect(events[0].actorType, ProposerRole.student);
      expect(events[1].actorType, ProposerRole.teacher);
      expect(events[2].actorType, ProposerRole.student);
      expect(events[3].actorType, ProposerRole.teacher);
    });
  });

  group('scenario 3: 오늘 완료', () {
    test('completed + 4 events', () async {
      final request = await repo.getById('ulr_3');
      expect(request!.status, UnifiedRequestStatus.completed);

      final events = await repo.getEventsByRequestId('ulr_3');
      expect(events.length, 4);
      expect(events.last.eventType, RequestEventType.completed);
    });
  });

  group('scenario 5: 학생 취소', () {
    test('cancelled + 2 events', () async {
      final request = await repo.getById('ulr_5');
      expect(request!.status, UnifiedRequestStatus.cancelled);

      final events = await repo.getEventsByRequestId('ulr_5');
      expect(events.length, 2);
      expect(events.last.eventType, RequestEventType.cancel);
      expect(events.last.actorType, ProposerRole.student);
    });
  });

  group('scenario 6: 기간 만료', () {
    test('expired + isExpiredByDate', () async {
      final request = await repo.getById('ulr_6');
      expect(request!.status, UnifiedRequestStatus.expired);
      expect(request.isExpiredByDate, isTrue);
    });
  });

  group('scenario 7+8: 복수 악기 (같은 학생)', () {
    test('student_1이 바이올린+피아노 2건', () async {
      final requests = await repo.getByStudentId('student_1');
      final instruments = requests.map((r) => r.instrument).toSet();
      expect(instruments, containsAll(['바이올린', '피아노']));
    });
  });

  group('scenario 9: 회차권', () {
    test('package type', () async {
      final request = await repo.getById('ulr_9');
      expect(request!.type, LessonRequestType.package);
      expect(request.typeDisplayLabel, '회차권');
    });
  });

  group('scenario 10: 재수강 (학원)', () {
    test('returning student + academy', () async {
      final request = await repo.getById('ulr_10');
      expect(request!.isReturningStudent, isTrue);
      expect(request.academyId, 'academy_1');
      expect(request.isAcademy, isTrue);
      expect(request.typeDisplayLabel, '재수강');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RequestEvent access
  // ═══════════════════════════════════════════════════════════════════════════

  group('getEventsByRequestId', () {
    test('sorted by createdAt ascending', () async {
      final events = await repo.getEventsByRequestId('ulr_2');
      for (int i = 0; i < events.length - 1; i++) {
        expect(events[i].createdAt.isBefore(events[i + 1].createdAt), isTrue);
      }
    });

    test('없는 요청 → 빈 리스트', () async {
      final events = await repo.getEventsByRequestId('nonexistent');
      expect(events, isEmpty);
    });
  });

  group('addEvent', () {
    test('이벤트 추가', () async {
      final event = RequestEvent(
        id: 'evt_new',
        requestId: 'ulr_1',
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        eventType: RequestEventType.approve,
        createdAt: DateTime.now(),
      );
      await repo.addEvent(event);

      final events = await repo.getEventsByRequestId('ulr_1');
      expect(events.length, 2); // 1 seed + 1 new
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Mutation with events
  // ═══════════════════════════════════════════════════════════════════════════

  group('proposeAlternatives creates event', () {
    test('negotiating + event added', () async {
      final before = await repo.getEventsByRequestId('ulr_1');
      final beforeCount = before.length;

      await repo.proposeAlternatives(
        'ulr_1',
        slots: [
          TimeSlotOption(id: 'ts_new', dayOfWeek: 1, startTime: '15:00', endTime: '16:00'),
        ],
        message: '다른 시간 제안합니다',
      );

      final after = await repo.getEventsByRequestId('ulr_1');
      expect(after.length, beforeCount + 1);
      expect(after.last.eventType, RequestEventType.proposeAlternative);

      final request = await repo.getById('ulr_1');
      expect(request!.status, UnifiedRequestStatus.negotiating);
    });
  });

  group('무제한 핑퐁 — maxRounds 제거', () {
    test('라운드 5에서도 counterPropose 가능', () async {
      final request = UnifiedLessonRequest(
        id: 'ulr_unlimited',
        studentId: 'student_test',
        teacherId: 'teacher_1',
        type: LessonRequestType.regular,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        status: UnifiedRequestStatus.negotiating,
        currentRound: 5,
        createdAt: DateTime.now(),
      );
      await repo.create(request);

      final result = await repo.counterPropose(
        'ulr_unlimited',
        slot: TimeSlotOption(
          id: 'ts_test',
          dayOfWeek: 0,
          startTime: '10:00',
          endTime: '11:00',
        ),
      );

      // Should NOT expire — unlimited rounds
      expect(result.status, UnifiedRequestStatus.negotiating);
      expect(result.currentRound, 6);
    });
  });
}
