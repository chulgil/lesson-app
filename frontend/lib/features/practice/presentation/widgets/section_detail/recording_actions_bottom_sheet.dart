// Recording actions bottom sheet — swipe consistency audit 2026-06-10 §2 원칙 2.
//
// Replaces the legacy PopupMenuButton for recording rows. The row swipe
// reserves the destructive [삭제] action; this bottom sheet collects the
// remaining multi-action choices ([대표설정], [공유]) plus a redundant
// [삭제] entry so users who open the sheet still see the full menu.
import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';

/// Actions presented in [RecordingActionsBottomSheet].
enum RecordingActionResult { setRepresentative, share, delete }

/// Modal bottom sheet that surfaces the multi-action menu for a recording row.
///
/// Per swipe consistency audit (§2 원칙 2), the swipe handle is reserved for
/// the destructive single action, while richer choices live in this sheet so
/// the row stays tap-friendly on small screens.
class RecordingActionsBottomSheet extends StatelessWidget {
  const RecordingActionsBottomSheet({
    super.key,
    required this.canSetRepresentative,
  });

  /// Whether the [대표 녹음으로 설정] entry should be rendered.
  final bool canSetRepresentative;

  /// Shows the sheet and returns the picked action, or `null` if dismissed.
  static Future<RecordingActionResult?> show(
    BuildContext context, {
    required bool canSetRepresentative,
  }) {
    return showModalBottomSheet<RecordingActionResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      builder: (ctx) => RecordingActionsBottomSheet(
        canSetRepresentative: canSetRepresentative,
      ),
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
                AppStrings.recordingActionsSheetTitle,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (canSetRepresentative)
              _ActionTile(
                icon: Icons.star_outline,
                label: AppStrings.practiceSetRepresentative,
                onTap: () => Navigator.of(
                  context,
                ).pop(RecordingActionResult.setRepresentative),
              ),
            _ActionTile(
              icon: Icons.share,
              label: AppStrings.practiceShareExternal,
              onTap: () =>
                  Navigator.of(context).pop(RecordingActionResult.share),
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              label: AppStrings.swipeActionDelete,
              isDestructive: true,
              onTap: () =>
                  Navigator.of(context).pop(RecordingActionResult.delete),
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
