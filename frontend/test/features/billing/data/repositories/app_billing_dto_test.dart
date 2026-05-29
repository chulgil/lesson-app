// #415 R4 — AppBillingDto.fromJson 매퍼.
//
// snake_case + camelCase 양쪽 허용, 알 수 없는 필드는 안전한 fallback.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/billing/data/repositories/app_billing_dto.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';

void main() {
  group('AppBillingDto.fromJson — snake_case (백엔드 표준)', () {
    test('full snake_case payload', () {
      final snapshot = AppBillingDto.fromJson({
        'id': 'plan-1',
        'user_id': 'user-1',
        'tier': 'pro',
        'status': 'trial',
        'started_at': '2026-01-01T00:00:00Z',
        'expires_at': '2026-01-15T00:00:00Z',
        'source': 'ios',
        'original_transaction_id': 'txn-abc',
        'trial_used': true,
      });
      expect(snapshot.id, 'plan-1');
      expect(snapshot.userId, 'user-1');
      expect(snapshot.plan, BillingPlan.pro);
      expect(snapshot.status, BillingStatus.trial);
      expect(snapshot.startedAt, DateTime.utc(2026, 1, 1));
      expect(snapshot.expiresAt, DateTime.utc(2026, 1, 15));
      expect(snapshot.source, 'ios');
      expect(snapshot.originalTransactionId, 'txn-abc');
      expect(snapshot.trialUsed, isTrue);
    });
  });

  group('AppBillingDto.fromJson — camelCase fallback', () {
    test('camelCase payload', () {
      final snapshot = AppBillingDto.fromJson({
        'id': 'plan-1',
        'userId': 'user-1',
        'tier': 'studio',
        'status': 'active',
        'startedAt': '2026-02-01T00:00:00Z',
        'expiresAt': '2027-02-01T00:00:00Z',
        'source': 'android',
        'originalTransactionId': 'txn-xyz',
        'trialUsed': false,
      });
      expect(snapshot.userId, 'user-1');
      expect(snapshot.plan, BillingPlan.studio);
      expect(snapshot.status, BillingStatus.active);
      expect(snapshot.originalTransactionId, 'txn-xyz');
    });
  });

  group('AppBillingDto.fromJson — fallback / 누락', () {
    test('빈 JSON → free + active + 빈 문자열 fallback', () {
      final snapshot = AppBillingDto.fromJson({});
      expect(snapshot.id, '');
      expect(snapshot.userId, '');
      expect(snapshot.plan, BillingPlan.free);
      expect(snapshot.status, BillingStatus.active);
      expect(snapshot.expiresAt, isNull);
      expect(snapshot.originalTransactionId, isNull);
      expect(snapshot.trialUsed, isFalse);
      expect(snapshot.source, 'unknown');
    });

    test('알 수 없는 tier → free fallback', () {
      final snapshot = AppBillingDto.fromJson({'tier': 'enterprise'});
      expect(snapshot.plan, BillingPlan.free);
    });

    test('invalid 날짜 → startedAt 은 now (UTC), expiresAt 은 null', () {
      final before = DateTime.now().toUtc();
      final snapshot = AppBillingDto.fromJson({
        'started_at': 'not-a-date',
        'expires_at': 'still-not-a-date',
      });
      final after = DateTime.now().toUtc();
      expect(snapshot.startedAt.isBefore(before), isFalse);
      expect(snapshot.startedAt.isAfter(after), isFalse);
      expect(snapshot.expiresAt, isNull);
    });

    test('trial_used 문자열 형태 ("true"/"false") 도 허용', () {
      expect(AppBillingDto.fromJson({'trial_used': 'true'}).trialUsed, isTrue);
      expect(
        AppBillingDto.fromJson({'trial_used': 'false'}).trialUsed,
        isFalse,
      );
    });
  });
}
