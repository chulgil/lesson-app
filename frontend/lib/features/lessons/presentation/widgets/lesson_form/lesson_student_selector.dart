import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'lesson_student_info.dart';

/// Student selector widget
class LessonStudentSelector extends StatelessWidget {
  final LessonStudentInfo? selectedStudent;
  final VoidCallback onTap;

  const LessonStudentSelector({
    super.key,
    required this.selectedStudent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              if (selectedStudent != null) ...[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: selectedStudent!.color.withValues(
                    alpha: 0.2,
                  ),
                  child: Text(
                    selectedStudent!.name[0],
                    style: AppTypography.headingSmall.copyWith(
                      color: selectedStudent!.color,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStudent!.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paperAccentSoft.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            child: Text(
                              selectedStudent!.instrument,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.paperAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Text(
                            selectedStudent!.currentPiece,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.paperDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add, color: AppColors.inkTertiary),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    '학생을 선택하세요',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
              ],
              Icon(Icons.chevron_right, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
