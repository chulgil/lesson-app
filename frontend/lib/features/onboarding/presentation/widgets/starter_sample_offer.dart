import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../providers/starter_sample_providers.dart';

/// Secondary CTA under the "학생이 없습니다" empty state (UXB-1).
///
/// A teacher with zero students cannot tell what the app looks like when it is
/// in use. One tap fills the shell with a clearly labelled example. Strictly
/// opt-in — nothing is written until this button is pressed.
class StarterSampleOffer extends ConsumerWidget {
  const StarterSampleOffer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(starterSampleOfferVisibleProvider).valueOrNull;
    if (visible != true) return const SizedBox.shrink();

    final progress = ref.watch(starterSampleControllerProvider);
    final isBusy = progress.isLoading;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.starterSampleOfferHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space1),
          TextButton.icon(
            onPressed: isBusy ? null : () => _create(context, ref),
            // 테마 minimumSize 가 Size(infinity, h) 라 Column 의 loose 제약에서
            // 크래시한다 — 컴팩트 배치에는 항상 override (tech-patterns).
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              foregroundColor: AppColors.ink,
            ),
            icon:
                isBusy
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.auto_stories_outlined, size: 16),
            label: Text(
              isBusy
                  ? AppStrings.starterSampleCreating
                  : AppStrings.starterSampleOfferLabel,
              style: NotebookTypography.sectionLabel.copyWith(
                color: AppColors.ink,
              ),
            ),
          ),
          if (progress.hasError) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.starterSampleCreateFailed,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome =
        await ref.read(starterSampleControllerProvider.notifier).createSample();

    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          StarterSampleOutcome.created => AppStrings.starterSampleCreated,
          StarterSampleOutcome.failedWithResidue =>
            AppStrings.starterSampleCreateFailedResidue,
          _ => AppStrings.starterSampleCreateFailed,
        }),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
