/// Subscription refund request entity (#1271).
///
/// Spec: GitHub issue #1271 (approved 2026-08-14). External bank transfer
/// only — no in-app payment/PG refund flow.
///
/// Pure value type — no display strings / no presentation imports / no Hive.
library;

/// Refund request lifecycle status.
///
/// `requested` -> `completed` | `rejected`. Terminal once resolved — no
/// reopening (a new request must be created for a fresh attempt).
enum RefundRequestStatus { requested, completed, rejected }

/// A student's refund request for a subscription with remaining lessons.
///
/// The account fields carry the student's withdrawal-destination bank
/// account (distinct from [BankAccount] in the profile feature, which is
/// the teacher's own settlement account). Masking for display is a
/// repository-level privacy concern (data-privacy.md Level 1) — this entity
/// always carries whatever the repository chose to return.
class RefundRequest {
  final String id;
  final String subscriptionId;
  final String studentId;
  final String teacherId;

  final String bankName;
  final String accountNumber;
  final String accountHolder;

  /// Optional free-text reason from the student.
  final String? reason;

  final RefundRequestStatus status;

  /// Amount actually transferred, set when the teacher completes the
  /// request. Null while `requested` or when `rejected`.
  final int? processedAmount;

  /// Set when the teacher rejects the request.
  final String? rejectReason;

  final DateTime requestedAt;
  final DateTime? processedAt;

  const RefundRequest({
    required this.id,
    required this.subscriptionId,
    required this.studentId,
    required this.teacherId,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.reason,
    this.status = RefundRequestStatus.requested,
    this.processedAmount,
    this.rejectReason,
    required this.requestedAt,
    this.processedAt,
  });

  bool get isRequested => status == RefundRequestStatus.requested;
  bool get isCompleted => status == RefundRequestStatus.completed;
  bool get isRejected => status == RefundRequestStatus.rejected;

  /// Whether the teacher's account info should be shown unmasked — only
  /// while the request is still actionable (spec: "선생님은 처리 가능한
  /// 동안 비마스킹").
  bool get isActionable => isRequested;

  RefundRequest copyWith({
    String? id,
    String? subscriptionId,
    String? studentId,
    String? teacherId,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    String? reason,
    RefundRequestStatus? status,
    int? processedAmount,
    String? rejectReason,
    DateTime? requestedAt,
    DateTime? processedAt,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      processedAmount: processedAmount ?? this.processedAmount,
      rejectReason: rejectReason ?? this.rejectReason,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
