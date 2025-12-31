// Smart Recording state and settings for automatic audio trimming.
//
// Provides automatic trimming of silent sections at the start and end
// of recordings, preserving the original file for recovery.

/// Recording phase during smart recording.
enum RecordingPhase {
  /// Waiting for sound input (silence detected)
  waiting,

  /// Active recording (sound detected)
  recording,

  /// Ending phase (sound stopped, may resume)
  ending,
}

/// Represents a silence period detected during recording.
class SilencePeriod {
  const SilencePeriod({
    required this.startTime,
    required this.endTime,
  });

  /// When silence started (relative to recording start).
  final Duration startTime;

  /// When silence ended (relative to recording start).
  final Duration endTime;

  /// Duration of the silence period.
  Duration get duration => endTime - startTime;

  Map<String, dynamic> toJson() => {
        'startTime': startTime.inMilliseconds,
        'endTime': endTime.inMilliseconds,
      };

  factory SilencePeriod.fromJson(Map<String, dynamic> json) => SilencePeriod(
        startTime: Duration(milliseconds: json['startTime'] as int),
        endTime: Duration(milliseconds: json['endTime'] as int),
      );
}

/// Represents a playable audio segment (non-silent portion).
class AudioSegment {
  const AudioSegment({
    required this.start,
    required this.end,
  });

  /// Start position in the original audio.
  final Duration start;

  /// End position in the original audio.
  final Duration end;

  /// Duration of this segment.
  Duration get duration => end - start;

  Map<String, dynamic> toJson() => {
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
      };

  factory AudioSegment.fromJson(Map<String, dynamic> json) => AudioSegment(
        start: Duration(milliseconds: json['start'] as int),
        end: Duration(milliseconds: json['end'] as int),
      );
}

/// State for smart recording functionality.
class SmartRecordingState {
  const SmartRecordingState({
    this.isEnabled = true,
    this.threshold = 0.40,
    this.phase = RecordingPhase.waiting,
    this.trimmedStart = Duration.zero,
    this.trimmedEnd = Duration.zero,
    this.originalFilePath,
    this.soundStartTime,
    this.soundEndTime,
    this.silencePeriods = const [],
    this.middleSilenceStartTime,
  });

  /// Whether smart recording is enabled.
  final bool isEnabled;

  /// Amplitude threshold for detecting sound (0.20 - 0.60).
  final double threshold;

  /// Current recording phase.
  final RecordingPhase phase;

  /// Duration trimmed from the start.
  final Duration trimmedStart;

  /// Duration trimmed from the end.
  final Duration trimmedEnd;

  /// Path to original file before trimming (for recovery).
  final String? originalFilePath;

  /// Timestamp when sound was first detected.
  final DateTime? soundStartTime;

  /// Timestamp when sound last stopped.
  final DateTime? soundEndTime;

  /// List of detected silence periods during recording.
  final List<SilencePeriod> silencePeriods;

  /// When current middle silence started (for tracking).
  final DateTime? middleSilenceStartTime;

  /// Minimum threshold value.
  static const double minThreshold = 0.20;

  /// Maximum threshold value.
  static const double maxThreshold = 0.60;

  /// Default threshold value.
  static const double defaultThreshold = 0.40;

  /// Minimum silence duration to consider for trimming.
  static const Duration minSilenceDuration = Duration(seconds: 3);

  /// Default middle silence threshold for skipping.
  static const Duration defaultMiddleSilenceThreshold = Duration(seconds: 10);

  /// Minimum middle silence threshold.
  static const Duration minMiddleSilenceThreshold = Duration(seconds: 5);

  /// Maximum middle silence threshold.
  static const Duration maxMiddleSilenceThreshold = Duration(seconds: 30);

  /// Buffer to keep before/after skipped silence.
  static const Duration silenceBuffer = Duration(seconds: 3);

  /// Total duration trimmed.
  Duration get totalTrimmed => trimmedStart + trimmedEnd;

  /// Whether any trimming was applied.
  bool get hasTrimming => trimmedStart > Duration.zero || trimmedEnd > Duration.zero;

  /// Whether original file can be recovered.
  bool get canRecover => originalFilePath != null;

  /// Whether there are middle silence periods to skip.
  bool get hasMiddleSilence => silencePeriods.isNotEmpty;

  SmartRecordingState copyWith({
    bool? isEnabled,
    double? threshold,
    RecordingPhase? phase,
    Duration? trimmedStart,
    Duration? trimmedEnd,
    String? originalFilePath,
    DateTime? soundStartTime,
    DateTime? soundEndTime,
    List<SilencePeriod>? silencePeriods,
    DateTime? middleSilenceStartTime,
    bool clearMiddleSilenceStartTime = false,
  }) {
    return SmartRecordingState(
      isEnabled: isEnabled ?? this.isEnabled,
      threshold: threshold ?? this.threshold,
      phase: phase ?? this.phase,
      trimmedStart: trimmedStart ?? this.trimmedStart,
      trimmedEnd: trimmedEnd ?? this.trimmedEnd,
      originalFilePath: originalFilePath ?? this.originalFilePath,
      soundStartTime: soundStartTime ?? this.soundStartTime,
      soundEndTime: soundEndTime ?? this.soundEndTime,
      silencePeriods: silencePeriods ?? this.silencePeriods,
      middleSilenceStartTime: clearMiddleSilenceStartTime
          ? null
          : (middleSilenceStartTime ?? this.middleSilenceStartTime),
    );
  }

  /// Reset to initial recording state.
  SmartRecordingState resetForNewRecording() {
    return SmartRecordingState(
      isEnabled: isEnabled,
      threshold: threshold,
      phase: RecordingPhase.waiting,
      trimmedStart: Duration.zero,
      trimmedEnd: Duration.zero,
      originalFilePath: null,
      soundStartTime: null,
      soundEndTime: null,
      silencePeriods: const [],
      middleSilenceStartTime: null,
    );
  }

  @override
  String toString() {
    return 'SmartRecordingState(isEnabled: $isEnabled, threshold: $threshold, '
        'phase: $phase, trimmedStart: $trimmedStart, trimmedEnd: $trimmedEnd, '
        'silencePeriods: ${silencePeriods.length})';
  }
}

/// Persistent settings for smart recording.
class SmartRecordingSettings {
  const SmartRecordingSettings({
    this.smartRecordingEnabled = true,
    this.trimThreshold = SmartRecordingState.defaultThreshold,
    this.middleSilenceSkipEnabled = true,
    this.middleSilenceThreshold = 10,
  });

  /// Whether smart recording is enabled by default.
  final bool smartRecordingEnabled;

  /// Default trim threshold.
  final double trimThreshold;

  /// Whether middle silence skip is enabled.
  final bool middleSilenceSkipEnabled;

  /// Middle silence threshold in seconds (5-30).
  final int middleSilenceThreshold;

  /// Get middle silence threshold as Duration.
  Duration get middleSilenceThresholdDuration =>
      Duration(seconds: middleSilenceThreshold);

  /// Create settings from JSON.
  factory SmartRecordingSettings.fromJson(Map<String, dynamic> json) {
    return SmartRecordingSettings(
      smartRecordingEnabled: json['smartRecordingEnabled'] as bool? ?? true,
      trimThreshold: (json['trimThreshold'] as num?)?.toDouble() ??
          SmartRecordingState.defaultThreshold,
      middleSilenceSkipEnabled:
          json['middleSilenceSkipEnabled'] as bool? ?? true,
      middleSilenceThreshold: json['middleSilenceThreshold'] as int? ?? 10,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'smartRecordingEnabled': smartRecordingEnabled,
      'trimThreshold': trimThreshold,
      'middleSilenceSkipEnabled': middleSilenceSkipEnabled,
      'middleSilenceThreshold': middleSilenceThreshold,
    };
  }

  SmartRecordingSettings copyWith({
    bool? smartRecordingEnabled,
    double? trimThreshold,
    bool? middleSilenceSkipEnabled,
    int? middleSilenceThreshold,
  }) {
    return SmartRecordingSettings(
      smartRecordingEnabled:
          smartRecordingEnabled ?? this.smartRecordingEnabled,
      trimThreshold: trimThreshold ?? this.trimThreshold,
      middleSilenceSkipEnabled:
          middleSilenceSkipEnabled ?? this.middleSilenceSkipEnabled,
      middleSilenceThreshold:
          middleSilenceThreshold ?? this.middleSilenceThreshold,
    );
  }
}

/// Result of a trim operation.
class TrimResult {
  const TrimResult({
    required this.success,
    required this.trimmedFilePath,
    this.originalFilePath,
    this.trimmedStart = Duration.zero,
    this.trimmedEnd = Duration.zero,
    this.errorMessage,
  });

  /// Whether trimming was successful.
  final bool success;

  /// Path to the trimmed file.
  final String trimmedFilePath;

  /// Path to the original file (for recovery).
  final String? originalFilePath;

  /// Duration trimmed from start.
  final Duration trimmedStart;

  /// Duration trimmed from end.
  final Duration trimmedEnd;

  /// Error message if trimming failed.
  final String? errorMessage;

  /// Total duration trimmed.
  Duration get totalTrimmed => trimmedStart + trimmedEnd;

  /// Whether any actual trimming occurred.
  bool get hasTrimming => trimmedStart > Duration.zero || trimmedEnd > Duration.zero;

  /// Create a failed result.
  factory TrimResult.failed(String filePath, String error) {
    return TrimResult(
      success: false,
      trimmedFilePath: filePath,
      errorMessage: error,
    );
  }

  /// Create a no-trim result (file unchanged).
  factory TrimResult.noTrim(String filePath) {
    return TrimResult(
      success: true,
      trimmedFilePath: filePath,
    );
  }
}
