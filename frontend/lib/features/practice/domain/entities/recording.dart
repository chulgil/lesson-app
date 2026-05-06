// Recording domain entity
// Moved from lib/features/practice/domain/entities/recording.dart for Clean Architecture

import 'package:hive/hive.dart';

part 'recording.g.dart';

/// Minimum recording duration in seconds.
/// Recordings shorter than this cannot be saved.
const int minRecordingSeconds = 5;

/// Maximum recording duration in seconds (3 minutes).
const int maxRecordingSeconds = 180;

/// Type of recording.
@HiveType(typeId: 20)
enum RecordingType {
  @HiveField(0)
  student, // Student practice recording

  @HiveField(1)
  teacher, // Teacher reference recording

  @HiveField(2)
  feedback, // AI-converted feedback (text stored)
}

/// Storage status for server-synced recordings.
@HiveType(typeId: 21)
enum StorageStatus {
  @HiveField(0)
  local, // Only stored locally

  @HiveField(1)
  active, // Server active storage (fast access)

  @HiveField(2)
  archived, // S3 archive (delayed playback)

  @HiveField(3)
  deleted, // Deleted from server
}

/// Recording model for practice recordings.
@HiveType(typeId: 22)
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

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String repertoireId;

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final RecordingType type;

  @HiveField(4)
  final String localPath;

  @HiveField(5)
  final String? serverUrl;

  @HiveField(6)
  final int durationSeconds;

  @HiveField(7)
  final bool isRepresentative;

  @HiveField(8)
  final DateTime recordedAt;

  @HiveField(9)
  final DateTime? sharedAt;

  @HiveField(10)
  final StorageStatus storageStatus;

  @HiveField(11)
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
