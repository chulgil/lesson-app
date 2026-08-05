import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/vocab_card.dart';

/// A tappable flashcard: the word ([VocabCard.front]) and, once revealed, its
/// meaning plus optional example and memo (#1124).
///
/// Reveal is parent-controlled ([showAnswer]) so the review page resets it per
/// card; tapping anywhere calls [onTap] to toggle. Content is min-height — the
/// page centers it inside a scroll view so long entries never overflow.
class FlashcardWidget extends StatelessWidget {
  const FlashcardWidget({
    super.key,
    required this.card,
    required this.showAnswer,
    required this.onTap,
  });

  final VocabCard card;
  final bool showAnswer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space6),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.front,
              style: NotebookTypography.pieceTitle.copyWith(
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            if (!showAnswer) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppStrings.vocabTapToReveal,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.space4),
              Container(height: 1, color: AppColors.inkQuaternary),
              const SizedBox(height: AppSpacing.space4),
              Text(
                card.back,
                style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              if (card.example != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  card.example!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (card.memo != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  card.memo!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
