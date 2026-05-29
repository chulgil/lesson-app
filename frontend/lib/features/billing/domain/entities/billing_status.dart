// #415 R4 — 결제 플랜 활성 상태.
//
// 백엔드 `BillingPlanResponse.status` 와 1:1.

/// 결제 플랜의 활성 상태.
///
/// - [active]: 결제 완료, 사용 중.
/// - [trial]: 14일 무료 체험 중 (tier=pro, status=trial 조합).
/// - [expired]: 만료 (7일 유예 → free 강등).
/// - [cancelled]: 사용자가 다음 갱신 차단함 (현재 기간은 유지).
enum BillingStatus {
  active,
  trial,
  expired,
  cancelled;

  static BillingStatus fromWire(String? value) {
    switch (value) {
      case 'trial':
        return BillingStatus.trial;
      case 'expired':
        return BillingStatus.expired;
      case 'cancelled':
        return BillingStatus.cancelled;
      case 'active':
      default:
        return BillingStatus.active;
    }
  }

  String toWire() => name;
}
