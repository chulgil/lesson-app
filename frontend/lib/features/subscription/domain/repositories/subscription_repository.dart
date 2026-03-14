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

  // ═══════════════════════════════════════════════════════════════════
  // Usage History
  // ═══════════════════════════════════════════════════════════════════

  /// Get usage history for a subscription.
  Future<List<SubscriptionUsage>> getUsageHistory(String subscriptionId);

  /// Add a usage record.
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage);
}
