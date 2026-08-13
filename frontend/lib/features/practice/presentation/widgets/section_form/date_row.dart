// Date row widget for section forms
// Matches the _buildDateRow pattern from repertoire_detail_screen

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Row-based date picker button matching repertoire detail screen style
/// Shows label on left, date on right with clear/chevron icon
class DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String? placeholder;
  final VoidCallback onTap;
  final bool canClear;
  final VoidCallback? onClear;

  const DateRow({
    super.key,
    required this.label,
    required this.date,
    this.placeholder,
    required this.onTap,
    this.canClear = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final showClearButton = canClear && date != null && onClear != null;

    // When clear button is shown, use separate tap areas
    if (showClearButton) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            // Tappable label and date area
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Row(
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${date!.year}년 ${date!.month}월 ${date!.day}일',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            // Clear button - using TextButton for better tap handling
            SizedBox(
              width: 32,
              height: 32,
              child: TextButton(
                onPressed: () {
                  onClear!();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor:
                      AppColors.inkBorder,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal mode - entire row is tappable
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const Spacer(),
              Text(
                date != null
                    ? '${date!.year}년 ${date!.month}월 ${date!.day}일'
                    : placeholder ?? '선택',
                style: AppTypography.bodyMedium.copyWith(
                  color: date != null
                      ? AppColors.ink
                      : AppColors.inkTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.inkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
