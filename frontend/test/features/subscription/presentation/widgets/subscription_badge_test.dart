import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_badge.dart';

void main() {
  // Helper to create test subscriptions
  Subscription createSubscription({
    SubscriptionType type = SubscriptionType.package,
    int? totalLessons,
    int? lessonsPerMonth,
    int usedLessons = 0,
    int bonusCount = 0,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus status = SubscriptionStatus.active,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'test_sub',
      studentId: 'student_1',
      membershipId: 'cm_001',
      type: type,
      totalLessons: totalLessons,
      lessonsPerMonth: lessonsPerMonth,
      usedLessons: usedLessons,
      bonusCount: bonusCount,
      startDate: startDate ?? now,
      endDate: endDate ?? now.add(const Duration(days: 30)),
      amount: 200000,
      status: status,
      createdAt: now,
    );
  }

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('SubscriptionBadge', () {
    testWidgets('8회권, 4회 사용 → "4/8회" 표시', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
      );

      await tester.pumpWidget(buildTestWidget(
        SubscriptionBadge(subscription: sub),
      ));

      expect(find.text('4/8회'), findsOneWidget);
    });

    testWidgets('8회권 + 2회 보너스, 0회 사용 → "10/10회" 표시 (totalLessonsForDisplay 사용)',
        (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 0,
        bonusCount: 2,
      );

      await tester.pumpWidget(buildTestWidget(
        SubscriptionBadge(subscription: sub),
      ));

      // remaining = 8 + 2 - 0 = 10
      // totalLessonsForDisplay = 8 + 2 = 10
      expect(find.text('10/10회'), findsOneWidget);
    });

    testWidgets('4회권 + 4회 보너스, 0회 사용 → "8/8회" 표시 (버그 수정 확인)',
        (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 0,
        bonusCount: 4,
      );

      await tester.pumpWidget(buildTestWidget(
        SubscriptionBadge(subscription: sub),
      ));

      // This was the bug: should NOT be "8/4회"
      expect(find.text('8/4회'), findsNothing);
      // Should be "8/8회"
      expect(find.text('8/8회'), findsOneWidget);
    });

    testWidgets('월정액 → D-N 형식 표시', (tester) async {
      final now = DateTime.now();
      final sub = createSubscription(
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        endDate: now.add(const Duration(days: 15)),
      );

      await tester.pumpWidget(buildTestWidget(
        SubscriptionBadge(subscription: sub),
      ));

      expect(find.textContaining('D-'), findsOneWidget);
    });

    testWidgets('체험 → "체험" 표시', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
      );

      await tester.pumpWidget(buildTestWidget(
        SubscriptionBadge(subscription: sub),
      ));

      expect(find.text('체험'), findsOneWidget);
    });
  });

  group('SubscriptionSummaryText', () {
    testWidgets('8회권 + 1회 보너스, 3회 사용 → "6/9회 남음" 표시', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 3,
        bonusCount: 1,
      );

      await tester.pumpWidget(buildTestWidget(
        SubscriptionSummaryText(subscription: sub),
      ));

      // remaining = 8 + 1 - 3 = 6
      // totalLessonsForDisplay = 8 + 1 = 9
      expect(find.textContaining('6/9회 남음'), findsOneWidget);
    });

    testWidgets('4회권 + 4회 보너스 → "8/4회" 아닌 "8/8회" 표시 (버그 수정 확인)',
        (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 0,
        bonusCount: 4,
      );

      await tester.pumpWidget(buildTestWidget(
        SubscriptionSummaryText(subscription: sub),
      ));

      // Bug: "8/4회" should NOT appear
      expect(find.textContaining('8/4회'), findsNothing);
      // Correct: "8/8회"
      expect(find.textContaining('8/8회'), findsOneWidget);
    });
  });
}
