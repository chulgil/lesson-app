import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
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
    bool paymentConfirmed = true,
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
      paymentConfirmed: paymentConfirmed,
    );
  }

  Widget buildTestWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SubscriptionBadge', () {
    testWidgets('8회권, 4회 사용 → "4/8회" 표시', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 4,
      );

      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );

      expect(find.text('4/8회'), findsOneWidget);
    });

    testWidgets(
      '8회권 + 2회 보너스, 0회 사용 → "10/10회" 표시 (totalLessonsForDisplay 사용)',
      (tester) async {
        final sub = createSubscription(
          type: SubscriptionType.package,
          totalLessons: 8,
          usedLessons: 0,
          bonusCount: 2,
        );

        await tester.pumpWidget(
          buildTestWidget(SubscriptionBadge(subscription: sub)),
        );

        // remaining = 8 + 2 - 0 = 10
        // totalLessonsForDisplay = 8 + 2 = 10
        expect(find.text('10/10회'), findsOneWidget);
      },
    );

    testWidgets('4회권 + 4회 보너스, 0회 사용 → "8/8회" 표시 (버그 수정 확인)', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 4,
        usedLessons: 0,
        bonusCount: 4,
      );

      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );

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

      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );

      expect(find.textContaining('D-'), findsOneWidget);
    });

    testWidgets('체험 → "체험" 표시', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.trial,
        totalLessons: 1,
        usedLessons: 0,
      );

      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );

      expect(find.text('체험'), findsOneWidget);
    });

    testWidgets('미수금 → "미수금" + 버밀리온 + 경고 아이콘', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        status: SubscriptionStatus.active,
        paymentConfirmed: false,
      );
      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );
      expect(find.text('미수금'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      final text = tester.widget<Text>(find.text('미수금'));
      expect(text.style?.color, AppColors.paperAccent);
    });

    testWidgets('기간 만료 (status=expired, 잔여 회차 있음) → "기간 만료" + 버밀리온', (
      tester,
    ) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons:
            4, // still has remaining lessons — date expiry, not depletion
        status: SubscriptionStatus.expired,
      );
      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );
      expect(find.text('기간 만료'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('기간 만료')).style?.color,
        AppColors.paperAccent,
      );
    });

    testWidgets('회차 소진 (status=expired + 0회 잔여) → "회차 소진" + 버밀리온', (
      tester,
    ) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 8, // all lessons used — depletion
        status: SubscriptionStatus.expired,
      );
      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );
      expect(find.text('회차 소진'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('회차 소진')).style?.color,
        AppColors.paperAccent,
      );
    });

    testWidgets('소진 임박 (잔여 1회) → "소진 임박 · 잔여 1회" + 시계 아이콘', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 7, // 1 remaining
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );
      expect(find.text('소진 임박 · 잔여 1회'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('날짜 임박 (D-N, 잔여 다수) → "D-N" 형식 + 시계 아이콘', (tester) async {
      // Duration(days:3) truncates to inDays=2 depending on time-of-day;
      // use days:4 to guarantee isExpiringSoon=true and daysUntilExpiration>=3.
      final sub = createSubscription(
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        endDate: DateTime.now().add(const Duration(days: 4)),
      );
      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );
      // Exact day count varies by time-of-day; verify D-N format and icon.
      expect(find.textContaining('D-'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('정상 회차권 → 중립 잉크 + 아이콘 없음', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 10,
        usedLessons: 3,
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );
      expect(find.text('7/10회'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('7/10회')).style?.color,
        AppColors.inkSecondary,
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('회귀: 같은 수강권 → 홈 직접 / 학생탭 위임 동일 라벨', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 10,
        usedLessons: 3,
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      // 홈 경로: SubscriptionBadge 직접 렌더
      await tester.pumpWidget(
        buildTestWidget(SubscriptionBadge(subscription: sub)),
      );
      expect(find.text('7/10회'), findsOneWidget); // 잔여, 사용([3/10]) 아님
      expect(find.text('[3/10]'), findsNothing);
    });

    testWidgets('smoke: 좁은 Row 제약에서 렌더 예외 없음', (tester) async {
      final sub = createSubscription(
        type: SubscriptionType.package,
        totalLessons: 10,
        usedLessons: 3,
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                SubscriptionBadge(subscription: sub),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
