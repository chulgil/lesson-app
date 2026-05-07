// Backup settings screen for managing data backups.
//
// Part of the data backup feature (Issue #15).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/backup_state.dart';
import '../providers/backup_provider.dart';
import '../widgets/backup_widgets.dart';

/// Screen for backup settings and management.
class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupStateNotifierProvider);

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text(AppStrings.backupAppBarTitle),
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      body: backupState.when(
        data: (state) => _BackupContent(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  const Text(
                    AppStrings.backupErrorState,
                    style: TextStyle(color: AppColors.paperAccent),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  ElevatedButton(
                    onPressed:
                        () => ref.invalidate(backupStateNotifierProvider),
                    child: const Text(AppStrings.retry),
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
      onRefresh: () => ref.read(backupStateNotifierProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // Status card
          StatusCard(state: state),
          const SizedBox(height: AppSpacing.space6),

          // Progress indicator
          if (isOperating) ...[
            ProgressCard(state: state),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Error message
          if (state.lastError != null) ...[
            ErrorCard(
              error: state.lastError!,
              onDismiss:
                  () =>
                      ref
                          .read(backupStateNotifierProvider.notifier)
                          .clearError(),
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Actions
          ActionsSection(isOperating: isOperating),
          const SizedBox(height: AppSpacing.space6),

          // Backup list
          const BackupListSection(),
        ],
      ),
    );
  }
}
