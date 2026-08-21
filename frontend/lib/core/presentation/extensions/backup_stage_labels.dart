// Presentation mapping for backup stages/failures (#1299).
//
// The data-layer backup services emit pure [BackupStage]/[BackupFailure]
// values; this is the single place that turns them into user-facing copy
// (C3 — 상태→라벨 매핑은 presentation extension 1곳). Reuses the existing
// AppStrings backup* constants, so the stage-0 ratchet is unaffected.

import '../../domain/entities/backup_stage.dart';
import '../../l10n/app_strings.dart';

extension BackupStageLabels on BackupStage {
  /// User-facing progress copy for this stage.
  ///
  /// [current]/[total] render the per-file counter for the recording
  /// add/restore stages; other stages ignore them.
  String label({int? current, int? total}) {
    switch (this) {
      case BackupStage.preparing:
        return AppStrings.backupPreparing;
      case BackupStage.creatingMetadata:
        return AppStrings.backupMetadataCreating;
      case BackupStage.exportingHive:
        return AppStrings.backupHiveExporting;
      case BackupStage.addingRecordings:
        if (current != null && total != null) {
          return AppStrings.backupRecordingsAddingProgressFormat(
            current,
            total,
          );
        }
        return AppStrings.backupRecordingsAdding;
      case BackupStage.compressing:
        return AppStrings.backupZipCompressing;
      case BackupStage.backupCompleted:
        return AppStrings.backupComplete;
      case BackupStage.readingFile:
        return AppStrings.backupFileReading;
      case BackupStage.checkingVersion:
        return AppStrings.backupVersionChecking;
      case BackupStage.restoringHive:
        return AppStrings.backupHiveRestoring;
      case BackupStage.restoringRecordings:
        if (current != null && total != null) {
          return AppStrings.backupRecordingsRestoringProgressFormat(
            current,
            total,
          );
        }
        return AppStrings.backupRecordingsRestoring;
      case BackupStage.restoreCompleted:
        return AppStrings.restoreComplete;
    }
  }
}

extension BackupFailureLabels on BackupFailure {
  /// User-facing error copy for this failure.
  String get message {
    switch (kind) {
      case BackupFailureKind.invalidFile:
        return AppStrings.backupInvalidFile;
      case BackupFailureKind.unsupportedVersion:
        return AppStrings.backupUnsupportedVersionFormat(detail ?? '');
      case BackupFailureKind.wrongExtension:
        return '${AppStrings.backupInvalidFile}'
            '${detail == null ? '' : ' ($detail)'}';
      case BackupFailureKind.encodeFailed:
        return AppStrings.backupEncodeFailure;
      case BackupFailureKind.unknown:
        return AppStrings.restoreErrorFormat(detail ?? '');
    }
  }
}
