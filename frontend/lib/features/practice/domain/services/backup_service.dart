// Backup service interface for practice §6.3 Phase 1.
//
// Defines the contract for creating and restoring `.lessonbackup` archives.
// Pure domain — concrete file/Hive I/O lives in `data/services/`.

import '../entities/backup_archive.dart';

/// Progress callback signature used by [BackupService].
///
/// [progress] is in `[0.0, 1.0]`. [status] is a localized message suitable
/// for UI display (e.g. the "백업 zip 압축 중" progress copy).
typedef BackupProgressCallback = void Function(double progress, String status);

/// Abstraction over the ZIP backup pipeline.
///
/// Implementations are expected to:
/// - Write `metadata.json` (with magic + version) as the first archive entry.
/// - Validate magic + major version before touching any local state on restore.
/// - Report progress via [BackupProgressCallback] at meaningful checkpoints.
abstract class BackupService {
  /// Bundle Hive boxes + recording files into a new `.lessonbackup` archive.
  ///
  /// Returns the [BackupArchive] describing the created file. Throws on
  /// I/O failure — callers should surface errors via the provider layer.
  Future<BackupArchive> create({BackupProgressCallback? onProgress});

  /// Restore an archive produced by [create].
  ///
  /// Rejects archives that fail magic/version validation
  /// ([BackupArchive.isValid]). Existing recording files are kept; new
  /// files and Hive entries are added.
  Future<BackupRestoreResult> restore(
    BackupArchive archive, {
    BackupProgressCallback? onProgress,
  });

  /// Parse archive metadata from a file path without performing restore.
  ///
  /// Used by the UI to preview the archive (created date, recording count)
  /// before the user confirms a restore.
  Future<BackupArchive> open(String filePath);
}
