// Recording comparison domain entity (practice §4.5).
//
// Holds the two recordings under comparison plus the playback session status.
// Pure value object — no Flutter, no audio driver, no persistence.

import 'practice_repertoire.dart';

/// Playback session status for an A/B recording comparison.
///
/// - [selecting]: user is still choosing recordings A and/or B.
/// - [playing]: at least one of A/B is actively playing back.
/// - [paused]: both recordings are loaded but no playback is active.
enum RecordingComparisonStatus { selecting, playing, paused }

/// Immutable A/B recording comparison value object.
///
/// Per spec practice_master.md §4.5.3:
/// - [recordingA]: earlier recording ("before").
/// - [recordingB]: later recording ("after").
class RecordingComparison {
  const RecordingComparison({
    required this.recordingA,
    required this.recordingB,
    this.status = RecordingComparisonStatus.paused,
  });

  /// Earlier recording (before).
  final PracticeRecording recordingA;

  /// Later recording (after).
  final PracticeRecording recordingB;

  /// Playback session status.
  final RecordingComparisonStatus status;

  /// BPM difference (null if either recording has no BPM).
  int? get bpmDelta => recordingA.bpm != null && recordingB.bpm != null
      ? recordingB.bpm! - recordingA.bpm!
      : null;

  /// BPM change percentage (null if either has no BPM or A.bpm is 0).
  double? get bpmChangePercent => bpmDelta != null && recordingA.bpm! > 0
      ? (bpmDelta! / recordingA.bpm!) * 100
      : null;

  /// Duration difference in seconds (B - A).
  int get durationDelta =>
      recordingB.durationSeconds - recordingA.durationSeconds;

  /// Days between the two recordings (B.createdAt - A.createdAt).
  int get daysBetween =>
      recordingB.createdAt.difference(recordingA.createdAt).inDays;

  RecordingComparison copyWith({
    PracticeRecording? recordingA,
    PracticeRecording? recordingB,
    RecordingComparisonStatus? status,
  }) {
    return RecordingComparison(
      recordingA: recordingA ?? this.recordingA,
      recordingB: recordingB ?? this.recordingB,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingComparison &&
          runtimeType == other.runtimeType &&
          recordingA == other.recordingA &&
          recordingB == other.recordingB &&
          status == other.status;

  @override
  int get hashCode => Object.hash(recordingA, recordingB, status);
}
