import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/notebook_glyph.dart';

/// Overlay shown when [YoutubeAdDetector] flags an ad as playing.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §3.5 #509
///
/// Tokens: paper background, paperAccent border, BorderRadius.zero (notebook).
class AdNoticeOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const AdNoticeOverlay({super.key, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border(
          left: BorderSide(color: AppColors.paperAccent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                NotebookGlyph.referenceMark,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.youtubeAdDetected,
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.youtubeAdHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.youtubeAdSkippable,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onResume,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(AppStrings.youtubeAdResume),
            ),
          ),
        ],
      ),
    );
  }
}
