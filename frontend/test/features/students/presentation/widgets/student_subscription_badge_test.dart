import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';
import 'package:lessonaza/features/subscription/subscription_ui_facade.dart';
import 'package:lessonaza/features/students/presentation/widgets/student_subscription_badge.dart';

Subscription _makeSub({
  String id = 'test_sub',
  SubscriptionType type = SubscriptionType.package,
  int totalLessons = 10,
  int usedLessons = 0,
  int bonusCount = 0,
  bool paymentConfirmed = true,
}) {
  final now = DateTime.now();
  return Subscription(
    id: id,
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
    paymentConfirmed: paymentConfirmed,
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

  testWidgets('다중 수강권: 미수금이 잔여 적은 정상보다 우선 선택됨', (tester) async {
    // 정상 수강권: 잔여 2/10 (미임박·미입금), 잔여 적음
    final normal = _makeSub(id: 'normal', totalLessons: 10, usedLessons: 8);
    // 미수금 수강권: 잔여 9/10 (미임박), isUnpaid=true
    final unpaid = _makeSub(
      id: 'unpaid',
      totalLessons: 10,
      usedLessons: 1,
      paymentConfirmed: false,
    );
    // 정상이 먼저 오도록 배치 — 깨진 comparator 면 잔여 적은 정상이 선택됨
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeStudentSubscriptionsProvider(
            's1',
          ).overrideWith((ref) async => [normal, unpaid]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentSubscriptionMiniBadge(studentId: 's1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 통일 우선순위(미수금>만료>임박>정상)면 미수금이 선택되어야 한다
    expect(find.text('미수금'), findsOneWidget);
  });
}
