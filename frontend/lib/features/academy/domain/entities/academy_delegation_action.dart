/// 위임 활성 기간 동안 delegatee 가 수행한 액션 로그 (audit).
///
/// Spec: docs/specs/web/academy/temporary_delegation_spec.md §7.1.
/// BE: backend/app/models/academy_governance.py AcademyDelegationAction.
///
/// 임시 위임 종료 후 학원장이 검토 — `ownerReviewedAt` 마킹.
/// 영구 보존.
class AcademyDelegationAction {
  const AcademyDelegationAction({
    required this.id,
    required this.delegationId,
    required this.performedAt,
    required this.performedByUserId,
    required this.permissionUsed,
    required this.endpoint,
    required this.responseStatus,
    this.targetResourceId,
    this.requestSummary,
    this.ownerReviewedAt,
    this.ownerDisputeNote,
  });

  final String id;
  final String delegationId;
  final DateTime performedAt;
  final String performedByUserId;

  /// 사용된 권한 항목 (예: "billing.collect").
  final String permissionUsed;

  /// 호출된 endpoint (예: "POST /billing/payments").
  final String endpoint;

  /// 호출 대상 리소스 id (예: invoice_id, payment_id).
  final String? targetResourceId;

  /// 요청 핵심 정보 (PII 제외).
  final Map<String, dynamic>? requestSummary;

  /// HTTP 응답 상태 코드.
  final int responseStatus;

  /// 학원장 사후 검토 시각.
  final DateTime? ownerReviewedAt;

  /// 학원장 이의 메모 (검토 후 분쟁 표식).
  final String? ownerDisputeNote;

  /// 학원장 사후 검토 완료 여부.
  bool get isReviewed => ownerReviewedAt != null;

  /// 학원장 이의 제기 여부.
  bool get isDisputed =>
      ownerDisputeNote != null && ownerDisputeNote!.isNotEmpty;

  AcademyDelegationAction copyWith({
    String? id,
    String? delegationId,
    DateTime? performedAt,
    String? performedByUserId,
    String? permissionUsed,
    String? endpoint,
    String? targetResourceId,
    Map<String, dynamic>? requestSummary,
    int? responseStatus,
    DateTime? ownerReviewedAt,
    String? ownerDisputeNote,
  }) {
    return AcademyDelegationAction(
      id: id ?? this.id,
      delegationId: delegationId ?? this.delegationId,
      performedAt: performedAt ?? this.performedAt,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      permissionUsed: permissionUsed ?? this.permissionUsed,
      endpoint: endpoint ?? this.endpoint,
      targetResourceId: targetResourceId ?? this.targetResourceId,
      requestSummary: requestSummary ?? this.requestSummary,
      responseStatus: responseStatus ?? this.responseStatus,
      ownerReviewedAt: ownerReviewedAt ?? this.ownerReviewedAt,
      ownerDisputeNote: ownerDisputeNote ?? this.ownerDisputeNote,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademyDelegationAction) return false;
    if (!_mapEquals(requestSummary, other.requestSummary)) return false;
    return id == other.id &&
        delegationId == other.delegationId &&
        performedAt == other.performedAt &&
        performedByUserId == other.performedByUserId &&
        permissionUsed == other.permissionUsed &&
        endpoint == other.endpoint &&
        targetResourceId == other.targetResourceId &&
        responseStatus == other.responseStatus &&
        ownerReviewedAt == other.ownerReviewedAt &&
        ownerDisputeNote == other.ownerDisputeNote;
  }

  @override
  int get hashCode => Object.hash(
    id,
    delegationId,
    performedAt,
    performedByUserId,
    permissionUsed,
    endpoint,
    targetResourceId,
    responseStatus,
    ownerReviewedAt,
    ownerDisputeNote,
    requestSummary?.length ?? 0,
  );

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
