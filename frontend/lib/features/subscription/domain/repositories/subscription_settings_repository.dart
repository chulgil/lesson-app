import '../entities/subscription_settings.dart';

/// Repository interface for subscription settings.
abstract class SubscriptionSettingsRepository {
  /// Get settings by teacher ID.
  Future<SubscriptionSettings?> getByTeacherId(String teacherId);

  /// Get settings by organization ID.
  Future<SubscriptionSettings?> getByOrganizationId(String organizationId);

  /// Create new settings.
  Future<SubscriptionSettings> create(SubscriptionSettings settings);

  /// Update settings.
  Future<SubscriptionSettings> update(SubscriptionSettings settings);

  /// Get or create default settings for a teacher.
  Future<SubscriptionSettings> getOrCreateForTeacher(String teacherId);
}
