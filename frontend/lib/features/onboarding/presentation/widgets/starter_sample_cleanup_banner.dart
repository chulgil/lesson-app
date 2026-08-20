import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../providers/starter_sample_providers.dart';

/// One-tap cleanup for the starter sample (UXB-1).
///
/// Surfaces only once a real student exists, so the sample never competes with
/// an empty roster the teacher is still trying to fill. Hidden again the moment
/// the sample is gone.
class StarterSampleCleanupBanner extends ConsumerWidget {
  const StarterSampleCleanupBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(starterSampleCleanupVisibleProvider).valueOrNull;
    if (visible != true) return const SizedBox.shrink();

    final progress = ref.watch(starterSampleControllerProvider);
    final isBusy = progress.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              size: 16,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.starterSampleCleanupTitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            TextButton(
              onPressed: isBusy ? null : () => _confirmAndRemove(context, ref),
              // 테마 minimumSize 가 Size(infinity, h) 라 Row 의 loose 제약에서
              // 크래시한다 — 컴팩트 배치에는 항상 override (tech-patterns).
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                ),
                foregroundColor: AppColors.paperAccent,
              ),
              child: Text(
                AppStrings.starterSampleCleanupLabel,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndRemove(BuildContext context, WidgetRef ref) async {
    // Deleting a student is destructive even when it is only the sample, so the
    // same confirmation gate as every other roster deletion applies.
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.starterSampleCleanupConfirmTitle,
      message: AppStrings.starterSampleCleanupConfirmMessage,
      confirmLabel: AppStrings.starterSampleCleanupLabel,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final outcome =
        await ref.read(starterSampleControllerProvider.notifier).removeSample();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome == StarterSampleOutcome.removed
              ? AppStrings.starterSampleCleanupDone
              : AppStrings.starterSampleCleanupFailed,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
