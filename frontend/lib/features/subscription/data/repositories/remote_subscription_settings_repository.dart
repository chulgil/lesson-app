import '../../../../core/network/api_client.dart';
import '../../domain/entities/subscription_settings.dart';
import '../../domain/repositories/subscription_settings_repository.dart';

/// Remote implementation of [SubscriptionSettingsRepository] using FastAPI backend.
class RemoteSubscriptionSettingsRepository
    implements SubscriptionSettingsRepository {
  final ApiClient _apiClient;

  RemoteSubscriptionSettingsRepository(this._apiClient);

  @override
  Future<SubscriptionSettings?> getByTeacherId(String teacherId) async {
    try {
      final response = await _apiClient.get(
        '/subscription-settings/teacher/$teacherId',
      );
      return SubscriptionSettings.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SubscriptionSettings?> getByOrganizationId(
      String organizationId) async {
    try {
      final response = await _apiClient.get(
        '/subscription-settings/organization/$organizationId',
      );
      return SubscriptionSettings.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SubscriptionSettings> create(SubscriptionSettings settings) async {
    final response = await _apiClient.post(
      '/subscription-settings',
      data: settings.toJson(),
    );
    return SubscriptionSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<SubscriptionSettings> update(SubscriptionSettings settings) async {
    final response = await _apiClient.put(
      '/subscription-settings/${settings.id}',
      data: settings.toJson(),
    );
    return SubscriptionSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<SubscriptionSettings> getOrCreateForTeacher(
      String teacherId) async {
    final existing = await getByTeacherId(teacherId);
    if (existing != null) return existing;

    final defaultSettings =
        SubscriptionSettings.defaultForTeacher(teacherId);
    return create(defaultSettings);
  }
}
