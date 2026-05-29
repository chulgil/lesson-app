// #415 R4 — 앱 결제 repository 인터페이스.
//
// Phase A 범위: fetchSnapshot 만 정의. Trial 시작/IAP 검증은 Phase B/C 에서 추가.

import '../entities/app_billing_snapshot.dart';

/// 앱 결제 정보를 가져오는 repository 계약.
abstract class AppBillingRepository {
  /// 현재 로그인된 사용자의 결제 스냅샷 조회.
  ///
  /// 백엔드 `GET /api/v1/me/billing/plan` 호출.
  /// 사용자가 plan row 가 없으면 [AppBillingSnapshot.freeFallback] 으로 fallback.
  Future<AppBillingSnapshot> fetchSnapshot();
}
