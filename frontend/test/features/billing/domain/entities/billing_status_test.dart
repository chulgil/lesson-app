// #415 R4 — BillingStatus enum fromWire/toWire 라운드트립.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';

void main() {
  group('BillingStatus.fromWire', () {
    test('known states map 1:1', () {
      expect(BillingStatus.fromWire('active'), BillingStatus.active);
      expect(BillingStatus.fromWire('trial'), BillingStatus.trial);
      expect(BillingStatus.fromWire('expired'), BillingStatus.expired);
      expect(BillingStatus.fromWire('cancelled'), BillingStatus.cancelled);
    });

    test('unknown / null fall back to active', () {
      expect(BillingStatus.fromWire(null), BillingStatus.active);
      expect(BillingStatus.fromWire(''), BillingStatus.active);
      expect(BillingStatus.fromWire('paused'), BillingStatus.active);
    });
  });

  test('toWire round-trips', () {
    for (final status in BillingStatus.values) {
      expect(BillingStatus.fromWire(status.toWire()), status);
    }
  });
}
