import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  RequestEvent createEvent({
    String id = 'evt_1',
    String requestId = 'req_1',
    ProposerRole actorType = ProposerRole.student,
    String actorId = 'student_1',
    RequestEventType eventType = RequestEventType.initialRequest,
    List<TimeSlotOption>? suggestedSlots,
    int? selectedSlotIndex,
    String? message,
    DateTime? createdAt,
  }) {
    return RequestEvent(
      id: id,
      requestId: requestId,
      actorType: actorType,
      actorId: actorId,
      eventType: eventType,
      suggestedSlots: suggestedSlots ?? [],
      selectedSlotIndex: selectedSlotIndex,
      message: message,
      createdAt: createdAt ?? DateTime(2026, 3, 29, 14, 0),
    );
  }

  TimeSlotOption createSlot({
    String id = 'slot_1',
    int dayOfWeek = 1,
    String startTime = '14:00',
    String endTime = '15:00',
  }) {
    return TimeSlotOption(
      id: id,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RequestEventType enum
  // ═══════════════════════════════════════════════════════════════════════════

  group('RequestEventType', () {
    test('label - 초기 요청', () {
      expect(RequestEventType.initialRequest.label, '레슨 요청');
    });

    test('label - 승인', () {
      expect(RequestEventType.approve.label, '수락');
    });

    test('label - 거절', () {
      expect(RequestEventType.reject.label, '거절');
    });

    test('label - 대안 시간 제안', () {
      expect(RequestEventType.proposeAlternative.label, '다른 시간 제안');
    });

    test('label - 역제안', () {
      expect(RequestEventType.counterPropose.label, '다른 시간 제안');
    });

    test('label - 대안 수락', () {
      expect(RequestEventType.acceptAlternative.label, '시간 수락');
    });

    test('label - 취소', () {
      expect(RequestEventType.cancel.label, '취소');
    });

    test('label - 만료', () {
      expect(RequestEventType.expire.label, '기간 만료');
    });

    test('label - 수강권 제안', () {
      expect(RequestEventType.proposalSent.label, '수강권 제안');
    });

    test('label - 수강권 수락', () {
      expect(RequestEventType.proposalAccepted.label, '수강권 수락');
    });

    test('label - 입금 알림', () {
      expect(RequestEventType.paymentNotified.label, '입금 알림');
    });

    test('label - 발급 완료', () {
      expect(RequestEventType.completed.label, '발급 완료');
    });

    test('isTerminal - 종료 이벤트', () {
      expect(RequestEventType.cancel.isTerminal, isTrue);
      expect(RequestEventType.expire.isTerminal, isTrue);
      expect(RequestEventType.subscriptionCompleted.isTerminal, isTrue);
      expect(RequestEventType.reject.isTerminal, isTrue);
    });

    test('isTerminal - 진행 이벤트', () {
      expect(RequestEventType.initialRequest.isTerminal, isFalse);
      expect(RequestEventType.approve.isTerminal, isFalse);
      expect(RequestEventType.proposeAlternative.isTerminal, isFalse);
      expect(RequestEventType.counterPropose.isTerminal, isFalse);
      expect(RequestEventType.acceptAlternative.isTerminal, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RequestEvent construction
  // ═══════════════════════════════════════════════════════════════════════════

  group('RequestEvent construction', () {
    test('기본 생성', () {
      final event = createEvent();
      expect(event.id, 'evt_1');
      expect(event.requestId, 'req_1');
      expect(event.actorType, ProposerRole.student);
      expect(event.actorId, 'student_1');
      expect(event.eventType, RequestEventType.initialRequest);
      expect(event.suggestedSlots, isEmpty);
      expect(event.selectedSlotIndex, isNull);
      expect(event.message, isNull);
    });

    test('시간 제안 이벤트 — 슬롯 3개', () {
      final slots = [
        createSlot(id: 's1', dayOfWeek: 1),
        createSlot(id: 's2', dayOfWeek: 3),
        createSlot(id: 's3', dayOfWeek: 5),
      ];
      final event = createEvent(
        eventType: RequestEventType.proposeAlternative,
        actorType: ProposerRole.teacher,
        actorId: 'teacher_1',
        suggestedSlots: slots,
        message: '다른 시간을 제안드립니다',
      );
      expect(event.suggestedSlots.length, 3);
      expect(event.message, '다른 시간을 제안드립니다');
      expect(event.actorType, ProposerRole.teacher);
    });

    test('수락 이벤트 — selectedSlotIndex', () {
      final event = createEvent(
        eventType: RequestEventType.acceptAlternative,
        selectedSlotIndex: 1,
      );
      expect(event.selectedSlotIndex, 1);
      expect(event.eventType, RequestEventType.acceptAlternative);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // copyWith
  // ═══════════════════════════════════════════════════════════════════════════

  group('copyWith', () {
    test('immutability — 원본 변경 없음', () {
      final original = createEvent(message: 'hello');
      final copy = original.copyWith(message: 'world');
      expect(original.message, 'hello');
      expect(copy.message, 'world');
    });

    test('모든 필드 복사', () {
      final original = createEvent(
        id: 'e1',
        requestId: 'r1',
        actorType: ProposerRole.student,
        actorId: 's1',
        eventType: RequestEventType.initialRequest,
        message: 'msg',
      );
      final copy = original.copyWith(
        id: 'e2',
        requestId: 'r2',
        actorType: ProposerRole.teacher,
        actorId: 't1',
        eventType: RequestEventType.approve,
        message: 'new',
      );
      expect(copy.id, 'e2');
      expect(copy.requestId, 'r2');
      expect(copy.actorType, ProposerRole.teacher);
      expect(copy.actorId, 't1');
      expect(copy.eventType, RequestEventType.approve);
      expect(copy.message, 'new');
    });

    test('스케줄 변경 스냅샷 필드 복사', () {
      final original = createEvent();
      final copy = original.copyWith(
        changeCreditUsed: 1,
        changeCreditRemainingAfter: 2,
        keepsSessionNumber: true,
      );

      expect(copy.changeCreditUsed, 1);
      expect(copy.changeCreditRemainingAfter, 2);
      expect(copy.keepsSessionNumber, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // JSON
  // ═══════════════════════════════════════════════════════════════════════════

  group('JSON', () {
    test('스케줄 변경 스냅샷 camelCase 필드 round-trip', () {
      final event = RequestEvent.fromJson({
        'id': 'evt_1',
        'request_id': 'req_1',
        'actor_type': 'student',
        'actor_id': 'student_1',
        'event_type': 'lessonCancelled',
        'suggested_slots': [],
        'created_at': '2026-03-29T14:00:00.000',
        'subscription_id': 'sub_1',
        'session_number': 3,
        'changeCreditUsed': 1,
        'changeCreditRemainingAfter': 2,
        'keepsSessionNumber': true,
      });

      expect(event.changeCreditUsed, 1);
      expect(event.changeCreditRemainingAfter, 2);
      expect(event.keepsSessionNumber, isTrue);

      final json = event.toJson();
      expect(json['changeCreditUsed'], 1);
      expect(json['changeCreditRemainingAfter'], 2);
      expect(json['keepsSessionNumber'], isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // chatDisplayMessage
  // ═══════════════════════════════════════════════════════════════════════════

  group('chatDisplayMessage', () {
    test('초기 요청 — 학생 이름 포함', () {
      final event = createEvent(
        eventType: RequestEventType.initialRequest,
        actorType: ProposerRole.student,
      );
      expect(event.chatDisplayMessage, '레슨을 요청했습니다');
    });

    test('수락', () {
      final event = createEvent(
        eventType: RequestEventType.approve,
        actorType: ProposerRole.teacher,
      );
      expect(event.chatDisplayMessage, '요청을 수락했습니다');
    });

    test('거절 — 메시지 포함', () {
      final event = createEvent(
        eventType: RequestEventType.reject,
        message: '현재 가능한 시간이 없어 이번에는 어렵습니다.',
      );
      expect(event.chatDisplayMessage, '레슨 요청을 거절했습니다');
    });

    test('대안 시간 제안', () {
      final event = createEvent(
        eventType: RequestEventType.proposeAlternative,
        suggestedSlots: [createSlot()],
      );
      expect(event.chatDisplayMessage, '다른 시간을 제안했습니다');
    });

    test('역제안', () {
      final event = createEvent(
        eventType: RequestEventType.counterPropose,
        suggestedSlots: [createSlot()],
      );
      expect(event.chatDisplayMessage, '다른 시간을 제안했습니다');
    });

    test('시간 수락', () {
      final event = createEvent(
        eventType: RequestEventType.acceptAlternative,
        selectedSlotIndex: 0,
      );
      expect(event.chatDisplayMessage, '제안한 시간을 수락했습니다');
    });

    test('취소', () {
      final event = createEvent(eventType: RequestEventType.cancel);
      expect(event.chatDisplayMessage, '요청을 취소했습니다');
    });

    test('만료', () {
      final event = createEvent(eventType: RequestEventType.expire);
      expect(event.chatDisplayMessage, '요청이 만료되었습니다');
    });
  });
}
