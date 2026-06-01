import '../../../../core/network/api_client.dart';
import '../../domain/entities/feedback_template.dart';
import '../../domain/repositories/feedback_template_repository.dart';

class RemoteFeedbackTemplateRepository implements FeedbackTemplateRepository {
  RemoteFeedbackTemplateRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<FeedbackTemplate>> getTemplates(String teacherId) => _list();

  @override
  Future<List<FeedbackTemplate>> getTemplatesByCategory(
    String teacherId,
    FeedbackCategory category,
  ) {
    return _list({'category': category.name});
  }

  @override
  Future<List<FeedbackTemplate>> getTemplatesByTag(
    String teacherId,
    String tag,
  ) {
    return _list({'tag': tag});
  }

  @override
  Future<List<FeedbackTemplate>> searchTemplates(
    String teacherId,
    String query,
  ) {
    return _list({'query': query});
  }

  @override
  Future<List<FeedbackTemplate>> getFrequentlyUsed(
    String teacherId, {
    int limit = 3,
  }) {
    return _list({'frequent': true, 'limit': limit});
  }

  @override
  Future<FeedbackTemplate> createTemplate(FeedbackTemplate template) async {
    final data =
        template.toJson()
          ..remove('id')
          ..remove('teacher_id')
          ..remove('usage_count')
          ..remove('created_at')
          ..remove('last_used_at');
    final response = await _apiClient.post(
      '/settings/feedback-templates',
      data: data,
    );
    return FeedbackTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<FeedbackTemplate> updateTemplate(FeedbackTemplate template) async {
    final data =
        template.toJson()
          ..remove('id')
          ..remove('teacher_id')
          ..remove('usage_count')
          ..remove('created_at')
          ..remove('last_used_at');
    final response = await _apiClient.put(
      '/settings/feedback-templates/${template.id}',
      data: data,
    );
    return FeedbackTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _apiClient.delete('/settings/feedback-templates/$id');
  }

  @override
  Future<FeedbackTemplate> incrementUsage(String id) async {
    final response = await _apiClient.patch(
      '/settings/feedback-templates/$id/usage',
    );
    return FeedbackTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FeedbackTemplate>> _list([Map<String, dynamic>? query]) async {
    final response = await _apiClient.get(
      '/settings/feedback-templates',
      queryParameters: _compact(query),
    );
    final items = response.data as List<dynamic>;
    return items
        .map((item) => FeedbackTemplate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic>? _compact(Map<String, dynamic>? values) {
    values?.removeWhere((_, value) => value == null || value == '');
    return values;
  }
}
