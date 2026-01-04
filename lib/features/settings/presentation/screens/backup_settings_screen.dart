// Backup settings screen for managing data backups.
//
// Part of the data backup feature (Issue #15).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/services/backup_service.dart';
import '../../domain/entities/backup_state.dart';
import '../providers/backup_provider.dart';

/// Screen for backup settings and management.
class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('녹음 백업'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
      ),
      body: backupState.when(
        data: (state) => _BackupContent(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('오류: $e', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(backupStateProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupContent extends ConsumerWidget {
  final BackupState state;

  const _BackupContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOperating = state.isBackingUp || state.isRestoring;

    return RefreshIndicator(
      onRefresh: () => ref.read(backupStateProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          _StatusCard(state: state),
          const SizedBox(height: 24),

          // Progress indicator
          if (isOperating) ...[
            _ProgressCard(state: state),
            const SizedBox(height: 24),
          ],

          // Error message
          if (state.lastError != null) ...[
            _ErrorCard(
              error: state.lastError!,
              onDismiss: () =>
                  ref.read(backupStateProvider.notifier).clearError(),
            ),
            const SizedBox(height: 24),
          ],

          // Actions
          _ActionsSection(isOperating: isOperating),
          const SizedBox(height: 24),

          // Backup list
          const _BackupListSection(),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final BackupState state;

  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storage,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '백업 현황',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.lastBackupDate != null
                          ? '마지막 백업: ${dateFormat.format(state.lastBackupDate!)}'
                          : '백업 기록 없음',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.mic,
                  label: '녹음 파일',
                  value: '${state.recordingCount}개',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.borderLight,
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.folder,
                  label: '전체 용량',
                  value: state.formattedSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondaryLight, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final BackupState state;

  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.progress ?? 0.0;
    final label = state.isBackingUp ? '백업 중...' : '복원 중...';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.info,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.info.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorCard({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.error,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends ConsumerWidget {
  final bool isOperating;

  const _ActionsSection({required this.isOperating});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '수동 백업',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        // Create backup button
        _ActionButton(
          icon: Icons.upload_file,
          title: '전체 백업 내보내기',
          subtitle: '모든 녹음과 데이터를 ZIP으로 내보냅니다',
          onPressed: isOperating
              ? null
              : () => _createBackup(context, ref),
        ),
        const SizedBox(height: 12),
        // Restore button
        _ActionButton(
          icon: Icons.download,
          title: '백업에서 복원',
          subtitle: '이전 백업 파일에서 데이터를 복원합니다',
          onPressed: isOperating
              ? null
              : () => _restoreBackup(context, ref),
        ),
      ],
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 생성'),
        content: const Text(
          '모든 녹음과 데이터를 백업합니다.\n'
          '백업 파일을 공유하거나 저장할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('백업 시작'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(backupStateProvider.notifier).createAndShareBackup();
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 복원'),
        content: const Text(
          '백업 파일에서 데이터를 복원합니다.\n\n'
          '이미 존재하는 녹음은 건너뜁니다.\n'
          '새로운 녹음만 추가됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('파일 선택'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result =
          await ref.read(backupStateProvider.notifier).pickAndRestore();

      if (result != null && context.mounted) {
        _showRestoreResult(context, result);
      }
    }
  }

  void _showRestoreResult(BuildContext context, RestoreResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.success ? '복원 완료' : '복원 실패'),
        content: result.success
            ? Text(
                '복원이 완료되었습니다.\n\n'
                '복원된 녹음: ${result.restoredRecordings}개\n'
                '건너뛴 녹음: ${result.skippedRecordings}개\n'
                '복원된 데이터: ${result.restoredBoxEntries}개',
              )
            : Text(result.errorMessage ?? '알 수 없는 오류가 발생했습니다.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.textDisabledLight.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDisabled
                      ? AppColors.textDisabledLight
                      : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? AppColors.textDisabledLight
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDisabled
                            ? AppColors.textDisabledLight
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDisabled
                    ? AppColors.textDisabledLight
                    : AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupListSection extends ConsumerWidget {
  const _BackupListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupList = ref.watch(backupListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '저장된 백업',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        backupList.when(
          data: (backups) {
            if (backups.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 48,
                        color: AppColors.textTertiaryLight,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '저장된 백업이 없습니다',
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: backups.map((backup) {
                return _BackupItem(backup: backup);
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '백업 목록을 불러올 수 없습니다',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackupItem extends ConsumerWidget {
  final BackupFileInfo backup;

  const _BackupItem({required this.backup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.archive,
            color: AppColors.secondary,
          ),
        ),
        title: Text(
          dateFormat.format(backup.createdAt),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          backup.formattedSize,
          style: const TextStyle(
            color: AppColors.textSecondaryLight,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondaryLight),
          onSelected: (value) async {
            if (value == 'restore') {
              await _restoreFromBackup(context, ref);
            } else if (value == 'share') {
              await _shareBackup(context);
            } else if (value == 'delete') {
              await _deleteBackup(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, size: 20),
                  SizedBox(width: 8),
                  Text('복원'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('공유'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreFromBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 복원'),
        content: const Text(
          '이 백업에서 데이터를 복원하시겠습니까?\n\n'
          '이미 존재하는 녹음은 건너뜁니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('복원'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(backupStateProvider.notifier)
          .restoreFromFile(backup.file);

      if (context.mounted) {
        _showRestoreResult(context, result);
      }
    }
  }

  void _showRestoreResult(BuildContext context, RestoreResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.success ? '복원 완료' : '복원 실패'),
        content: result.success
            ? Text(
                '복원이 완료되었습니다.\n\n'
                '복원된 녹음: ${result.restoredRecordings}개\n'
                '건너뛴 녹음: ${result.skippedRecordings}개\n'
                '복원된 데이터: ${result.restoredBoxEntries}개',
              )
            : Text(result.errorMessage ?? '알 수 없는 오류가 발생했습니다.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareBackup(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backup.file.path)],
        subject: '레슨 앱 백업',
        text: '레슨 앱 녹음 데이터 백업 파일입니다.',
      ),
    );
  }

  Future<void> _deleteBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 삭제'),
        content: const Text('이 백업을 삭제하시겠습니까?\n삭제된 백업은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(backupStateProvider.notifier).deleteBackup(backup);
    }
  }
}
