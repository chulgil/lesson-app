// #415 R4 — MockAppBillingRepository 기본값 + 주입.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/billing/data/repositories/mock_app_billing_repository.dart';
import 'package:lessonaza/features/billing/domain/entities/app_billing_snapshot.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';

void main() {
  test('default snapshot → free + active', () async {
    final repo = MockAppBillingRepository();
    final snapshot = await repo.fetchSnapshot();
    expect(snapshot.plan, BillingPlan.free);
    expect(snapshot.status, BillingStatus.active);
    expect(snapshot.isUnlimited, isFalse);
    expect(snapshot.isActiveOrTrial, isTrue);
  });

  test('주입한 snapshot 그대로 반환', () async {
    final injected = AppBillingSnapshot(
      id: 'inj-1',
      userId: 'u-1',
      plan: BillingPlan.pro,
      status: BillingStatus.trial,
      startedAt: DateTime.utc(2026, 3, 1),
      expiresAt: DateTime.utc(2026, 3, 15),
      source: 'mock',
      originalTransactionId: null,
      trialUsed: false,
    );
    final repo = MockAppBillingRepository(initial: injected);
    final snapshot = await repo.fetchSnapshot();
    expect(snapshot.plan, BillingPlan.pro);
    expect(snapshot.status, BillingStatus.trial);
    expect(snapshot.isUnlimited, isTrue);
    expect(snapshot.isActiveOrTrial, isTrue);
  });

  test('freeFallback 헬퍼는 unlimited=false, isActiveOrTrial=true', () {
    final fallback = AppBillingSnapshot.freeFallback(userId: 'u-99');
    expect(fallback.plan, BillingPlan.free);
    expect(fallback.status, BillingStatus.active);
    expect(fallback.userId, 'u-99');
    expect(fallback.isUnlimited, isFalse);
    expect(fallback.isActiveOrTrial, isTrue);
    expect(fallback.expiresAt, isNull);
  });
}
