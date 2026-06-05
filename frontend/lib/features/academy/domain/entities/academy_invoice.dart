import 'billing_enums.dart';

/// 월간 학생 청구서 (1 학생 × 월 = 1 행).
///
/// Spec: docs/specs/web/academy/billing_settlement.md §3.
/// BE: backend/app/models/academy_billing.py AcademyInvoice.
///
/// (academyId, academyStudentId, periodYear, periodMonth) unique.
class AcademyInvoice {
  AcademyInvoice({
    required this.id,
    required this.academyId,
    required this.academyStudentId,
    required this.periodYear,
    required this.periodMonth,
    required this.createdAt,
    this.issuedAt,
    this.sentAt,
    this.baseAmount = 0,
    this.extraAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.status = InvoiceStatus.draft,
    this.dueDate,
    this.pdfUrl,
    List<Map<String, dynamic>>? lineItems,
    this.taxInvoiceIssued = false,
    this.cashReceiptIssued = false,
    this.cashReceiptIssuedAt,
    this.cashReceiptRef,
    this.cashReceiptTargetNo,
  }) : lineItems = List.unmodifiable(lineItems ?? const []) {
    assert(
      periodMonth >= 1 && periodMonth <= 12,
      'periodMonth must be in 1..12',
    );
    assert(totalAmount >= 0, 'totalAmount must be >= 0');
  }

  final String id;
  final String academyId;
  final String academyStudentId;
  final int periodYear;
  final int periodMonth;
  final DateTime? issuedAt;
  final DateTime? sentAt;
  final int baseAmount;
  final int extraAmount;
  final int discountAmount;
  final int totalAmount;
  final InvoiceStatus status;
  final DateTime? dueDate;
  final String? pdfUrl;

  /// 청구 항목 (월 수강료 / 보충 / 할인 등 라인별 breakdown).
  final List<Map<String, dynamic>> lineItems;

  final bool taxInvoiceIssued;
  final bool cashReceiptIssued;
  final DateTime? cashReceiptIssuedAt;
  final String? cashReceiptRef;
  final String? cashReceiptTargetNo;

  final DateTime createdAt;

  /// 미수금 상태 (sent / overdue).
  bool get isOutstanding => status.isOutstanding;

  /// 발급 가능 상태 (draft).
  bool get isDraft => status == InvoiceStatus.draft;

  /// 만료 여부 (asOf 시점 기준, dueDate 가 있어야).
  bool isPastDueAt(DateTime asOf) {
    if (dueDate == null) return false;
    return asOf.isAfter(dueDate!);
  }

  /// 회계 검산: base + extra - discount == total.
  bool get hasConsistentTotal =>
      baseAmount + extraAmount - discountAmount == totalAmount;

  AcademyInvoice copyWith({
    String? id,
    String? academyId,
    String? academyStudentId,
    int? periodYear,
    int? periodMonth,
    DateTime? issuedAt,
    DateTime? sentAt,
    int? baseAmount,
    int? extraAmount,
    int? discountAmount,
    int? totalAmount,
    InvoiceStatus? status,
    DateTime? dueDate,
    String? pdfUrl,
    List<Map<String, dynamic>>? lineItems,
    bool? taxInvoiceIssued,
    bool? cashReceiptIssued,
    DateTime? cashReceiptIssuedAt,
    String? cashReceiptRef,
    String? cashReceiptTargetNo,
    DateTime? createdAt,
  }) {
    return AcademyInvoice(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      academyStudentId: academyStudentId ?? this.academyStudentId,
      periodYear: periodYear ?? this.periodYear,
      periodMonth: periodMonth ?? this.periodMonth,
      issuedAt: issuedAt ?? this.issuedAt,
      sentAt: sentAt ?? this.sentAt,
      baseAmount: baseAmount ?? this.baseAmount,
      extraAmount: extraAmount ?? this.extraAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      lineItems: lineItems ?? this.lineItems,
      taxInvoiceIssued: taxInvoiceIssued ?? this.taxInvoiceIssued,
      cashReceiptIssued: cashReceiptIssued ?? this.cashReceiptIssued,
      cashReceiptIssuedAt: cashReceiptIssuedAt ?? this.cashReceiptIssuedAt,
      cashReceiptRef: cashReceiptRef ?? this.cashReceiptRef,
      cashReceiptTargetNo: cashReceiptTargetNo ?? this.cashReceiptTargetNo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademyInvoice) return false;
    return id == other.id &&
        academyId == other.academyId &&
        academyStudentId == other.academyStudentId &&
        periodYear == other.periodYear &&
        periodMonth == other.periodMonth &&
        issuedAt == other.issuedAt &&
        sentAt == other.sentAt &&
        baseAmount == other.baseAmount &&
        extraAmount == other.extraAmount &&
        discountAmount == other.discountAmount &&
        totalAmount == other.totalAmount &&
        status == other.status &&
        dueDate == other.dueDate &&
        pdfUrl == other.pdfUrl &&
        lineItems.length == other.lineItems.length &&
        taxInvoiceIssued == other.taxInvoiceIssued &&
        cashReceiptIssued == other.cashReceiptIssued &&
        cashReceiptIssuedAt == other.cashReceiptIssuedAt &&
        cashReceiptRef == other.cashReceiptRef &&
        cashReceiptTargetNo == other.cashReceiptTargetNo &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    academyStudentId,
    periodYear,
    periodMonth,
    baseAmount,
    extraAmount,
    discountAmount,
    totalAmount,
    status,
    dueDate,
    lineItems.length,
    Object.hash(
      taxInvoiceIssued,
      cashReceiptIssued,
      cashReceiptIssuedAt,
      cashReceiptRef,
      cashReceiptTargetNo,
    ),
    createdAt,
  );
}
