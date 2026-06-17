/// 입금 확인 대기 항목 — #424.
///
/// 백엔드 `/api/v1/subscriptions/payment-pending` 응답 항목을 1:1 매핑.
class PendingPayment {
  const PendingPayment({
    required this.proposalId,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.daysSinceSent,
    required this.expiresAt,
    required this.canResend,
    required this.status,
    this.lessonCount,
    this.lastReminderSentAt,
  });

  final String proposalId;
  final String studentId;
  final String studentName;
  final int amount;
  final int? lessonCount;
  final int daysSinceSent;
  final DateTime expiresAt;
  final DateTime? lastReminderSentAt;
  final bool canResend;
  final String status; // pending | paymentNotified

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    return PendingPayment(
      proposalId: json['proposal_id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      lessonCount: (json['lesson_count'] as num?)?.toInt(),
      daysSinceSent: (json['days_since_sent'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      lastReminderSentAt: json['last_reminder_sent_at'] != null
          ? DateTime.parse(json['last_reminder_sent_at'] as String)
          : null,
      canResend: json['can_resend'] as bool? ?? true,
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// True when the home card should highlight this as the most urgent group.
  bool get isImminent => daysSinceSent >= 7;
  bool get isUrgent => daysSinceSent >= 3 && daysSinceSent < 7;
}
