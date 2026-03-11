// Backup settings screen for managing data backups.
//
// Part of the data backup feature (Issue #15).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/backup_state.dart';
import '../providers/backup_provider.dart';
import '../widgets/backup_widgets.dart';

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
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('오류가 발생했습니다.', style: TextStyle(color: AppColors.error)),
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
          StatusCard(state: state),
          const SizedBox(height: 24),

          // Progress indicator
          if (isOperating) ...[
            ProgressCard(state: state),
            const SizedBox(height: 24),
          ],

          // Error message
          if (state.lastError != null) ...[
            ErrorCard(
              error: state.lastError!,
              onDismiss: () =>
                  ref.read(backupStateProvider.notifier).clearError(),
            ),
            const SizedBox(height: 24),
          ],

          // Actions
          ActionsSection(isOperating: isOperating),
          const SizedBox(height: 24),

          // Backup list
          const BackupListSection(),
        ],
      ),
    );
  }
}
