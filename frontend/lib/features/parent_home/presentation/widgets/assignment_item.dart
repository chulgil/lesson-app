import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
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
          // §7.132: round → 사각 체크박스 (Notebook 메타포).
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.paperOk : AppColors.paperDark,
              border:
                  isCompleted
                      ? null
                      : Border.all(color: AppColors.inkQuaternary),
            ),
            child:
                isCompleted
                    ? const Icon(Icons.check, size: 16, color: AppColors.paper)
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
                    // H7 — 완료 항목은 잉크가 바랜 것처럼 물러난다. 체크박스와
                    // 완료 라벨(paperOk)은 "채워진" 게이지로 남는다.
                    decorationColor:
                        isCompleted ? AppColors.inkQuaternary : null,
                    color: isCompleted ? AppColors.inkQuaternary : AppColors.ink,
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
                borderRadius: BorderRadius.zero,
              ),
              // "필수" = 시스템 자동 긴급도 인디케이터 → Tier 4 Pretendard italic
              // (README §1.1 4계층, §7.127 Gaegu 회피).
              child: Text(
                AppStrings.parentHomeRequired,
                style: NotebookTypography.indicatorLabel,
              ),
            ),
        ],
      ),
    );
  }
}
