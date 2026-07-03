import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/review_grade.dart';

/// The four SM-2 self-rating buttons shown once a flashcard is revealed (#1124).
///
/// Again / Hard / Good / Easy → [ReviewGrade]. Colour stays within the Notebook
/// palette (C8, ≤3 semantic inks): `again` vermilion (a miss) and `easy` green
/// (well known) carry meaning; `hard`/`good` are neutral ink shades. Each button
/// pins its minimum size so the compact row never hits the theme's ∞ min-width.
class ReviewGradeBar extends StatelessWidget {
  const ReviewGradeBar({super.key, required this.onGrade});

  final ValueChanged<ReviewGrade> onGrade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _button(
          ReviewGrade.again,
          AppStrings.vocabGradeAgain,
          AppColors.paperAccent,
        ),
        const SizedBox(width: AppSpacing.space2),
        _button(
          ReviewGrade.hard,
          AppStrings.vocabGradeHard,
          AppColors.inkSecondary,
        ),
        const SizedBox(width: AppSpacing.space2),
        _button(ReviewGrade.good, AppStrings.vocabGradeGood, AppColors.ink),
        const SizedBox(width: AppSpacing.space2),
        _button(ReviewGrade.easy, AppStrings.vocabGradeEasy, AppColors.paperOk),
      ],
    );
  }

  Widget _button(ReviewGrade grade, String label, Color color) => Expanded(
    child: OutlinedButton(
      onPressed: () => onGrade(grade),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        minimumSize: const Size(0, AppSpacing.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: NotebookTypography.sectionLabel.copyWith(color: color),
      ),
    ),
  );
}
