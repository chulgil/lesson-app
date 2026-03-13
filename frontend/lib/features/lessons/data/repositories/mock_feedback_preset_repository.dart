import '../../domain/constants/feedback_constants.dart';
import '../../domain/entities/feedback_preset.dart';

/// Mock repository for feedback presets.
/// Stores default presets and teacher-created custom presets.
class MockFeedbackPresetRepository {
  final List<FeedbackPreset> _presets = [];
  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    // Initialize with default presets
    for (int i = 0; i < feedbackPresets.length; i++) {
      _presets.add(FeedbackPreset(
        id: 'default_$i',
        text: feedbackPresets[i],
        sortOrder: i,
        isDefault: true,
        createdAt: DateTime(2026, 1, 1),
      ));
    }
  }

  /// Get all visible presets for a teacher, sorted by order.
  Future<List<FeedbackPreset>> getPresets({String? teacherId}) async {
    _ensureInitialized();
    final result = _presets
        .where((p) => !p.isHidden)
        .where((p) => p.isDefault || p.teacherId == teacherId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  /// Add a custom preset.
  Future<FeedbackPreset> addPreset(FeedbackPreset preset) async {
    _ensureInitialized();
    final maxOrder = _presets.isEmpty
        ? 0
        : _presets.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b);
    final newPreset = preset.copyWith(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      sortOrder: maxOrder + 1,
    );
    _presets.add(newPreset);
    return newPreset;
  }

  /// Update a preset (text or sort order).
  Future<void> updatePreset(FeedbackPreset preset) async {
    _ensureInitialized();
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      _presets[index] = preset;
    }
  }

  /// Delete a custom preset or hide a default preset.
  Future<void> deletePreset(String id) async {
    _ensureInitialized();
    final index = _presets.indexWhere((p) => p.id == id);
    if (index != -1) {
      if (_presets[index].isDefault) {
        // Hide default presets instead of deleting
        _presets[index] = _presets[index].copyWith(isHidden: true);
      } else {
        _presets.removeAt(index);
      }
    }
  }

  /// Restore a hidden default preset.
  Future<void> restorePreset(String id) async {
    _ensureInitialized();
    final index = _presets.indexWhere((p) => p.id == id);
    if (index != -1 && _presets[index].isDefault) {
      _presets[index] = _presets[index].copyWith(isHidden: false);
    }
  }
}
