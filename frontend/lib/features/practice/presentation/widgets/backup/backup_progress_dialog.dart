// Modal progress dialog for practice §6.3 Phase 1 backup operations.
//
// Watches [backupControllerProvider] and renders a determinate progress bar
// plus the localized status message reported by [BackupService]. The dialog
// is non-dismissible while [BackupProgress.isRunning] is true; the caller
// pops it once the future completes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../providers/backup_provider.dart';

/// Modal progress UI driven by [backupControllerProvider].
///
/// [title] is shown above the progress bar (e.g. AppStrings.backupExporting).
class BackupProgressDialog extends ConsumerWidget {
  final String title;

  const BackupProgressDialog({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(backupControllerProvider);

    return PopScope(
      canPop: !progress.isRunning,
      child: AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(title, style: AppTypography.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: progress.progress,
              minHeight: 6,
              backgroundColor: AppColors.paperDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.paperAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              progress.status ?? AppStrings.backupPreparing,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (progress.progress != null) ...[
              const SizedBox(height: AppSpacing.space1),
              Text(
                '${((progress.progress ?? 0) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperPencil,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
