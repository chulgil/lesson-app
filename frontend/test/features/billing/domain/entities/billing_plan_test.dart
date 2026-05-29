// #415 R4 — BillingPlan enum fromWire/toWire 라운드트립.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';

void main() {
  group('BillingPlan.fromWire', () {
    test('known tiers map 1:1', () {
      expect(BillingPlan.fromWire('free'), BillingPlan.free);
      expect(BillingPlan.fromWire('pro'), BillingPlan.pro);
      expect(BillingPlan.fromWire('studio'), BillingPlan.studio);
      expect(BillingPlan.fromWire('lifetime'), BillingPlan.lifetime);
    });

    test('unknown / null fall back to free (safe default)', () {
      expect(BillingPlan.fromWire(null), BillingPlan.free);
      expect(BillingPlan.fromWire(''), BillingPlan.free);
      expect(BillingPlan.fromWire('enterprise'), BillingPlan.free);
    });
  });

  group('BillingPlan.toWire', () {
    test('round-trips with fromWire', () {
      for (final plan in BillingPlan.values) {
        expect(BillingPlan.fromWire(plan.toWire()), plan);
      }
    });
  });
}
