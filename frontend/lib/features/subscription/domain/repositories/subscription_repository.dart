import '../entities/pending_payment.dart';
import '../entities/subscription.dart';
import '../entities/subscription_usage.dart';

/// Repository interface for Subscription operations.
abstract class SubscriptionRepository {
  /// Get all subscriptions for a student.
  Future<List<Subscription>> getByStudentId(String studentId);

  /// Get active subscription for a membership.
  Future<Subscription?> getActiveByMembershipId(String membershipId);

  /// Get a single subscription by ID.
  Future<Subscription?> getById(String id);

  /// Create a new subscription.
  Future<Subscription> create(Subscription subscription);

  /// Update a subscription.
  Future<Subscription> update(Subscription subscription);

  /// Use one lesson (increment usedLessons by 1).
  /// Optionally provide lesson details for usage history.
  Future<Subscription> useLesson(
    String id, {
    String? lessonId,
    String? teacherName,
    String? instrument,
  });

  /// Use one reschedule allowance (increment usedRescheduleCount by 1).
  /// Returns the updated subscription.
  /// Throws if no reschedule allowance remaining.
  Future<Subscription> useReschedule(String id);

  /// Update subscription status.
  Future<void> updateStatus(String id, SubscriptionStatus status);

  /// Get subscriptions expiring soon (for notifications).
  Future<List<Subscription>> getExpiringSoon();

  /// Get expired subscriptions (status = expired or date passed).
  Future<List<Subscription>> getExpired();

  /// Get all active subscriptions for a teacher's students.
  Future<List<Subscription>> getByTeacherId(String teacherId);

  /// Watch subscriptions for a student (stream).
  Stream<List<Subscription>> watchByStudentId(String studentId);

  /// Watch active subscription for a membership (stream).
  Stream<Subscription?> watchActiveByMembershipId(String membershipId);

  // ═══════════════════════════════════════════════════════════════════
  // Payment
  // ═══════════════════════════════════════════════════════════════════

  /// Get unpaid (active but not payment-confirmed) subscriptions for a teacher.
  Future<List<Subscription>> getUnpaidSubscriptions(String teacherId);

  /// Confirm payment on a subscription.
  Future<Subscription> confirmPayment(
    String id, {
    SubscriptionPaymentMethod? paymentMethod,
  });

  /// Undo a payment confirmation within the 24h window — #426.
  ///
  /// Server rejects with 400/409 if:
  /// - payment is not yet confirmed
  /// - first lesson has already been consumed (`firstLessonConsumedAt` set)
  /// - 24h window since `paymentConfirmedAt` has elapsed
  Future<Subscription> undoConfirmPayment(String id);

  // ═══════════════════════════════════════════════════════════════════
  // Payment-pending dashboard — #424
  // ═══════════════════════════════════════════════════════════════════

  /// List of subscription-proposals awaiting payment confirmation.
  Future<List<PendingPayment>> getPendingPayments();

  /// Lightweight count for the home card.
  Future<int> getPendingPaymentCount();

  /// Resend the payment reminder to the student (30-minute cooldown server-side).
  Future<void> resendProposalReminder(String proposalId);

  /// Revoke a proposal (teacher-side correction).
  Future<void> revokeProposal(String proposalId);

  // ═══════════════════════════════════════════════════════════════════
  // Usage History
  // ═══════════════════════════════════════════════════════════════════

  /// Get usage history for a subscription.
  Future<List<SubscriptionUsage>> getUsageHistory(String subscriptionId);

  /// Add a usage record.
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage);
}
