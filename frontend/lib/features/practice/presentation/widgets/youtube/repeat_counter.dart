import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/notebook_bottom_sheet.dart';

/// Loop repeat counter — shows "completed / target" with a small progress bar.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.6, §7.4
class RepeatCounter extends StatelessWidget {
  final int completed;
  final int target;

  /// Tap callback for the target value (opens a 1–20 picker).
  final ValueChanged<int>? onTargetChanged;

  const RepeatCounter({
    super.key,
    required this.completed,
    required this.target,
    this.onTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clampedCompleted = completed.clamp(0, target);
    final progress = target > 0 ? clampedCompleted / target : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppStrings.youtubeLoopRepeatCountLabel,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          '$clampedCompleted',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.paperAccent,
            height: 1.0,
          ),
        ),
        Text(
          ' ${AppStrings.youtubeLoopCounterOf} ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTargetChanged == null
              ? null
              : () => _showTargetPicker(context, target, onTargetChanged!),
          child: Text(
            '$target',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Container(
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.inkQuaternary,
              borderRadius: BorderRadius.zero,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.paperAccent,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> _showTargetPicker(
    BuildContext context,
    int current,
    ValueChanged<int> onChanged,
  ) async {
    final selected = await showNotebookModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (_, i) {
                final value = i + 1;
                final isSelected = value == current;
                return ListTile(
                  title: Text(
                    '$value',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.paperAccent : AppColors.ink,
                      fontWeight: isSelected ? FontWeight.w700 : null,
                    ),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(value),
                );
              },
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }
}
