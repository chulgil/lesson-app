import '../entities/feedback_preset.dart';

/// Repository interface for feedback presets.
abstract class FeedbackPresetRepository {
  Future<List<FeedbackPreset>> getPresets({String? teacherId});
  Future<FeedbackPreset> addPreset(FeedbackPreset preset);
  Future<void> updatePreset(FeedbackPreset preset);
  Future<void> deletePreset(String id);
  Future<void> restorePreset(String id);
}
