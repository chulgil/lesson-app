// #415 R4 Phase C2 — SubscriptionStatusCard smoke + 변형 분기 테스트.
//
// 각 변형(Free/Pro/Trial/Expired/Lifetime/Studio)이 의도된 badge/CTA 를
// 노출하고 콜백이 올바르게 라우팅되는지 확인.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/billing/domain/entities/app_billing_snapshot.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';
import 'package:lessonaza/features/billing/presentation/widgets/subscription_status_card.dart';

void main() {
  AppBillingSnapshot snapshot({
    required BillingPlan plan,
    required BillingStatus status,
    DateTime? expiresAt,
    bool trialUsed = false,
  }) => AppBillingSnapshot(
    id: 'test',
    userId: 'teacher-1',
    plan: plan,
    status: status,
    startedAt: DateTime.utc(2026, 1, 1),
    expiresAt: expiresAt,
    source: 'test',
    originalTransactionId: null,
    trialUsed: trialUsed,
  );

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SafeArea(child: child)));

  testWidgets('Free 변형: FREE 배지 + 학생 사용량 + 단일 업그레이드 CTA', (tester) async {
    var upgrade = 0, manage = 0, receipts = 0;

    await tester.pumpWidget(
      wrap(
        SubscriptionStatusCard(
          snapshot: snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 3,
          onUpgrade: () => upgrade++,
          onManage: () => manage++,
          onReceipts: () => receipts++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.billingBadgeFree), findsOneWidget);
    expect(find.textContaining('3/5'), findsOneWidget);
    expect(find.text(AppStrings.billingFreeUpgradeCta), findsOneWidget);
    expect(find.byKey(SubscriptionStatusCard.manageButtonKey), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(SubscriptionStatusCard.upgradeButtonKey));
    await tester.pump();
    expect(upgrade, 1);
    expect(manage, 0);
    expect(receipts, 0);
  });

  testWidgets('Pro 변형: PRO 배지 + D-N 갱신 + 관리/영수증 2버튼', (tester) async {
    var manage = 0, receipts = 0;
    final now = DateTime.utc(2026, 5, 1);
    final expires = now.add(const Duration(days: 12));

    await tester.pumpWidget(
      wrap(
        SubscriptionStatusCard(
          snapshot: snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.active,
            expiresAt: expires,
          ),
          studentCount: 8,
          onUpgrade: () {},
          onManage: () => manage++,
          onReceipts: () => receipts++,
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.billingBadgePro), findsOneWidget);
    expect(find.textContaining('D-12'), findsOneWidget);
    expect(find.text(AppStrings.billingManagePlanCta), findsOneWidget);
    expect(find.text(AppStrings.billingReceiptsCta), findsOneWidget);
    expect(find.byKey(SubscriptionStatusCard.upgradeButtonKey), findsNothing);

    await tester.tap(find.byKey(SubscriptionStatusCard.manageButtonKey));
    await tester.tap(find.byKey(SubscriptionStatusCard.receiptsButtonKey));
    await tester.pump();
    expect(manage, 1);
    expect(receipts, 1);
  });

  testWidgets('Trial 변형: TRIAL 배지 + D-N 종료 + Pro 전환 CTA', (tester) async {
    final now = DateTime.utc(2026, 5, 1);
    final expires = now.add(const Duration(days: 7));

    await tester.pumpWidget(
      wrap(
        SubscriptionStatusCard(
          snapshot: snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.trial,
            expiresAt: expires,
          ),
          studentCount: 4,
          onUpgrade: () {},
          onManage: () {},
          onReceipts: () {},
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.billingBadgeTrial), findsOneWidget);
    expect(find.textContaining('D-7'), findsOneWidget);
    expect(find.text(AppStrings.billingTrialConvertCta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expired 변형: EXPIRED 배지 + 7일 유예 안내 + 재결제 CTA', (tester) async {
    final now = DateTime.utc(2026, 5, 1);
    // 만료가 과거여도 status 가 expired 이면 변형이 결정됨.
    await tester.pumpWidget(
      wrap(
        SubscriptionStatusCard(
          snapshot: snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.expired,
            expiresAt: now.subtract(const Duration(days: 1)),
          ),
          studentCount: 0,
          onUpgrade: () {},
          onManage: () {},
          onReceipts: () {},
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.billingBadgeExpired), findsOneWidget);
    expect(find.text(AppStrings.billingStatusExpiredDetail), findsOneWidget);
    expect(find.text(AppStrings.paywallProBuyCta), findsOneWidget);
  });

  testWidgets('Lifetime 변형: LIFETIME 배지 + 관리/영수증 2버튼', (tester) async {
    await tester.pumpWidget(
      wrap(
        SubscriptionStatusCard(
          snapshot: snapshot(
            plan: BillingPlan.lifetime,
            status: BillingStatus.active,
          ),
          studentCount: 99,
          onUpgrade: () {},
          onManage: () {},
          onReceipts: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.billingBadgeLifetime), findsOneWidget);
    expect(find.text(AppStrings.billingStatusLifetimeDetail), findsOneWidget);
    expect(find.byKey(SubscriptionStatusCard.manageButtonKey), findsOneWidget);
    expect(
      find.byKey(SubscriptionStatusCard.receiptsButtonKey),
      findsOneWidget,
    );
  });
}
