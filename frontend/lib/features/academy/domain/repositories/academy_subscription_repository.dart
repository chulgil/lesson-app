import '../entities/academy_subscription.dart';

/// AcademySubscriptionRepository — 학원 귀속 수강권 관리
abstract class AcademySubscriptionRepository {
  /// List subscriptions for a student
  Future<List<AcademySubscription>> listByStudent(String studentId);

  /// Get subscription by ID
  Future<AcademySubscription?> getById(String id);
}
