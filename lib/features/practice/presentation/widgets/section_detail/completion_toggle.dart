// Completion toggle widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice_repertoire.dart';

/// Completion toggle widget for marking section as complete
class CompletionToggle extends StatelessWidget {
  final PracticeSection section;
  final VoidCallback onToggle;

  const CompletionToggle({
    super.key,
    required this.section,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasRepresentativeRecording = section.representativeRecording != null;

    return Card(
      color: section.isCompleted
          ? AppColors.success.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Icon(
                section.isCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: section.isCompleted
                    ? AppColors.success
                    : AppColors.textTertiaryLight,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.isCompleted ? '연습 완료!' : '연습 완료로 표시',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: section.isCompleted
                            ? AppColors.success
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      section.isCompleted
                          ? '탭하여 완료 취소'
                          : '탭하여 이 섹션을 완료로 표시하세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    // Show sharing message when there's a representative recording
                    if (!section.isCompleted && hasRepresentativeRecording) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Row(
                        children: [
                          Icon(
                            Icons.share,
                            size: 12,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '완료 시 대표녹음이 선생님께 공유됩니다',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
