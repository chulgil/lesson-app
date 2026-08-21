// Backup archive value object for practice §6.3 Phase 1.
//
// Represents the manifest of a `.lessonbackup` ZIP archive: magic number,
// version, metadata, and the recording entries inside the archive.
// Pure domain — no Flutter or platform imports.

import '../../../../core/domain/entities/backup_stage.dart';

/// Magic header written to `metadata.json` to identify our archive format.
///
/// Used at restore time as a first-pass integrity gate before doing any
/// file I/O against Hive boxes or the recordings directory.

const String backupArchiveMagic = 'lessonbackup';

/// Backup archive format version.
///
/// Bumped whenever the on-disk layout (file names, JSON shape, Hive schema)
/// changes in a non-backwards-compatible way. Restore checks the major
/// version prefix (e.g. `1.x` accepts `1.0`, `1.1`).
const String backupArchiveVersion = '1.0';

/// Manifest entry describing one recording file inside the archive.
class BackupRecordingEntry {
  /// Path inside the archive, relative to archive root (e.g. `recordings/abc.m4a`).
  final String relativePath;

  /// File size in bytes (uncompressed).
  final int sizeBytes;

  const BackupRecordingEntry({
    required this.relativePath,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'relativePath': relativePath,
    'sizeBytes': sizeBytes,
  };

  factory BackupRecordingEntry.fromJson(Map<String, dynamic> json) {
    return BackupRecordingEntry(
      relativePath: json['relativePath'] as String,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
    );
  }
}

/// Metadata stored in `metadata.json` inside the archive.
class BackupArchiveMetadata {
  /// Magic header (`backupArchiveMagic`).
  final String magic;

  /// Archive format version (`backupArchiveVersion`).
  final String backupVersion;

  /// App version that produced the archive.
  final String appVersion;

  /// Creation timestamp (UTC).
  final DateTime createdAt;

  /// Total number of recording files in the archive.
  final int recordingCount;

  /// Total uncompressed bytes of recording files.
  final int totalSizeBytes;

  /// Platform identifier (e.g. `ios`, `android`).
  final String deviceModel;

  /// OS version string.
  final String osVersion;

  const BackupArchiveMetadata({
    required this.magic,
    required this.backupVersion,
    required this.appVersion,
    required this.createdAt,
    required this.recordingCount,
    required this.totalSizeBytes,
    required this.deviceModel,
    required this.osVersion,
  });

  Map<String, dynamic> toJson() => {
    'magic': magic,
    'backupVersion': backupVersion,
    'appVersion': appVersion,
    'createdAt': createdAt.toIso8601String(),
    'recordingCount': recordingCount,
    'totalSizeBytes': totalSizeBytes,
    'deviceModel': deviceModel,
    'osVersion': osVersion,
  };

  factory BackupArchiveMetadata.fromJson(Map<String, dynamic> json) {
    return BackupArchiveMetadata(
      magic: json['magic'] as String? ?? '',
      backupVersion: json['backupVersion'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? 'unknown',
      createdAt: DateTime.parse(json['createdAt'] as String),
      recordingCount: json['recordingCount'] as int? ?? 0,
      totalSizeBytes: json['totalSizeBytes'] as int? ?? 0,
      deviceModel: json['deviceModel'] as String? ?? 'unknown',
      osVersion: json['osVersion'] as String? ?? 'unknown',
    );
  }
}

/// Logical representation of a `.lessonbackup` archive.
///
/// Created by [BackupService.create] and passed to [BackupService.restore].
/// Concrete adapters back this with a file path or in-memory bytes.
class BackupArchive {
  /// Absolute path of the archive on disk (`*.lessonbackup`).
  final String filePath;

  /// Parsed metadata (magic, version, counters).
  final BackupArchiveMetadata metadata;

  /// Manifest of recording entries inside the archive.
  final List<BackupRecordingEntry> recordings;

  const BackupArchive({
    required this.filePath,
    required this.metadata,
    required this.recordings,
  });

  /// Reject archives whose magic or major version do not match.
  ///
  /// `true` only when both checks pass — used by restore as a hard gate.
  bool get isValid =>
      metadata.magic == backupArchiveMagic &&
      isVersionCompatible(metadata.backupVersion);

  /// `1.x` archives are accepted; future major versions are rejected
  /// to avoid silently overwriting newer Hive schemas with older data.
  static bool isVersionCompatible(String version) => version.startsWith('1.');
}

/// Outcome of [BackupService.restore].
class BackupRestoreResult {
  /// `true` when the archive passed validation and restore finished.
  final bool success;

  /// Recording files copied into the documents directory.
  final int restoredRecordings;

  /// Recording files skipped because the destination already exists.
  final int skippedRecordings;

  /// Hive entries inserted across all boxes.
  final int restoredBoxEntries;

  /// Typed failure payload when [success] is `false` — presentation maps it
  /// to user copy (backup_stage_labels.dart).
  final BackupFailure? failure;

  const BackupRestoreResult({
    required this.success,
    this.restoredRecordings = 0,
    this.skippedRecordings = 0,
    this.restoredBoxEntries = 0,
    this.failure,
  });

  factory BackupRestoreResult.failure(BackupFailure failure) =>
      BackupRestoreResult(success: false, failure: failure);
}
