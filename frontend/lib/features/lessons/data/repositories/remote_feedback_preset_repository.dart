import '../../../../core/network/api_client.dart';
import '../../domain/entities/feedback_preset.dart';
import '../../domain/repositories/feedback_preset_repository.dart';

/// Remote implementation of [FeedbackPresetRepository] using FastAPI backend.
class RemoteFeedbackPresetRepository implements FeedbackPresetRepository {
  final ApiClient _apiClient;

  RemoteFeedbackPresetRepository(this._apiClient);

  @override
  Future<List<FeedbackPreset>> getPresets({String? teacherId}) async {
    final response = await _apiClient.get('/settings/feedback-presets');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => FeedbackPreset.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FeedbackPreset> addPreset(FeedbackPreset preset) async {
    final response = await _apiClient.post(
      '/settings/feedback-presets',
      data: {
        'text': preset.text,
        'sort_order': preset.sortOrder,
      },
    );
    return FeedbackPreset.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updatePreset(FeedbackPreset preset) async {
    await _apiClient.put(
      '/settings/feedback-presets/${preset.id}',
      data: {
        'text': preset.text,
        'sort_order': preset.sortOrder,
        'is_hidden': preset.isHidden,
      },
    );
  }

  @override
  Future<void> deletePreset(String id) async {
    await _apiClient.delete('/settings/feedback-presets/$id');
  }

  @override
  Future<void> restorePreset(String id) async {
    // Restore = update with is_hidden: false
    await _apiClient.put(
      '/settings/feedback-presets/$id',
      data: {'is_hidden': false},
    );
  }
}
