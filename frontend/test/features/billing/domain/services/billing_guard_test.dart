// #415 R4 — BillingGuard 순수 로직 5 시나리오.
//
// spec/paywall_spec.md §3 기준.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/billing/domain/entities/app_billing_snapshot.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';
import 'package:lessonaza/features/billing/domain/services/billing_guard.dart';

AppBillingSnapshot _snapshot({
  required BillingPlan plan,
  required BillingStatus status,
}) {
  return AppBillingSnapshot(
    id: 'test',
    userId: 'user-1',
    plan: plan,
    status: status,
    startedAt: DateTime.utc(2026, 1, 1),
    expiresAt:
        status == BillingStatus.expired ? DateTime.utc(2025, 12, 1) : null,
    source: 'test',
    originalTransactionId: null,
    trialUsed: false,
  );
}

void main() {
  const guard = BillingGuard();

  group('BillingGuard.checkStudentLimit — free plan', () {
    test('under limit (4명) → allowed', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.free,
          status: BillingStatus.active,
        ),
        currentStudentCount: 4,
      );
      expect(decision.allowed, isTrue);
      expect(decision.blocked, isFalse);
      expect(decision.reason, LimitReason.withinLimit);
    });

    test('at limit (5명) → blocked freeLimitReached', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.free,
          status: BillingStatus.active,
        ),
        currentStudentCount: 5,
      );
      expect(decision.allowed, isFalse);
      expect(decision.blocked, isTrue);
      expect(decision.reason, LimitReason.freeLimitReached);
    });

    test('over limit (10명, 데이터 정합성 깨진 케이스) → blocked', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.free,
          status: BillingStatus.active,
        ),
        currentStudentCount: 10,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, LimitReason.freeLimitReached);
    });
  });

  group('BillingGuard.checkStudentLimit — unlimited plans', () {
    test('pro + active → allowed regardless of count', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.pro,
          status: BillingStatus.active,
        ),
        currentStudentCount: 100,
      );
      expect(decision.allowed, isTrue);
      expect(decision.reason, LimitReason.withinLimit);
    });

    test('pro + trial → allowed (체험 기간도 무제한)', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(plan: BillingPlan.pro, status: BillingStatus.trial),
        currentStudentCount: 50,
      );
      expect(decision.allowed, isTrue);
      expect(decision.reason, LimitReason.withinLimit);
    });

    test('studio + active → allowed', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.studio,
          status: BillingStatus.active,
        ),
        currentStudentCount: 200,
      );
      expect(decision.allowed, isTrue);
    });

    test('lifetime + active → allowed', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.lifetime,
          status: BillingStatus.active,
        ),
        currentStudentCount: 999,
      );
      expect(decision.allowed, isTrue);
    });
  });

  group('BillingGuard.checkStudentLimit — expired', () {
    test('pro + expired → blocked planExpired (7일 유예 종료)', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.pro,
          status: BillingStatus.expired,
        ),
        currentStudentCount: 3,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, LimitReason.planExpired);
    });

    test('free + expired → blocked planExpired (이론적, 백엔드 강제 free=active)', () {
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.free,
          status: BillingStatus.expired,
        ),
        currentStudentCount: 0,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, LimitReason.planExpired);
    });

    test('cancelled (현재 기간 active 와 동일) → allowed (다음 갱신 차단, 현재 기간 유지)', () {
      // BillingStatus.cancelled: isActiveOrTrial=true, 현재 기간 pro 혜택 유지.
      // 만료는 BillingStatus.expired.
      final decision = guard.checkStudentLimit(
        snapshot: _snapshot(
          plan: BillingPlan.pro,
          status: BillingStatus.cancelled,
        ),
        currentStudentCount: 3,
      );
      expect(decision.allowed, isTrue);
      expect(decision.reason, LimitReason.withinLimit);
    });
  });

  group(
    'BillingGuard.requireTier — Pro 진입 (free/pro/studio/lifetime × 4 status)',
    () {
      test('free + active → blocked tierTooLow', () {
        final decision = guard.requireTier(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          required: TierRequirement.pro,
        );
        expect(decision.allowed, isFalse);
        expect(decision.blocked, isTrue);
        expect(decision.reason, FeatureGateReason.tierTooLow);
      });

      test('pro + active → allowed', () {
        final decision = guard.requireTier(
          snapshot: _snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.active,
          ),
          required: TierRequirement.pro,
        );
        expect(decision.allowed, isTrue);
        expect(decision.reason, FeatureGateReason.allowed);
      });

      test('pro + trial → allowed (체험 기간도 Pro 기능 사용)', () {
        final decision = guard.requireTier(
          snapshot: _snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.trial,
          ),
          required: TierRequirement.pro,
        );
        expect(decision.allowed, isTrue);
      });

      test('pro + expired → blocked planExpired (tier 는 충분하지만 만료)', () {
        final decision = guard.requireTier(
          snapshot: _snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.expired,
          ),
          required: TierRequirement.pro,
        );
        expect(decision.allowed, isFalse);
        expect(decision.reason, FeatureGateReason.planExpired);
      });

      test('pro + cancelled → allowed (현재 기간 active 유지, 만료는 expired)', () {
        // BillingStatus.cancelled: isActiveOrTrial=true — 다음 갱신만 차단,
        // 현재 기간 pro 혜택은 유지. 실제 차단은 BillingStatus.expired.
        final decision = guard.requireTier(
          snapshot: _snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.cancelled,
          ),
          required: TierRequirement.pro,
        );
        expect(decision.allowed, isTrue);
        expect(decision.reason, FeatureGateReason.allowed);
      });

      test('studio + active → allowed (상위 tier)', () {
        final decision = guard.requireTier(
          snapshot: _snapshot(
            plan: BillingPlan.studio,
            status: BillingStatus.active,
          ),
          required: TierRequirement.pro,
        );
        expect(decision.allowed, isTrue);
      });

      test('lifetime + active → allowed (영구 Pro)', () {
        final decision = guard.requireTier(
          snapshot: _snapshot(
            plan: BillingPlan.lifetime,
            status: BillingStatus.active,
          ),
          required: TierRequirement.pro,
        );
        expect(decision.allowed, isTrue);
      });
    },
  );

  group('BillingGuard.requireTier — Studio 진입 (학원 전용 기능)', () {
    test('free → blocked tierTooLow', () {
      final decision = guard.requireTier(
        snapshot: _snapshot(
          plan: BillingPlan.free,
          status: BillingStatus.active,
        ),
        required: TierRequirement.studio,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, FeatureGateReason.tierTooLow);
    });

    test('pro + active → blocked tierTooLow (Pro 로도 Studio 기능 진입 불가)', () {
      final decision = guard.requireTier(
        snapshot: _snapshot(
          plan: BillingPlan.pro,
          status: BillingStatus.active,
        ),
        required: TierRequirement.studio,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, FeatureGateReason.tierTooLow);
    });

    test('studio + active → allowed', () {
      final decision = guard.requireTier(
        snapshot: _snapshot(
          plan: BillingPlan.studio,
          status: BillingStatus.active,
        ),
        required: TierRequirement.studio,
      );
      expect(decision.allowed, isTrue);
    });

    test('studio + trial → allowed', () {
      final decision = guard.requireTier(
        snapshot: _snapshot(
          plan: BillingPlan.studio,
          status: BillingStatus.trial,
        ),
        required: TierRequirement.studio,
      );
      expect(decision.allowed, isTrue);
    });

    test('studio + expired → blocked planExpired', () {
      final decision = guard.requireTier(
        snapshot: _snapshot(
          plan: BillingPlan.studio,
          status: BillingStatus.expired,
        ),
        required: TierRequirement.studio,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, FeatureGateReason.planExpired);
    });

    test('lifetime → blocked tierTooLow (Lifetime 은 Pro 영구이지 Studio 아님)', () {
      final decision = guard.requireTier(
        snapshot: _snapshot(
          plan: BillingPlan.lifetime,
          status: BillingStatus.active,
        ),
        required: TierRequirement.studio,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, FeatureGateReason.tierTooLow);
    });
  });

  group('BillingGuard.effectiveStudentLimit', () {
    test('free → 5', () {
      expect(
        guard.effectiveStudentLimit(
          _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
        ),
        freeStudentLimit,
      );
    });

    test('pro/studio/lifetime → null (무제한)', () {
      for (final plan in [
        BillingPlan.pro,
        BillingPlan.studio,
        BillingPlan.lifetime,
      ]) {
        expect(
          guard.effectiveStudentLimit(
            _snapshot(plan: plan, status: BillingStatus.active),
          ),
          isNull,
        );
      }
    });
  });
}
