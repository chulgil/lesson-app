// #415 R4 Phase C — IAP 영수증 검증 결과.
//
// 백엔드 POST /me/billing/iap/validate 응답.
//
// granted=true 면 plan 이 즉시 활성화됨. granted=false 는 audit 저장만 되고
// 실제 Apple/Google validator 통합 (Phase D) 까지 대기 상태.

class IapValidationResult {
  const IapValidationResult({
    required this.granted,
    required this.message,
    this.planId,
    this.tier,
    this.expiresAt,
  });

  /// true = plan 즉시 활성화, false = pending (audit 저장만).
  final bool granted;

  final String message;
  final String? planId;
  final String? tier;
  final DateTime? expiresAt;
}
