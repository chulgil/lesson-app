import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/practice_repertoire.dart';

part 'recording_comparison_provider.g.dart';

/// Recording comparison data model.
class RecordingComparison {
  const RecordingComparison({
    required this.recordingA,
    required this.recordingB,
  });

  /// Earlier recording (before).
  final PracticeRecording recordingA;

  /// Later recording (after).
  final PracticeRecording recordingB;

  /// BPM difference (null if either has no BPM).
  int? get bpmDelta =>
      recordingA.bpm != null && recordingB.bpm != null
          ? recordingB.bpm! - recordingA.bpm!
          : null;

  /// BPM change percentage.
  double? get bpmChangePercent =>
      bpmDelta != null && recordingA.bpm! > 0
          ? (bpmDelta! / recordingA.bpm!) * 100
          : null;

  /// Duration difference in seconds.
  int get durationDelta =>
      recordingB.durationSeconds - recordingA.durationSeconds;

  /// Days between the two recordings.
  int get daysBetween =>
      recordingB.createdAt.difference(recordingA.createdAt).inDays;
}

/// Comparison state notifier.
@riverpod
class RecordingComparisonNotifier extends _$RecordingComparisonNotifier {
  @override
  RecordingComparison? build() => null;

  void setComparison(PracticeRecording a, PracticeRecording b) {
    state = RecordingComparison(recordingA: a, recordingB: b);
  }

  void clear() => state = null;
}
