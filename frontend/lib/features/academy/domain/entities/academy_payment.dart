import 'billing_enums.dart';

/// 수금 1건 (1 청구서 × N 수금 — 부분 수금 지원).
///
/// Spec: docs/specs/web/academy/billing_settlement.md §4.
/// BE: backend/app/models/academy_billing.py AcademyPayment.
///
/// 학원장이 수기 마킹 (앱이 결제 처리 X — payment_architecture A' 흐름).
class AcademyPayment {
  AcademyPayment({
    required this.id,
    required this.academyId,
    required this.invoiceId,
    required this.paidAmount,
    required this.paidAt,
    required this.confirmedByUserId,
    required this.createdAt,
    this.method = PaymentMethod.transfer,
    this.source = PaymentSource.manual,
    this.bankTxRef,
    this.depositorRaw,
    this.note,
  }) {
    assert(paidAmount > 0, 'paidAmount must be > 0 (BE CheckConstraint)');
  }

  final String id;
  final String academyId;
  final String invoiceId;
  final int paidAmount;
  final DateTime paidAt;
  final PaymentMethod method;
  final String confirmedByUserId;
  final PaymentSource source;

  /// 은행 CSV 임포트 시 거래번호 (audit).
  final String? bankTxRef;

  /// 입금자 원문 (fuzzy 매칭 audit, payment_matching_spec).
  final String? depositorRaw;

  final String? note;

  final DateTime createdAt;

  /// CSV / fuzzy 매칭 audit 가 가능한지 여부.
  bool get hasMatchingAudit => bankTxRef != null || depositorRaw != null;

  AcademyPayment copyWith({
    String? id,
    String? academyId,
    String? invoiceId,
    int? paidAmount,
    DateTime? paidAt,
    PaymentMethod? method,
    String? confirmedByUserId,
    PaymentSource? source,
    String? bankTxRef,
    String? depositorRaw,
    String? note,
    DateTime? createdAt,
  }) {
    return AcademyPayment(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      invoiceId: invoiceId ?? this.invoiceId,
      paidAmount: paidAmount ?? this.paidAmount,
      paidAt: paidAt ?? this.paidAt,
      method: method ?? this.method,
      confirmedByUserId: confirmedByUserId ?? this.confirmedByUserId,
      source: source ?? this.source,
      bankTxRef: bankTxRef ?? this.bankTxRef,
      depositorRaw: depositorRaw ?? this.depositorRaw,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademyPayment) return false;
    return id == other.id &&
        academyId == other.academyId &&
        invoiceId == other.invoiceId &&
        paidAmount == other.paidAmount &&
        paidAt == other.paidAt &&
        method == other.method &&
        confirmedByUserId == other.confirmedByUserId &&
        source == other.source &&
        bankTxRef == other.bankTxRef &&
        depositorRaw == other.depositorRaw &&
        note == other.note &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    invoiceId,
    paidAmount,
    paidAt,
    method,
    confirmedByUserId,
    source,
    bankTxRef,
    depositorRaw,
    note,
    createdAt,
  );
}
