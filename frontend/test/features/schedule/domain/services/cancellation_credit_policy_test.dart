// #578 — CancellationCreditPolicy 순수 로직.
// 기준: lesson_cancellation_flow_spec §2, §3.3, §7, §8.2.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/cancel_reason.dart';
import 'package:lessonaza/features/schedule/domain/services/cancellation_credit_policy.dart';

void main() {
  const policy = CancellationCreditPolicy();

  // 레슨 시작: 2026-06-10 15:00, 마감 12시간 전 = 2026-06-10 03:00.
  final lessonStart = DateTime(2026, 6, 10, 15, 0);
  const deadlineHours = 12;
  final beforeDeadline = DateTime(2026, 6, 10, 2, 0); // 03:00 이전 → 무료
  final afterDeadline = DateTime(2026, 6, 10, 9, 0); // 03:00 이후 → 차감

  CancellationCreditOutcome run({
    required CancelReason reason,
    required DateTime now,
    int used = 0,
    int max = 2,
  }) {
    return policy.compute(
      reason: reason,
      lessonStart: lessonStart,
      now: now,
      deadlineHours: deadlineHours,
      usedReschedule: used,
      maxReschedule: max,
    );
  }

  group('학생 사유 — 마감 전 (무료)', () {
    test('studentSchedule 마감 전 → creditUsed 0, 차단 없음', () {
      final o = run(reason: CancelReason.studentSchedule, now: beforeDeadline);
      expect(o.creditUsed, 0);
      expect(o.beforeDeadline, isTrue);
      expect(o.blocked, isFalse);
      expect(o.remainingAfter, 2); // 그대로 유지
    });

    test('studentSick 마감 전 → 잔여 0이어도 무료 허용 (§8.2)', () {
      final o = run(
        reason: CancelReason.studentSick,
        now: beforeDeadline,
        used: 2,
      );
      expect(o.creditUsed, 0);
      expect(o.blocked, isFalse);
    });
  });

  group('학생 사유 — 마감 후 (차감)', () {
    test('studentSchedule 마감 후 → creditUsed 1, remaining 감소', () {
      final o = run(
        reason: CancelReason.studentSchedule,
        now: afterDeadline,
        used: 0,
      );
      expect(o.creditUsed, 1);
      expect(o.beforeDeadline, isFalse);
      expect(o.blocked, isFalse);
      expect(o.remainingAfter, 1);
    });

    test('마감 후 마지막 크레딧 → remaining 0 (§8.1)', () {
      final o = run(
        reason: CancelReason.studentSick,
        now: afterDeadline,
        used: 1,
      );
      expect(o.creditUsed, 1);
      expect(o.remainingAfter, 0);
    });

    test('마감 후 잔여 0 → 차단 (§8.2)', () {
      final o = run(
        reason: CancelReason.studentSchedule,
        now: afterDeadline,
        used: 2,
      );
      expect(o.blocked, isTrue);
      expect(o.creditUsed, 0);
    });
  });

  group('선생님/합의 — 항상 무료', () {
    test('teacherCancel 마감 후라도 차감 없음', () {
      final o = run(reason: CancelReason.teacherCancel, now: afterDeadline);
      expect(o.creditUsed, 0);
      expect(o.blocked, isFalse);
    });

    test('mutual 마감 후 잔여 0이어도 차단 없음', () {
      final o = run(
        reason: CancelReason.mutual,
        now: afterDeadline,
        used: 2,
      );
      expect(o.creditUsed, 0);
      expect(o.blocked, isFalse);
    });
  });

  group('경계값', () {
    test('정확히 마감 시각 = 마감 후로 취급 (now == deadline → beforeDeadline false)', () {
      // 마감 = 03:00 정각.
      final o = run(
        reason: CancelReason.studentSchedule,
        now: DateTime(2026, 6, 10, 3, 0),
      );
      // isBefore(deadline) 가 false → 마감 후 → 차감.
      expect(o.beforeDeadline, isFalse);
      expect(o.creditUsed, 1);
    });
  });
}
