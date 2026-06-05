import 'billing_enums.dart';

/// 월간 강사 배분 명세 (1 강사 × 월 = 1 행).
///
/// Spec: docs/specs/web/academy/billing_settlement.md §6, §6.7.
/// BE: backend/app/models/academy_billing.py AcademySettlement.
///
/// 라이프사이클: draft → confirmed → transferred.
/// (academyId, teacherMemberId, periodYear, periodMonth) unique.
///
/// audit trail (§6.7):
/// - [teacherAcknowledgedAt]: 강사 확인 시각
/// - [teacherDisputeNote]: 강사 이의 메모
/// - [adjustmentLog]: 학원장 수정 이력 (영구 보존)
class AcademySettlement {
  AcademySettlement({
    required this.id,
    required this.academyId,
    required this.teacherMemberId,
    required this.periodYear,
    required this.periodMonth,
    required this.createdAt,
    this.calculatedAmount = 0,
    this.adjustedAmount,
    this.finalAmount = 0,
    this.status = SettlementStatus.draft,
    this.confirmedAt,
    this.transferredAt,
    this.pdfUrl,
    List<Map<String, dynamic>>? breakdown,
    this.teacherAcknowledgedAt,
    this.teacherDisputeNote,
    List<Map<String, dynamic>>? adjustmentLog,
    this.note,
  }) : breakdown = List.unmodifiable(breakdown ?? const []),
       adjustmentLog = List.unmodifiable(adjustmentLog ?? const []) {
    assert(
      periodMonth >= 1 && periodMonth <= 12,
      'periodMonth must be in 1..12',
    );
    assert(calculatedAmount >= 0, 'calculatedAmount must be >= 0');
    assert(finalAmount >= 0, 'finalAmount must be >= 0');
  }

  final String id;
  final String academyId;
  final String teacherMemberId;
  final int periodYear;
  final int periodMonth;

  /// 자동 계산 금액 (BillingRule + 출결/청구 기반).
  final int calculatedAmount;

  /// 학원장 수동 조정 금액. null = 미조정.
  final int? adjustedAmount;

  /// 최종 지급 금액 (== adjustedAmount ?? calculatedAmount).
  final int finalAmount;

  final SettlementStatus status;
  final DateTime? confirmedAt;
  final DateTime? transferredAt;
  final String? pdfUrl;

  /// 학생별 기여 내역 (강사 명세서용).
  /// 각 항목: `{"studentId": "...", "lessons": 8, "amount": 50000}` 등.
  final List<Map<String, dynamic>> breakdown;

  /// 강사 확인 시각 (§6.7 audit).
  final DateTime? teacherAcknowledgedAt;

  /// 강사 이의 메모 (§6.7).
  final String? teacherDisputeNote;

  /// 학원장 수정 이력 (영구 보존). 각 항목:
  /// `{"at": iso, "by": userId, "from": int, "to": int, "reason": "..."}`.
  final List<Map<String, dynamic>> adjustmentLog;

  final String? note;

  final DateTime createdAt;

  /// 자동 계산만 (draft) — 학원장이 아직 확정 안 함.
  bool get isDraft => status == SettlementStatus.draft;

  /// 학원장 확정 완료 + 송금 대기.
  bool get isAwaitingTransfer => status == SettlementStatus.confirmed;

  /// 송금 완료.
  bool get isTransferred => status == SettlementStatus.transferred;

  /// 강사가 명세 확인 완료.
  bool get isAcknowledged => teacherAcknowledgedAt != null;

  /// 강사가 이의 제기.
  bool get isDisputed =>
      teacherDisputeNote != null && teacherDisputeNote!.isNotEmpty;

  /// 학원장이 수동 조정한 명세.
  bool get isAdjusted => adjustedAmount != null;

  AcademySettlement copyWith({
    String? id,
    String? academyId,
    String? teacherMemberId,
    int? periodYear,
    int? periodMonth,
    int? calculatedAmount,
    int? adjustedAmount,
    int? finalAmount,
    SettlementStatus? status,
    DateTime? confirmedAt,
    DateTime? transferredAt,
    String? pdfUrl,
    List<Map<String, dynamic>>? breakdown,
    DateTime? teacherAcknowledgedAt,
    String? teacherDisputeNote,
    List<Map<String, dynamic>>? adjustmentLog,
    String? note,
    DateTime? createdAt,
  }) {
    return AcademySettlement(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      teacherMemberId: teacherMemberId ?? this.teacherMemberId,
      periodYear: periodYear ?? this.periodYear,
      periodMonth: periodMonth ?? this.periodMonth,
      calculatedAmount: calculatedAmount ?? this.calculatedAmount,
      adjustedAmount: adjustedAmount ?? this.adjustedAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      transferredAt: transferredAt ?? this.transferredAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      breakdown: breakdown ?? this.breakdown,
      teacherAcknowledgedAt:
          teacherAcknowledgedAt ?? this.teacherAcknowledgedAt,
      teacherDisputeNote: teacherDisputeNote ?? this.teacherDisputeNote,
      adjustmentLog: adjustmentLog ?? this.adjustmentLog,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademySettlement) return false;
    return id == other.id &&
        academyId == other.academyId &&
        teacherMemberId == other.teacherMemberId &&
        periodYear == other.periodYear &&
        periodMonth == other.periodMonth &&
        calculatedAmount == other.calculatedAmount &&
        adjustedAmount == other.adjustedAmount &&
        finalAmount == other.finalAmount &&
        status == other.status &&
        confirmedAt == other.confirmedAt &&
        transferredAt == other.transferredAt &&
        pdfUrl == other.pdfUrl &&
        breakdown.length == other.breakdown.length &&
        teacherAcknowledgedAt == other.teacherAcknowledgedAt &&
        teacherDisputeNote == other.teacherDisputeNote &&
        adjustmentLog.length == other.adjustmentLog.length &&
        note == other.note &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    teacherMemberId,
    periodYear,
    periodMonth,
    calculatedAmount,
    adjustedAmount,
    finalAmount,
    status,
    confirmedAt,
    transferredAt,
    breakdown.length,
    teacherAcknowledgedAt,
    teacherDisputeNote,
    adjustmentLog.length,
    createdAt,
  );
}
