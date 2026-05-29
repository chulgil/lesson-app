// #415 R4 — Mock 결제 repository.
//
// DEV 계정 / 단위 테스트에서 사용. 기본값은 free + active.
// 컨스트럭터로 다른 스냅샷을 주입하면 그것을 반환한다.

import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/entities/billing_plan.dart';
import '../../domain/entities/billing_status.dart';
import '../../domain/entities/iap_validation_result.dart';
import '../../domain/entities/trial_activation_result.dart';
import '../../domain/repositories/app_billing_repository.dart';

class MockAppBillingRepository implements AppBillingRepository {
  MockAppBillingRepository({AppBillingSnapshot? initial})
    : _snapshot =
          initial ??
          AppBillingSnapshot(
            id: 'mock-billing-plan',
            userId: 'mock-user',
            plan: BillingPlan.free,
            status: BillingStatus.active,
            startedAt: DateTime.utc(2026, 1, 1),
            expiresAt: null,
            source: 'mock',
            originalTransactionId: null,
            trialUsed: false,
          );

  final AppBillingSnapshot _snapshot;

  @override
  Future<AppBillingSnapshot> fetchSnapshot() async => _snapshot;

  @override
  Future<TrialActivationResult> startTrial() async {
    return TrialActivationResult(
      success: true,
      message: 'mock_trial_started',
      planId: _snapshot.id,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 14)),
    );
  }

  @override
  Future<IapValidationResult> validatePurchase({
    required String platform,
    required String receipt,
    required String productId,
  }) async {
    return IapValidationResult(
      granted: true,
      message: 'mock_iap_granted',
      planId: _snapshot.id,
      tier: 'pro',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );
  }
}
