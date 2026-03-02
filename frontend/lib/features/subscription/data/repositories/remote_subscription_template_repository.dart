import '../../../../core/network/api_client.dart';
import '../../domain/entities/subscription_template.dart';
import '../../domain/repositories/subscription_template_repository.dart';

/// Remote implementation of [SubscriptionTemplateRepository] using FastAPI backend.
class RemoteSubscriptionTemplateRepository
    implements SubscriptionTemplateRepository {
  final ApiClient _apiClient;

  RemoteSubscriptionTemplateRepository(this._apiClient);

  @override
  Future<List<SubscriptionTemplate>> getByTeacher(String teacherId) async {
    final response = await _apiClient.get('/subscriptions-templates');
    final items = response.data as List<dynamic>;
    return items
        .map((e) => SubscriptionTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SubscriptionTemplate>> getByAcademy(String academyId) async {
    final response = await _apiClient.get(
      '/subscriptions-templates',
      queryParameters: {'academy_id': academyId},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => SubscriptionTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SubscriptionTemplate?> getById(String id) async {
    final response = await _apiClient.get('/subscriptions-templates/$id');
    return SubscriptionTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<SubscriptionTemplate>> getActiveByTeacher(
    String teacherId,
  ) async {
    final response = await _apiClient.get(
      '/subscriptions-templates',
      queryParameters: {'active': 'true'},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => SubscriptionTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SubscriptionTemplate>> getActiveByAcademy(
    String academyId,
  ) async {
    final response = await _apiClient.get(
      '/subscriptions-templates',
      queryParameters: {'academy_id': academyId, 'active': 'true'},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => SubscriptionTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SubscriptionTemplate>> getAutoProposalTemplates(
    String teacherId,
  ) async {
    final response = await _apiClient.get(
      '/subscriptions-templates',
      queryParameters: {'active': 'true', 'auto_proposal': 'true'},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => SubscriptionTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SubscriptionTemplate> create(SubscriptionTemplate template) async {
    final response = await _apiClient.post(
      '/subscriptions-templates',
      data: template.toJson(),
    );
    return SubscriptionTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionTemplate> update(SubscriptionTemplate template) async {
    final response = await _apiClient.put(
      '/subscriptions-templates/${template.id}',
      data: template.toJson(),
    );
    return SubscriptionTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/subscriptions-templates/$id');
  }

  @override
  Future<SubscriptionTemplate> toggleActive(String id) async {
    final response = await _apiClient.patch(
      '/subscriptions-templates/$id/toggle-active',
    );
    return SubscriptionTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    await _apiClient.patch(
      '/subscriptions-templates/reorder',
      data: {'ordered_ids': orderedIds},
    );
  }
}
