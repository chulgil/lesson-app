import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/subscription/domain/entities/lesson_policy.dart';
import 'package:lessonaza/features/subscription/domain/entities/refund_calculator.dart';

// Policy-backed refund amount calculation per subscription_master.md §4.7.
// Pure logic — no widget tests needed.
void main() {
  LessonPolicy policyWith({
    int fullRefundDays = 1,
    double partialRefundRatio = 0.67,
    double halfwayRefundRatio = 0,
    double noShowRefundRatio = 0.67,
  }) {
    return LessonPolicy(
      id: 'policy_1',
      teacherId: 'teacher_1',
      fullRefundDays: fullRefundDays,
      partialRefundRatio: partialRefundRatio,
      halfwayRefundRatio: halfwayRefundRatio,
      noShowRefundRatio: noShowRefundRatio,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('RefundCalculator', () {
    test('no lessons used, before first lesson → full refund', () {
      final result = RefundCalculator.calculate(
        totalPrice: 380000,
        totalSessions: 8,
        usedSessions: 0,
        policy: policyWith(),
        daysUntilFirstLesson: 2,
      );
      expect(result.amount, 380000);
      expect(result.rule, RefundRule.fullRefund);
    });

    test('0 sessions used, within fullRefundDays cutoff → partial', () {
      final result = RefundCalculator.calculate(
        totalPrice: 380000,
        totalSessions: 8,
        usedSessions: 0,
        policy: policyWith(),
        daysUntilFirstLesson: 0,
      );
      // remaining 8 * perSession 47500 * 0.67 = 254,600
      expect(result.rule, RefundRule.partialRefund);
      expect(result.amount, 254600);
    });

    test('3 sessions used of 8 → partial refund by ratio', () {
      // spec §4.7: 8회권 380,000원, 3회 사용 후 90% 환불 → 213,750원
      // Here partialRefundRatio = 0.9 (not 0.67)
      final result = RefundCalculator.calculate(
        totalPrice: 380000,
        totalSessions: 8,
        usedSessions: 3,
        policy: policyWith(partialRefundRatio: 0.9),
        daysUntilFirstLesson: -5,
      );
      // remaining 5 * 47500 = 237,500 * 0.9 = 213,750
      expect(result.rule, RefundRule.partialRefund);
      expect(result.amount, 213750);
    });

    test('past halfway point → halfwayRefundRatio applied', () {
      final result = RefundCalculator.calculate(
        totalPrice: 380000,
        totalSessions: 8,
        usedSessions: 5,
        policy: policyWith(halfwayRefundRatio: 0),
        daysUntilFirstLesson: -10,
      );
      // past halfway (5/8 > 0.5) → ratio 0
      expect(result.rule, RefundRule.halfwayRefund);
      expect(result.amount, 0);
    });

    test('all sessions used → no refund', () {
      final result = RefundCalculator.calculate(
        totalPrice: 380000,
        totalSessions: 8,
        usedSessions: 8,
        policy: policyWith(),
        daysUntilFirstLesson: -60,
      );
      expect(result.amount, 0);
      expect(result.rule, RefundRule.noRefund);
    });

    test('zero sessions is guarded (no division by zero)', () {
      final result = RefundCalculator.calculate(
        totalPrice: 100000,
        totalSessions: 0,
        usedSessions: 0,
        policy: policyWith(),
        daysUntilFirstLesson: 5,
      );
      expect(result.amount, 100000);
      expect(result.rule, RefundRule.fullRefund);
    });
  });
}
