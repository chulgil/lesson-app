import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../settings/settings_facade.dart';

class ReviewPromptCard extends ConsumerWidget {
  final int completedLessonCount;

  const ReviewPromptCard({super.key, required this.completedLessonCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldPrompt = ref.watch(
      shouldPromptForReviewProvider(completedLessonCount),
    );

    if (!shouldPrompt) {
      return const SizedBox.shrink();
    }

    return NotebookCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.thumb_up_outlined,
                  color: AppColors.paperAccent,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.reviewPromptTitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        AppStrings.reviewPromptSubtitle(completedLessonCount),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final client = ref.read(appReviewClientProvider);
                  final canRequest = await client.canRequestReview();
                  if (!canRequest || !context.mounted) {
                    return;
                  }
                  await client.requestReview();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.reviewPromptThanks)),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.reviewPromptAction,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
