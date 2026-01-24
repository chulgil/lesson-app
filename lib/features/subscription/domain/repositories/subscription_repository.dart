import '../entities/subscription.dart';

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
  Future<Subscription> useLesson(String id);

  /// Update subscription status.
  Future<void> updateStatus(String id, SubscriptionStatus status);

  /// Get subscriptions expiring soon (for notifications).
  Future<List<Subscription>> getExpiringSoon();

  /// Get all active subscriptions for a teacher's students.
  Future<List<Subscription>> getByTeacherId(String teacherId);

  /// Watch subscriptions for a student (stream).
  Stream<List<Subscription>> watchByStudentId(String studentId);

  /// Watch active subscription for a membership (stream).
  Stream<Subscription?> watchActiveByMembershipId(String membershipId);
}
