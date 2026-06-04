import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Which goal window triggered the celebration dialog.
enum GoalAchievementScope { daily, weekly }

/// Celebration dialog shown once when a daily or weekly practice goal is
/// achieved. The widget itself does not persist anything — the caller
/// (typically `GoalProgressWidget`) is responsible for marking the
/// achievement as shown via the storage provider before invoking this.
class GoalAchievedDialog extends StatelessWidget {
  final GoalAchievementScope scope;

  const GoalAchievedDialog({super.key, required this.scope});

  /// Convenience helper to show the dialog with notebook-style surface.
  static Future<void> show(
    BuildContext context, {
    required GoalAchievementScope scope,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => GoalAchievedDialog(scope: scope),
    );
  }

  String get _title => switch (scope) {
    GoalAchievementScope.daily => AppStrings.goalAchievedDailyTitle,
    GoalAchievementScope.weekly => AppStrings.goalAchievedWeeklyTitle,
  };

  String get _message => switch (scope) {
    GoalAchievementScope.daily => AppStrings.goalAchievedDailyMessage,
    GoalAchievementScope.weekly => AppStrings.goalAchievedWeeklyMessage,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Trophy-style celebration mark using app accent colors only.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: AppColors.paperAccent,
                size: AppSpacing.iconLG,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              _title,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              _message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space5),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  foregroundColor: AppColors.paper,
                  minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.goalAchievedConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
