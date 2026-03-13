import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_feedback_preset_repository.dart';
import '../../domain/entities/feedback_preset.dart';

part 'feedback_preset_providers.g.dart';

/// Repository provider for feedback presets.
@Riverpod(keepAlive: true)
MockFeedbackPresetRepository feedbackPresetRepository(
  FeedbackPresetRepositoryRef ref,
) {
  return MockFeedbackPresetRepository();
}

/// Provider for active feedback presets (visible, sorted).
@riverpod
class FeedbackPresetNotifier extends _$FeedbackPresetNotifier {
  @override
  Future<List<FeedbackPreset>> build({String? teacherId}) async {
    final repository = ref.read(feedbackPresetRepositoryProvider);
    return repository.getPresets(teacherId: teacherId);
  }

  /// Add a new custom preset.
  Future<void> addPreset(String text) async {
    final repository = ref.read(feedbackPresetRepositoryProvider);
    final preset = FeedbackPreset(
      id: '',
      text: text,
      teacherId: teacherId,
      createdAt: DateTime.now(),
    );
    await repository.addPreset(preset);
    ref.invalidateSelf();
  }

  /// Delete a preset (hides default, removes custom).
  Future<void> deletePreset(String id) async {
    final repository = ref.read(feedbackPresetRepositoryProvider);
    await repository.deletePreset(id);
    ref.invalidateSelf();
  }

  /// Update preset text.
  Future<void> updatePreset(FeedbackPreset preset) async {
    final repository = ref.read(feedbackPresetRepositoryProvider);
    await repository.updatePreset(preset);
    ref.invalidateSelf();
  }
}
