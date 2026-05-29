// #415 R4 Phase C — Trial 활성화 결과.
//
// 백엔드 POST /me/billing/trial/start 응답.

class TrialActivationResult {
  const TrialActivationResult({
    required this.success,
    required this.message,
    this.planId,
    this.expiresAt,
  });

  /// 백엔드 성공 응답 (200) — plan 이 trial 로 활성화됨.
  final bool success;

  /// 사용자 노출 문구 (또는 에러 사유).
  final String message;

  final String? planId;
  final DateTime? expiresAt;
}
