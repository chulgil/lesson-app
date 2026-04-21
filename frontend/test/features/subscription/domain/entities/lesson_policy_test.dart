import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/subscription/domain/entities/lesson_policy.dart';

// Verifies policy summary getters produce expected user-facing strings.
// Covers the refund summary addition for §4.7 of subscription_master spec.
void main() {
  LessonPolicy policyWith({
    int fullRefundDays = 1,
    double partialRefundRatio = 0.67,
    double halfwayRefundRatio = 0,
    bool allowCarryover = true,
    int maxCarryoverLessons = 1,
    int carryoverPeriodMonths = 1,
    bool deductLessonOnNoShow = true,
    int minCancelHours = 4,
    int maxChangesPerMonth = 2,
    bool allowSameDayCancel = false,
  }) {
    return LessonPolicy(
      id: 'p1',
      teacherId: 't1',
      fullRefundDays: fullRefundDays,
      partialRefundRatio: partialRefundRatio,
      halfwayRefundRatio: halfwayRefundRatio,
      allowCarryover: allowCarryover,
      maxCarryoverLessons: maxCarryoverLessons,
      carryoverPeriodMonths: carryoverPeriodMonths,
      deductLessonOnNoShow: deductLessonOnNoShow,
      minCancelHours: minCancelHours,
      maxChangesPerMonth: maxChangesPerMonth,
      allowSameDayCancel: allowSameDayCancel,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('LessonPolicy.refundPolicySummary', () {
    test('default policy → 1일 전 100% · 첫수업 후 67% · 1/2 경과 후 0%', () {
      expect(
        policyWith().refundPolicySummary,
        '1일 전 100% · 첫수업 후 67% · 1/2 경과 후 0%',
      );
    });

    test('custom ratios render as rounded percentages', () {
      expect(
        policyWith(
          fullRefundDays: 3,
          partialRefundRatio: 0.9,
          halfwayRefundRatio: 0.5,
        ).refundPolicySummary,
        '3일 전 100% · 첫수업 후 90% · 1/2 경과 후 50%',
      );
    });

    test('rounding: 0.666 → 67%, 0.664 → 66%', () {
      expect(
        policyWith(partialRefundRatio: 0.666).refundPolicySummary,
        contains('첫수업 후 67%'),
      );
      expect(
        policyWith(partialRefundRatio: 0.664).refundPolicySummary,
        contains('첫수업 후 66%'),
      );
    });
  });

  group('LessonPolicy.noShowPolicySummary', () {
    test('deductOnNoShow true → 노쇼 시 횟수 차감', () {
      expect(
        policyWith(deductLessonOnNoShow: true).noShowPolicySummary,
        '노쇼 시 횟수 차감',
      );
    });

    test('deductOnNoShow false → 노쇼 시 횟수 유지', () {
      expect(
        policyWith(deductLessonOnNoShow: false).noShowPolicySummary,
        '노쇼 시 횟수 유지',
      );
    });
  });

  group('LessonPolicy.carryoverPolicySummary', () {
    test('allowCarryover false → 이월 불가', () {
      expect(policyWith(allowCarryover: false).carryoverPolicySummary, '이월 불가');
    });

    test('allow + 1회/1개월 → 최대 1회 이월 (1개월 내)', () {
      expect(policyWith().carryoverPolicySummary, '최대 1회 이월 (1개월 내)');
    });
  });
}
