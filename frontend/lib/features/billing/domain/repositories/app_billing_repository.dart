// #415 R4 — 앱 결제 repository 인터페이스.
//
// Phase A: fetchSnapshot.
// Phase C: startTrial, validatePurchase.

import '../entities/app_billing_snapshot.dart';
import '../entities/iap_validation_result.dart';
import '../entities/trial_activation_result.dart';

/// 앱 결제 정보를 가져오는 repository 계약.
abstract class AppBillingRepository {
  /// 현재 로그인된 사용자의 결제 스냅샷 조회.
  ///
  /// 백엔드 `GET /api/v1/me/billing/plan` 호출.
  /// 사용자가 plan row 가 없으면 [AppBillingSnapshot.freeFallback] 으로 fallback.
  Future<AppBillingSnapshot> fetchSnapshot();

  /// 14일 Pro 체험 시작.
  ///
  /// 백엔드 `POST /api/v1/me/billing/trial/start`.
  /// 이미 체험을 사용한 계정은 409 → success=false.
  Future<TrialActivationResult> startTrial();

  /// StoreKit2 / PlayBilling 영수증을 백엔드로 전송해 plan 활성화 요청.
  ///
  /// 백엔드 `POST /api/v1/me/billing/iap/validate`.
  /// [platform] 은 'apple' 또는 'google'.
  /// [receipt] 는 Apple = base64 영수증, Google = purchase token.
  Future<IapValidationResult> validatePurchase({
    required String platform,
    required String receipt,
    required String productId,
  });
}
