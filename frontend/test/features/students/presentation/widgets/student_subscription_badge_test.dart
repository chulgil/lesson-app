import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';
import 'package:lessonaza/features/subscription/subscription_ui_facade.dart';
import 'package:lessonaza/features/students/presentation/widgets/student_subscription_badge.dart';

Subscription _makeSub({
  SubscriptionType type = SubscriptionType.package,
  int totalLessons = 10,
  int usedLessons = 0,
  int bonusCount = 0,
}) {
  final now = DateTime.now();
  return Subscription(
    id: 'test_sub',
    studentId: 's1',
    membershipId: 'cm_001',
    type: type,
    totalLessons: totalLessons,
    usedLessons: usedLessons,
    bonusCount: bonusCount,
    startDate: now,
    endDate: now.add(const Duration(days: 30)),
    amount: 200000,
    status: SubscriptionStatus.active,
    createdAt: now,
  );
}

void main() {
  testWidgets('수강권 0건 → "수강권 없음" 텍스트, SubscriptionBadge 없음', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeStudentSubscriptionsProvider(
            's1',
          ).overrideWith((ref) async => <Subscription>[]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentSubscriptionMiniBadge(studentId: 's1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('수강권 없음'), findsOneWidget);
    expect(find.byType(SubscriptionBadge), findsNothing);
  });

  testWidgets('수강권 존재 → SubscriptionBadge 위임 렌더', (tester) async {
    final sub = _makeSub(
      type: SubscriptionType.package,
      totalLessons: 10,
      usedLessons: 3,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeStudentSubscriptionsProvider(
            's1',
          ).overrideWith((ref) async => [sub]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentSubscriptionMiniBadge(studentId: 's1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionBadge), findsOneWidget);
    expect(find.text('7/10회'), findsOneWidget);
  });
}
