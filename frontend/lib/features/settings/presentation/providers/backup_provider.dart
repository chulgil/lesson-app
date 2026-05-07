// Backup providers for managing backup state and operations.
//
// Part of the data backup feature (Issue #15).

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/backup_state.dart';
import '../../data/services/backup_service.dart';

part 'backup_provider.g.dart';

/// Provider for BackupService singleton.
@Riverpod(keepAlive: true)
BackupService backupService(BackupServiceRef ref) {
  return BackupService();
}

/// List of available backup files.
@Riverpod(keepAlive: true)
Future<List<BackupFileInfo>> backupList(BackupListRef ref) async {
  final service = ref.watch(backupServiceProvider);
  return service.listBackups();
}

/// Backup notifier for managing backup operations.
@Riverpod(keepAlive: true)
class BackupStateNotifier extends _$BackupStateNotifier {
  BackupService get _service => ref.read(backupServiceProvider);

  @override
  Future<BackupState> build() async {
    return _service.getBackupState();
  }

  /// Create a new backup and share it.
  Future<File?> createBackup() async {
    final current = state.value ?? const BackupState();

    // Set backing up state
    state = AsyncValue.data(
      current.copyWith(isBackingUp: true, progress: 0.0, lastError: null),
    );

    try {
      final backupFile = await _service.createBackup(
        onProgress: (progress, status) {
          final currentState = state.value ?? const BackupState();
          state = AsyncValue.data(currentState.copyWith(progress: progress));
        },
      );

      // Refresh state after backup
      final newState = await _service.getBackupState();
      state = AsyncValue.data(
        newState.copyWith(isBackingUp: false, progress: null),
      );

      // Invalidate backup list
      ref.invalidate(backupListProvider);

      return backupFile;
    } catch (e) {
      final currentState = state.value ?? const BackupState();
      state = AsyncValue.data(
        currentState.copyWith(
          isBackingUp: false,
          progress: null,
          lastError: e.toString(),
        ),
      );
      return null;
    }
  }

  /// Create backup and share via share sheet.
  Future<void> createAndShareBackup() async {
    final backupFile = await createBackup();
    if (backupFile != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          subject: '레슨 앱 백업',
          text: '레슨 앱 녹음 데이터 백업 파일입니다.',
        ),
      );
    }
  }

  /// Restore from a backup file picked by user.
  Future<RestoreResult?> pickAndRestore() async {
    // Pick file - use FileType.any for iOS compatibility
    // iOS doesn't recognize custom UTIs, so we validate extension after selection
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final filePath = result.files.first.path;
    if (filePath == null) {
      return RestoreResult.failure('파일 경로를 가져올 수 없습니다.');
    }

    // Validate file extension
    final expectedExtension = '.${BackupService.backupExtension}';
    if (!filePath.toLowerCase().endsWith(expectedExtension.toLowerCase())) {
      return RestoreResult.failure(
        '올바른 백업 파일이 아닙니다.\n$expectedExtension 확장자 파일을 선택해주세요.',
      );
    }

    return restoreFromFile(File(filePath));
  }

  /// Restore from a specific backup file.
  Future<RestoreResult> restoreFromFile(File backupFile) async {
    final current = state.value ?? const BackupState();

    // Set restoring state
    state = AsyncValue.data(
      current.copyWith(isRestoring: true, progress: 0.0, lastError: null),
    );

    try {
      final result = await _service.restoreFromBackup(
        backupFile,
        onProgress: (progress, status) {
          final currentState = state.value ?? const BackupState();
          state = AsyncValue.data(currentState.copyWith(progress: progress));
        },
      );

      // Refresh state after restore
      final newState = await _service.getBackupState();
      state = AsyncValue.data(
        newState.copyWith(
          isRestoring: false,
          progress: null,
          lastError: result.success ? null : result.errorMessage,
        ),
      );

      return result;
    } catch (e) {
      final currentState = state.value ?? const BackupState();
      state = AsyncValue.data(
        currentState.copyWith(
          isRestoring: false,
          progress: null,
          lastError: e.toString(),
        ),
      );
      return RestoreResult.failure(e.toString());
    }
  }

  /// Delete a backup file.
  Future<void> deleteBackup(BackupFileInfo backup) async {
    await _service.deleteBackup(backup.file);
    ref.invalidate(backupListProvider);
  }

  /// Refresh backup state.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getBackupState());
    ref.invalidate(backupListProvider);
  }

  /// Clear last error.
  void clearError() {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(lastError: null));
    }
  }
}
