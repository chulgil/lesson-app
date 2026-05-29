// #415 R4 — 앱 결제 플랜 enum.
//
// 백엔드 BillingPlanResponse.tier 와 1:1. spec/paywall_spec.md §1 의
// `trial_pro` 는 별도 tier 가 아니라 (tier=pro, status=trial) 로 표현된다.
// `lifetime` 은 M5 후속 SKU 라 본 enum 에 포함하지만 백엔드 enum 에는 아직 없음.

/// 백엔드 `BillingPlanResponse.tier` 와 매핑되는 결제 플랜.
enum BillingPlan {
  /// 무료 — 학생 5명 한도.
  free,

  /// Pro — 학생 무제한.
  pro,

  /// Studio — 학원 다중 강사 + 통계 대시보드.
  studio,

  /// Lifetime — M5 출시 후 90일 한정 얼리어답터 (백엔드 enum 미포함).
  lifetime;

  /// 백엔드 응답 문자열 → enum.
  ///
  /// 알 수 없는 값은 [BillingPlan.free] 로 fallback (서버 신규 plan 도입 시 안전).
  static BillingPlan fromWire(String? value) {
    switch (value) {
      case 'pro':
        return BillingPlan.pro;
      case 'studio':
        return BillingPlan.studio;
      case 'lifetime':
        return BillingPlan.lifetime;
      case 'free':
      default:
        return BillingPlan.free;
    }
  }

  /// enum → 백엔드 전송용 문자열.
  String toWire() => name;
}
