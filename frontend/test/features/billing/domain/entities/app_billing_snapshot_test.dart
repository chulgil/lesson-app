// #415 R4 Phase C2 — Lifetime 얼리어답터 오퍼 가용성 게이터 테스트.
//
// `lifetimeOfferActive` 는 배너 노출 조건을 결정한다:
//  - lifetimeOfferEndsAt 가 미래
//  - plan == free OR status == trial (이미 유료 결제 사용자는 노출 안 함)

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/billing/domain/entities/app_billing_snapshot.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';

AppBillingSnapshot _snapshot({
  required BillingPlan plan,
  required BillingStatus status,
  DateTime? lifetimeOfferEndsAt,
}) {
  return AppBillingSnapshot(
    id: 'p',
    userId: 'u',
    plan: plan,
    status: status,
    startedAt: DateTime.utc(2026, 1, 1),
    expiresAt: null,
    source: 'test',
    originalTransactionId: null,
    trialUsed: false,
    lifetimeOfferEndsAt: lifetimeOfferEndsAt,
  );
}

void main() {
  group('AppBillingSnapshot.lifetimeOfferActive', () {
    test('null lifetimeOfferEndsAt → false', () {
      final s = _snapshot(plan: BillingPlan.free, status: BillingStatus.active);
      expect(s.lifetimeOfferActive, isFalse);
    });

    test('free + 미래 endsAt → true', () {
      final s = _snapshot(
        plan: BillingPlan.free,
        status: BillingStatus.active,
        lifetimeOfferEndsAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(s.lifetimeOfferActive, isTrue);
    });

    test('pro trial + 미래 endsAt → true (체험 사용자도 lifetime 가능)', () {
      final s = _snapshot(
        plan: BillingPlan.pro,
        status: BillingStatus.trial,
        lifetimeOfferEndsAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(s.lifetimeOfferActive, isTrue);
    });

    test('pro active + 미래 endsAt → false (이미 결제 중)', () {
      final s = _snapshot(
        plan: BillingPlan.pro,
        status: BillingStatus.active,
        lifetimeOfferEndsAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(s.lifetimeOfferActive, isFalse);
    });

    test('lifetime active + 미래 endsAt → false (이미 lifetime 보유)', () {
      final s = _snapshot(
        plan: BillingPlan.lifetime,
        status: BillingStatus.active,
        lifetimeOfferEndsAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(s.lifetimeOfferActive, isFalse);
    });

    test('free + 과거 endsAt → false (오퍼 만료)', () {
      final s = _snapshot(
        plan: BillingPlan.free,
        status: BillingStatus.active,
        lifetimeOfferEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(s.lifetimeOfferActive, isFalse);
    });
  });
}
