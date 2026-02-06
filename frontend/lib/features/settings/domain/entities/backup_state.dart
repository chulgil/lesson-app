// Backup state and related models for the backup system.
//
// Part of the data backup feature (Issue #15).

/// State of the backup system.
class BackupState {
  final int recordingCount;
  final int totalSizeBytes;
  final DateTime? lastBackupDate;
  final bool isBackingUp;
  final bool isRestoring;
  final double? progress;
  final String? lastError;

  const BackupState({
    this.recordingCount = 0,
    this.totalSizeBytes = 0,
    this.lastBackupDate,
    this.isBackingUp = false,
    this.isRestoring = false,
    this.progress,
    this.lastError,
  });

  BackupState copyWith({
    int? recordingCount,
    int? totalSizeBytes,
    DateTime? lastBackupDate,
    bool? isBackingUp,
    bool? isRestoring,
    double? progress,
    String? lastError,
  }) {
    return BackupState(
      recordingCount: recordingCount ?? this.recordingCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      progress: progress ?? this.progress,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Format total size as human-readable string.
  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

/// Metadata stored in backup archive.
class BackupMetadata {
  final String appVersion;
  final String backupVersion;
  final DateTime createdAt;
  final int recordingCount;
  final int totalSizeBytes;
  final String deviceModel;
  final String osVersion;
  final Map<String, int> boxCounts;

  const BackupMetadata({
    required this.appVersion,
    required this.backupVersion,
    required this.createdAt,
    required this.recordingCount,
    required this.totalSizeBytes,
    required this.deviceModel,
    required this.osVersion,
    this.boxCounts = const {},
  });

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'backupVersion': backupVersion,
        'createdAt': createdAt.toIso8601String(),
        'recordingCount': recordingCount,
        'totalSizeBytes': totalSizeBytes,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'boxCounts': boxCounts,
      };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      appVersion: json['appVersion'] as String? ?? 'unknown',
      backupVersion: json['backupVersion'] as String? ?? '1.0',
      createdAt: DateTime.parse(json['createdAt'] as String),
      recordingCount: json['recordingCount'] as int? ?? 0,
      totalSizeBytes: json['totalSizeBytes'] as int? ?? 0,
      deviceModel: json['deviceModel'] as String? ?? 'unknown',
      osVersion: json['osVersion'] as String? ?? 'unknown',
      boxCounts: Map<String, int>.from(json['boxCounts'] as Map? ?? {}),
    );
  }
}

/// Result of a restore operation.
class RestoreResult {
  final bool success;
  final int restoredRecordings;
  final int skippedRecordings;
  final int restoredBoxEntries;
  final String? errorMessage;

  const RestoreResult({
    required this.success,
    this.restoredRecordings = 0,
    this.skippedRecordings = 0,
    this.restoredBoxEntries = 0,
    this.errorMessage,
  });

  factory RestoreResult.failure(String message) => RestoreResult(
        success: false,
        errorMessage: message,
      );
}
