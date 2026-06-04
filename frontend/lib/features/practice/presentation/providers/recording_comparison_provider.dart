import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/practice_repertoire.dart';
import '../../domain/entities/recording_comparison.dart';

// Re-export the entity so existing imports of this file keep working.
export '../../domain/entities/recording_comparison.dart'
    show RecordingComparison, RecordingComparisonStatus;

part 'recording_comparison_provider.g.dart';

/// Comparison state notifier.
@riverpod
class RecordingComparisonNotifier extends _$RecordingComparisonNotifier {
  @override
  RecordingComparison? build() => null;

  void setComparison(PracticeRecording a, PracticeRecording b) {
    state = RecordingComparison(recordingA: a, recordingB: b);
  }

  void setStatus(RecordingComparisonStatus status) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(status: status);
  }

  void clear() => state = null;
}
