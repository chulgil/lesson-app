// Backup item actions bottom sheet — swipe consistency followup audit #668 D6.
//
// Replaces the legacy PopupMenuButton for backup rows in backup_widgets.dart.
// The row swipe reserves the destructive [삭제] action; this bottom sheet
// collects the remaining multi-action choices ([복원], [공유]) plus a redundant
// [삭제] entry so users who open the sheet still see the full menu.
import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Actions presented in [BackupItemActionsBottomSheet].
enum BackupItemActionResult { restore, share, delete }

/// Modal bottom sheet that surfaces the multi-action menu for a backup row.
///
/// Per swipe consistency audit (§2 원칙 2), the swipe handle is reserved for
/// the destructive single action, while richer choices live in this sheet so
/// the row stays tap-friendly on small screens.
class BackupItemActionsBottomSheet extends StatelessWidget {
  const BackupItemActionsBottomSheet({super.key});

  /// Shows the sheet and returns the picked action, or `null` if dismissed.
  ///
  /// build() 가 [NotebookBottomSheet] surface 를 직접 소유하므로
  /// [showNotebookModalBottomSheet] (custom-body 변형) 로 라우트한다.
  static Future<BackupItemActionResult?> show(BuildContext context) {
    return showNotebookModalBottomSheet<BackupItemActionResult>(
      context: context,
      builder: (ctx) => const BackupItemActionsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotebookBottomSheet(
      showHandle: false,
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: BottomSheetHandle()),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.space2,
                AppSpacing.screenPadding,
                AppSpacing.space3,
              ),
              child: Text(
                AppStrings.backupActionsSheetTitle,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _ActionTile(
              icon: Icons.restore,
              label: AppStrings.backupActionsRestore,
              onTap:
                  () =>
                      Navigator.of(context).pop(BackupItemActionResult.restore),
            ),
            _ActionTile(
              icon: Icons.share,
              label: AppStrings.backupActionsShare,
              onTap:
                  () => Navigator.of(context).pop(BackupItemActionResult.share),
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              label: AppStrings.swipeActionDelete,
              isDestructive: true,
              onTap:
                  () =>
                      Navigator.of(context).pop(BackupItemActionResult.delete),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.paperAccent : AppColors.ink;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(color: color),
      ),
      onTap: onTap,
    );
  }
}
