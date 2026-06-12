import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/subscription/presentation/utils/expiry_streak_detector.dart';

void main() {
  var eventSeq = 0;

  RequestEvent event(
    RequestEventType type, {
    required int sessionNumber,
    required DateTime createdAt,
  }) {
    eventSeq++;
    return RequestEvent(
      id: 'evt_$eventSeq',
      requestId: 'sub_1',
      actorType: ProposerRole.student,
      actorId: 'student_1',
      eventType: type,
      sessionNumber: sessionNumber,
      createdAt: createdAt,
    );
  }

  /// propose → expire 사이클 1회 (2 이벤트).
  List<RequestEvent> proposeExpireCycle({
    required int sessionNumber,
    required DateTime base,
  }) {
    return [
      event(
        RequestEventType.scheduleChangeProposed,
        sessionNumber: sessionNumber,
        createdAt: base,
      ),
      event(
        RequestEventType.scheduleChangeExpired,
        sessionNumber: sessionNumber,
        createdAt: base.add(const Duration(hours: 72)),
      ),
    ];
  }

  group('hasConsecutiveExpiryStreak', () {
    test('3회 연속 만료 → true', () {
      final events = [
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 1)),
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 5)),
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 9)),
      ];

      expect(
        hasConsecutiveExpiryStreak(events: events, sessionNumber: 4),
        isTrue,
      );
    });

    test('2회 만료 → false', () {
      final events = [
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 1)),
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 5)),
      ];

      expect(
        hasConsecutiveExpiryStreak(events: events, sessionNumber: 4),
        isFalse,
      );
    });

    test('중간에 accepted 발생 시 카운터 리셋 → false', () {
      final events = [
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 1)),
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 5)),
        // 2회 만료 후 합의 성사 — 스트릭 리셋
        event(
          RequestEventType.scheduleChangeProposed,
          sessionNumber: 4,
          createdAt: DateTime(2026, 5, 9),
        ),
        event(
          RequestEventType.scheduleChangeAccepted,
          sessionNumber: 4,
          createdAt: DateTime(2026, 5, 9, 12),
        ),
        // 리셋 후 만료 2회 — threshold 미달
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 13)),
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 17)),
      ];

      expect(
        hasConsecutiveExpiryStreak(events: events, sessionNumber: 4),
        isFalse,
      );
    });

    test('다른 회차 만료는 카운트에서 제외', () {
      final events = [
        // session 4: 만료 2회
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 1)),
        ...proposeExpireCycle(sessionNumber: 4, base: DateTime(2026, 5, 5)),
        // session 5: 만료 1회 — session 4 카운트에 합산되면 안 됨
        ...proposeExpireCycle(sessionNumber: 5, base: DateTime(2026, 5, 9)),
      ];

      expect(
        hasConsecutiveExpiryStreak(events: events, sessionNumber: 4),
        isFalse,
      );
      expect(
        hasConsecutiveExpiryStreak(events: events, sessionNumber: 5),
        isFalse,
      );
    });
  });
}
