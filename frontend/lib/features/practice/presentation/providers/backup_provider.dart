// Riverpod providers for practice §6.3 Phase 1 backup flow.
//
// Exposes:
// - [backupService]: keep-alive [BackupService] instance (FileBackupService).
// - [backupProgress]: current operation progress + status text.
// - [backupController]: thin orchestration that runs create/restore and
//   pumps the progress provider.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/file_backup_service.dart';
import '../../../../core/presentation/extensions/backup_stage_labels.dart';
import '../../domain/entities/backup_archive.dart';
import '../../domain/services/backup_service.dart';

part 'backup_provider.g.dart';

/// Snapshot of the current backup or restore operation.
///
/// `progress` is `null` when idle, otherwise in `[0.0, 1.0]`.
class BackupProgress {
  final double? progress;
  final String? status;
  final bool isRunning;

  const BackupProgress({this.progress, this.status, this.isRunning = false});

  static const idle = BackupProgress();

  BackupProgress copyWith({double? progress, String? status, bool? isRunning}) {
    return BackupProgress(
      progress: progress ?? this.progress,
      status: status ?? this.status,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

/// Keep-alive [BackupService] instance.
@Riverpod(keepAlive: true)
BackupService backupService(BackupServiceRef ref) => FileBackupService();

/// Mutable progress feed driven by [BackupController].
@riverpod
class BackupProgressNotifier extends _$BackupProgressNotifier {
  @override
  BackupProgress build() => BackupProgress.idle;

  void update(double progress, String status) {
    state = BackupProgress(
      progress: progress,
      status: status,
      isRunning: progress < 1.0,
    );
  }

  void start(String status) {
    state = BackupProgress(progress: 0.0, status: status, isRunning: true);
  }

  void finish() {
    state = BackupProgress.idle;
  }
}

/// Orchestrates create/restore operations and pumps [BackupProgressNotifier].
///
/// The controller is itself a `Notifier<BackupProgress>` so that screens can
/// `ref.watch` it for state changes and `ref.read(...notifier).export()` to
/// trigger an operation.
@riverpod
class BackupController extends _$BackupController {
  @override
  BackupProgress build() => BackupProgress.idle;

  /// Run [BackupService.create] and surface progress via state.
  ///
  /// Returns the created [BackupArchive] on success, or `null` on failure
  /// (errors are surfaced through [error]).
  Future<BackupArchive?> export() async {
    if (state.isRunning) return null;
    state = BackupProgress(progress: 0.0, status: null, isRunning: true);
    try {
      final service = ref.read(backupServiceProvider);
      final archive = await service.create(
        onProgress: (p, s, {current, total}) {
          state = BackupProgress(
            progress: p,
            status: s.label(current: current, total: total),
            isRunning: p < 1.0,
          );
        },
      );
      state = BackupProgress.idle;
      return archive;
    } catch (e) {
      state = BackupProgress.idle;
      rethrow;
    }
  }

  /// Run [BackupService.restore] against a previously opened archive.
  Future<BackupRestoreResult?> import(BackupArchive archive) async {
    if (state.isRunning) return null;
    state = BackupProgress(progress: 0.0, status: null, isRunning: true);
    try {
      final service = ref.read(backupServiceProvider);
      final result = await service.restore(
        archive,
        onProgress: (p, s, {current, total}) {
          state = BackupProgress(
            progress: p,
            status: s.label(current: current, total: total),
            isRunning: p < 1.0,
          );
        },
      );
      state = BackupProgress.idle;
      return result;
    } catch (e) {
      state = BackupProgress.idle;
      rethrow;
    }
  }

  /// Parse archive metadata from disk (preview before restore).
  Future<BackupArchive> open(String filePath) {
    return ref.read(backupServiceProvider).open(filePath);
  }
}
