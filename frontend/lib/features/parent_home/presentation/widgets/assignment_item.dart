import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

/// Assignment item widget for parent dashboard
class AssignmentItem extends StatelessWidget {
  final String title;
  final String dueDate;
  final bool isCompleted;
  final String priority;

  const AssignmentItem({
    super.key,
    required this.title,
    required this.dueDate,
    required this.isCompleted,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.paperOk : AppColors.paperDark,
              shape: BoxShape.circle,
              border:
                  isCompleted
                      ? null
                      : Border.all(color: AppColors.inkQuaternary),
            ),
            child:
                isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? AppColors.inkTertiary : AppColors.ink,
                  ),
                ),
                Text(
                  dueDate,
                  style: AppTypography.caption.copyWith(
                    color:
                        isCompleted
                            ? AppColors.paperOk
                            : dueDate.contains('내일')
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isCompleted && priority == 'must')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              // Notebook × Score: "필수" = 긴급도 마지널리아 → Gaegu handEmphasis (§1.1 #4 · §7.108).
              child: Text('필수', style: NotebookTypography.handEmphasis),
            ),
        ],
      ),
    );
  }
}
