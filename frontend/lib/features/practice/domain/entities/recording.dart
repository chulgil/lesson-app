/// Minimum recording duration in seconds.
/// Recordings shorter than this cannot be saved.
const int minRecordingSeconds = 5;

/// Maximum recording duration in seconds (3 minutes).
const int maxRecordingSeconds = 180;

/// Type of recording.
enum RecordingType {
  student, // Student practice recording

  teacher, // Teacher reference recording

  feedback, // AI-converted feedback (text stored)
}

/// Storage status for server-synced recordings.
enum StorageStatus {
  local, // Only stored locally

  active, // Server active storage (fast access)

  archived, // S3 archive (delayed playback)

  deleted, // Deleted from server
}

/// Recording model for practice recordings.
class Recording {
  const Recording({
    required this.id,
    required this.repertoireId,
    required this.studentId,
    required this.type,
    required this.localPath,
    required this.durationSeconds,
    required this.recordedAt,
    this.serverUrl,
    this.isRepresentative = false,
    this.sharedAt,
    this.storageStatus = StorageStatus.local,
    this.title,
  });

  final String id;

  final String repertoireId;

  final String studentId;

  final RecordingType type;

  final String localPath;

  final String? serverUrl;

  final int durationSeconds;

  final bool isRepresentative;

  final DateTime recordedAt;

  final DateTime? sharedAt;

  final StorageStatus storageStatus;

  final String? title;

  /// Formatted duration string (mm:ss).
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Whether this recording is shared with teacher.
  bool get isShared => sharedAt != null;

  /// Whether local file exists (check by path not being empty).
  bool get hasLocalFile => localPath.isNotEmpty;

  /// The recording that should inherit representative status when the current
  /// representative is removed: the most recent by [recordedAt]. Null if empty.
  /// (#749 — never leave a repertoire without a representative.)
  static Recording? pickRepresentativeHeir(Iterable<Recording> candidates) {
    if (candidates.isEmpty) return null;
    final sorted = candidates.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return sorted.first;
  }

  Recording copyWith({
    String? id,
    String? repertoireId,
    String? studentId,
    RecordingType? type,
    String? localPath,
    String? serverUrl,
    int? durationSeconds,
    bool? isRepresentative,
    DateTime? recordedAt,
    DateTime? sharedAt,
    StorageStatus? storageStatus,
    String? title,
  }) {
    return Recording(
      id: id ?? this.id,
      repertoireId: repertoireId ?? this.repertoireId,
      studentId: studentId ?? this.studentId,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      serverUrl: serverUrl ?? this.serverUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isRepresentative: isRepresentative ?? this.isRepresentative,
      recordedAt: recordedAt ?? this.recordedAt,
      sharedAt: sharedAt ?? this.sharedAt,
      storageStatus: storageStatus ?? this.storageStatus,
      title: title ?? this.title,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recording && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
