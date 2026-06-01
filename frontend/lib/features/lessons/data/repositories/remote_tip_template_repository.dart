import '../../../../core/network/api_client.dart';
import '../../domain/entities/tip_template.dart';
import '../../domain/repositories/tip_template_repository.dart';

class RemoteTipTemplateRepository implements TipTemplateRepository {
  RemoteTipTemplateRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<TipTemplate>> getTemplates(String teacherId) => _list();

  @override
  Future<List<TipTemplate>> getTemplatesByCategory(
    String teacherId,
    TipCategory category,
  ) {
    return _list({'category': category.name});
  }

  @override
  Future<List<TipTemplate>> getTemplatesByInstrument(
    String teacherId,
    String? instrument,
  ) {
    return _list({'instrument': instrument});
  }

  @override
  Future<List<TipTemplate>> searchTemplates(String teacherId, String query) {
    return _list({'query': query});
  }

  @override
  Future<List<TipTemplate>> getFrequentlyUsed(
    String teacherId, {
    int limit = 5,
  }) {
    return _list({'frequent': true, 'limit': limit});
  }

  @override
  Future<TipTemplate> createTemplate(TipTemplate template) async {
    final data =
        template.toJson()
          ..remove('id')
          ..remove('teacher_id')
          ..remove('usage_count')
          ..remove('created_at')
          ..remove('last_used_at');
    final response = await _apiClient.post(
      '/settings/tip-templates',
      data: data,
    );
    return TipTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TipTemplate> updateTemplate(TipTemplate template) async {
    final data =
        template.toJson()
          ..remove('id')
          ..remove('teacher_id')
          ..remove('usage_count')
          ..remove('created_at')
          ..remove('last_used_at');
    final response = await _apiClient.put(
      '/settings/tip-templates/${template.id}',
      data: data,
    );
    return TipTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _apiClient.delete('/settings/tip-templates/$id');
  }

  @override
  Future<TipTemplate> incrementUsage(String id) async {
    final response = await _apiClient.patch(
      '/settings/tip-templates/$id/usage',
    );
    return TipTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TipTemplate>> _list([Map<String, dynamic>? query]) async {
    final response = await _apiClient.get(
      '/settings/tip-templates',
      queryParameters: _compact(query),
    );
    final items = response.data as List<dynamic>;
    return items
        .map((item) => TipTemplate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic>? _compact(Map<String, dynamic>? values) {
    values?.removeWhere((_, value) => value == null || value == '');
    return values;
  }
}
