// Backup progress stages and typed failures (#1299).
//
// The backup pipelines (settings legacy `BackupService`, practice
// `FileBackupService`) used to emit localized status STRINGS from the data
// layer, which violates the l10n layer contract (data must not depend on
// the string layer). They now emit these pure values; the label mapping
// lives in `core/presentation/extensions/backup_stage_labels.dart`.

/// A checkpoint in the backup/restore pipeline.
///
/// [BackupStage.addingRecordings] and [BackupStage.restoringRecordings] are
/// reported with `current`/`total` counters via the progress callback so the
/// UI can render per-file progress copy.
enum BackupStage {
  preparing,
  creatingMetadata,
  exportingHive,
  addingRecordings,
  compressing,
  backupCompleted,
  readingFile,
  checkingVersion,
  restoringHive,
  restoringRecordings,
  restoreCompleted,
}

/// Why a backup/restore operation failed.
enum BackupFailureKind {
  /// Archive is missing, corrupt, or fails magic/metadata validation.
  invalidFile,

  /// Archive version is newer than this app understands. [BackupFailure.detail]
  /// carries the offending version string.
  unsupportedVersion,

  /// Picked file does not carry the backup extension.
  /// [BackupFailure.detail] carries the expected extension.
  wrongExtension,

  /// File picker returned no usable path (unrelated to file validity).
  pathUnavailable,

  /// ZIP encoding produced no bytes.
  encodeFailed,

  /// Unexpected error during restore. [BackupFailure.detail] carries the
  /// underlying error's string form.
  unknown,
}

/// Typed failure payload — replaces the localized `errorMessage` string that
/// data-layer services used to produce.
class BackupFailure {
  final BackupFailureKind kind;

  /// Kind-specific detail (version string, underlying error text).
  final String? detail;

  const BackupFailure(this.kind, {this.detail});

  @override
  String toString() =>
      'BackupFailure(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// Exception form for pipeline steps that throw instead of returning a
/// failure result (e.g. archive open, ZIP encode).
class BackupException implements Exception {
  final BackupFailure failure;

  const BackupException(this.failure);

  @override
  String toString() => 'BackupException(${failure.kind.name})';
}
