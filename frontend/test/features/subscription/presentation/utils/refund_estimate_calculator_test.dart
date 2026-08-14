import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/lesson_policy.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/utils/refund_estimate_calculator.dart';

void main() {
  final policy = LessonPolicy(
    id: 'policy_1',
    teacherId: 'teacher_1',
    fullRefundDays: 1,
    partialRefundRatio: 0.67,
    halfwayRefundRatio: 0.3,
    createdAt: DateTime(2026, 1, 1),
  );

  Subscription buildSubscription({
    required int totalLessons,
    required int usedLessons,
    required int amount,
    DateTime? startDate,
  }) {
    return Subscription(
      id: 'sub_1',
      studentId: 'student_1',
      membershipId: 'membership_1',
      type: SubscriptionType.package,
      totalLessons: totalLessons,
      usedLessons: usedLessons,
      amount: amount,
      status: SubscriptionStatus.active,
      startDate: startDate,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('estimateRefundAmount', () {
    test('full refund within fullRefundDays with no lessons used', () {
      final now = DateTime(2026, 3, 10, 12);
      final subscription = buildSubscription(
        totalLessons: 8,
        usedLessons: 0,
        amount: 400000,
        startDate: DateTime(2026, 3, 10),
      );

      final result = estimateRefundAmount(
        subscription: subscription,
        policy: policy,
        now: now,
      );

      expect(result, 400000);
    });

    test('partial ratio applied once outside the full-refund window', () {
      final subscription = buildSubscription(
        totalLessons: 8,
        usedLessons: 1,
        amount: 400000,
        startDate: DateTime(2026, 1, 1),
      );

      // Unused value: 400000 * 7/8 = 350000. Used 1/8 < 50% -> partialRatio.
      final result = estimateRefundAmount(
        subscription: subscription,
        policy: policy,
        now: DateTime(2026, 3, 1),
      );

      expect(result, (350000 * 0.67).round());
    });

    test('halfway ratio applied once half or more lessons are used', () {
      final subscription = buildSubscription(
        totalLessons: 8,
        usedLessons: 4,
        amount: 400000,
        startDate: DateTime(2026, 1, 1),
      );

      // Unused value: 400000 * 4/8 = 200000. Used 4/8 == 50% -> halfwayRatio.
      final result = estimateRefundAmount(
        subscription: subscription,
        policy: policy,
        now: DateTime(2026, 3, 1),
      );

      expect(result, (200000 * 0.3).round());
    });

    test('returns null when no lessons remain', () {
      final subscription = buildSubscription(
        totalLessons: 8,
        usedLessons: 8,
        amount: 400000,
        startDate: DateTime(2026, 1, 1),
      );

      final result = estimateRefundAmount(
        subscription: subscription,
        policy: policy,
        now: DateTime(2026, 3, 1),
      );

      expect(result, isNull);
    });

    test('returns null when the subscription has no lesson total', () {
      final subscription = Subscription(
        id: 'sub_trial',
        studentId: 'student_1',
        membershipId: 'membership_1',
        type: SubscriptionType.monthly,
        amount: 100000,
        status: SubscriptionStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

      final result = estimateRefundAmount(
        subscription: subscription,
        policy: policy,
      );

      expect(result, isNull);
    });
  });
}
