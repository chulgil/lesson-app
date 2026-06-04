import '../value_objects/audio_mix_mode.dart';
import '../value_objects/practice_loop_speeds.dart';
import 'loop_memo.dart';

/// Student-side override of teacher's default loop section for a [PracticeSection].
///
/// Stored locally per (student, section). The teacher's `PracticeSection.youtubeUrl`,
/// `youtubeStartSeconds`, `youtubeEndSeconds` remain untouched — overrides shadow them.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §3.2
class PracticeLoopOverride {
  /// Practice section this override targets.
  final String sectionId;

  /// Student who owns this override (Hive key isolation).
  final String studentUserId;

  /// Override start seconds. `null` = use teacher default.
  final int? overrideStartSeconds;

  /// Override end seconds. `null` = use teacher default.
  final int? overrideEndSeconds;

  /// Playback speed (must be one of [PracticeLoopSpeeds.allowed]).
  final double playbackSpeed;

  /// Target number of loop repetitions. Range: 1–20. Default 5.
  final int targetRepeatCount;

  /// Completed repetitions (runtime; persisted to enable resume).
  final int completedRepeatCount;

  /// Count-in (3-2-1) before each playback / loop restart.
  final bool countInEnabled;

  /// Click sound during count-in (only meaningful when [countInEnabled]).
  final bool countInSoundEnabled;

  /// Audio mix mode (video + recording + metronome combo).
  final AudioMixMode audioMixMode;

  /// Last time this section was played.
  final DateTime lastPlayedAt;

  /// Student-authored memos pinned to playback positions inside this section.
  ///
  /// Ordered by [LoopMemo.atSeconds] ascending for deterministic display.
  /// Spec: GH #510 — loop memo follow-up for §3.5.
  final List<LoopMemo> studentMemos;

  const PracticeLoopOverride({
    required this.sectionId,
    required this.studentUserId,
    this.overrideStartSeconds,
    this.overrideEndSeconds,
    this.playbackSpeed = PracticeLoopSpeeds.defaultSpeed,
    this.targetRepeatCount = 5,
    this.completedRepeatCount = 0,
    this.countInEnabled = false,
    this.countInSoundEnabled = true,
    this.audioMixMode = AudioMixMode.videoOnly,
    required this.lastPlayedAt,
    this.studentMemos = const [],
  });

  PracticeLoopOverride copyWith({
    String? sectionId,
    String? studentUserId,
    int? overrideStartSeconds,
    int? overrideEndSeconds,
    bool clearOverrideStart = false,
    bool clearOverrideEnd = false,
    double? playbackSpeed,
    int? targetRepeatCount,
    int? completedRepeatCount,
    bool? countInEnabled,
    bool? countInSoundEnabled,
    AudioMixMode? audioMixMode,
    DateTime? lastPlayedAt,
    List<LoopMemo>? studentMemos,
  }) {
    return PracticeLoopOverride(
      sectionId: sectionId ?? this.sectionId,
      studentUserId: studentUserId ?? this.studentUserId,
      overrideStartSeconds: clearOverrideStart
          ? null
          : (overrideStartSeconds ?? this.overrideStartSeconds),
      overrideEndSeconds: clearOverrideEnd
          ? null
          : (overrideEndSeconds ?? this.overrideEndSeconds),
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      targetRepeatCount: targetRepeatCount ?? this.targetRepeatCount,
      completedRepeatCount: completedRepeatCount ?? this.completedRepeatCount,
      countInEnabled: countInEnabled ?? this.countInEnabled,
      countInSoundEnabled: countInSoundEnabled ?? this.countInSoundEnabled,
      audioMixMode: audioMixMode ?? this.audioMixMode,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      studentMemos: studentMemos ?? this.studentMemos,
    );
  }

  /// Returns the effective start seconds, falling back to [teacherStart].
  int effectiveStartSeconds(int? teacherStart) =>
      overrideStartSeconds ?? teacherStart ?? 0;

  /// Returns the effective end seconds, falling back to [teacherEnd].
  int? effectiveEndSeconds(int? teacherEnd) => overrideEndSeconds ?? teacherEnd;

  /// True if either start or end is overridden.
  bool get hasOverride =>
      overrideStartSeconds != null || overrideEndSeconds != null;

  /// JSON encoding for portability (Hive uses custom adapter for performance).
  Map<String, dynamic> toJson() => {
    'sectionId': sectionId,
    'studentUserId': studentUserId,
    'overrideStartSeconds': overrideStartSeconds,
    'overrideEndSeconds': overrideEndSeconds,
    'playbackSpeed': playbackSpeed,
    'targetRepeatCount': targetRepeatCount,
    'completedRepeatCount': completedRepeatCount,
    'countInEnabled': countInEnabled,
    'countInSoundEnabled': countInSoundEnabled,
    'audioMixMode': audioMixMode.name,
    'lastPlayedAt': lastPlayedAt.toIso8601String(),
    'studentMemos': studentMemos.map((m) => m.toJson()).toList(),
  };

  static PracticeLoopOverride fromJson(Map<String, dynamic> json) {
    // Migration: older records (pre-#510) have no `studentMemos` key —
    // default to an empty list so existing data continues to load.
    final memosRaw = json['studentMemos'] as List<dynamic>?;
    final memos = memosRaw == null
        ? const <LoopMemo>[]
        : memosRaw
              .map((m) => LoopMemo.fromJson(m as Map<String, dynamic>))
              .toList();

    return PracticeLoopOverride(
      sectionId: json['sectionId'] as String,
      studentUserId: json['studentUserId'] as String,
      overrideStartSeconds: json['overrideStartSeconds'] as int?,
      overrideEndSeconds: json['overrideEndSeconds'] as int?,
      playbackSpeed:
          (json['playbackSpeed'] as num?)?.toDouble() ??
          PracticeLoopSpeeds.defaultSpeed,
      targetRepeatCount: (json['targetRepeatCount'] as int?) ?? 5,
      completedRepeatCount: (json['completedRepeatCount'] as int?) ?? 0,
      countInEnabled: (json['countInEnabled'] as bool?) ?? false,
      countInSoundEnabled: (json['countInSoundEnabled'] as bool?) ?? true,
      audioMixMode: AudioMixMode.values.firstWhere(
        (m) => m.name == (json['audioMixMode'] as String?),
        orElse: () => AudioMixMode.videoOnly,
      ),
      lastPlayedAt: DateTime.parse(
        (json['lastPlayedAt'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      studentMemos: memos,
    );
  }
}
