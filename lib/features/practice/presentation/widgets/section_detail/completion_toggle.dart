// Completion toggle widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice_repertoire.dart';

/// Completion toggle widget for marking section as complete
/// Supports both standard toggle and N회 반복 mode with 🐾 paw stamps
class CompletionToggle extends StatelessWidget {
  final PracticeSection section;
  final VoidCallback onToggle;
  final DateTime? selectedDate; // For date-specific completion tracking

  const CompletionToggle({
    super.key,
    required this.section,
    required this.onToggle,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final hasRepresentativeRecording = section.representativeRecording != null;
    final today = selectedDate ?? DateTime.now();

    // Check if N회 반복 mode
    if (section.hasRepeatCount) {
      return _buildRepeatCountCard(context, today, hasRepresentativeRecording);
    }

    // Standard toggle mode
    return _buildStandardCard(context, hasRepresentativeRecording);
  }

  Widget _buildStandardCard(BuildContext context, bool hasRepresentativeRecording) {
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

  Widget _buildRepeatCountCard(BuildContext context, DateTime date, bool hasRepresentativeRecording) {
    final completedCount = section.getRepeatCompletedCount(date);
    final totalCount = section.repeatCount!;
    final isAllCompleted = completedCount >= totalCount;

    return Card(
      color: isAllCompleted
          ? AppColors.success.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            children: [
              // Paw stamps row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalCount, (index) {
                  final isCompleted = index < completedCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Opacity(
                      opacity: isCompleted ? 1.0 : 0.3,
                      child: Text(
                        '🐾',
                        style: TextStyle(
                          fontSize: totalCount <= 5 ? 28 : 20,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Status text
              Text(
                isAllCompleted
                    ? '오늘 연습 완료! ($completedCount/$totalCount회)'
                    : '탭하여 연습 기록하기 ($completedCount/$totalCount회)',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAllCompleted
                      ? AppColors.success
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                isAllCompleted
                    ? '탭하여 초기화'
                    : '하루 $totalCount회 반복 연습',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              // Show sharing message when complete and there's a representative recording
              if (isAllCompleted && hasRepresentativeRecording) ...[
                const SizedBox(height: AppSpacing.space2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share,
                      size: 12,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '대표녹음이 선생님께 공유됩니다',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
