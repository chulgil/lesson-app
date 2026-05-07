/// PaymentReceipt entity — issued when teacher confirms student payment.
///
/// Immutable snapshot: teacher/student names and subscription details are
/// captured at issuance time so the receipt remains accurate even if
/// profile data later changes.
class PaymentReceipt {
  final String id;

  /// Formatted receipt number: "2026-TXXXXXXXX-0001"
  final String receiptNumber;

  final String teacherId;
  final String studentId;

  /// Student display name at issuance time (snapshot).
  final String studentName;

  /// Human-readable subscription type: "체험" | "8회권" | "월정액"
  final String subscriptionType;

  /// Tuition amount in KRW (won).
  final int amount;

  /// Date teacher confirmed the bank transfer.
  final DateTime paymentDate;

  /// Lesson period label: "2026.05.01 ~ 2026.06.30"
  final String period;

  final DateTime createdAt;

  /// Presigned PDF URL (expires in 1 hour), null while PDF is being generated.
  final String? pdfUrl;

  const PaymentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.teacherId,
    required this.studentId,
    required this.studentName,
    required this.subscriptionType,
    required this.amount,
    required this.paymentDate,
    required this.period,
    required this.createdAt,
    this.pdfUrl,
  });

  PaymentReceipt copyWith({
    String? id,
    String? receiptNumber,
    String? teacherId,
    String? studentId,
    String? studentName,
    String? subscriptionType,
    int? amount,
    DateTime? paymentDate,
    String? period,
    DateTime? createdAt,
    String? pdfUrl,
  }) {
    return PaymentReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}
