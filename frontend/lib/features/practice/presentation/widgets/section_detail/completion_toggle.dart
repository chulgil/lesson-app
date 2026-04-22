// Completion toggle widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/practice/domain/entities/practice_repertoire.dart';

/// Completion toggle widget for marking section as complete
/// Supports:
/// - Standard toggle mode (simple on/off)
/// - N회 반복 mode (tap to increment paw stamps, shows progress x/n)
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
    return _buildStandardCard(context, today, hasRepresentativeRecording);
  }

  /// Standard mode: Simple toggle (date-aware)
  Widget _buildStandardCard(
      BuildContext context, DateTime date, bool hasRepresentativeRecording) {
    // Use date-specific completion status instead of global isCompleted
    final isCompleted = section.isCompletedForDate(date);

    return Card(
      color: isCompleted
          ? AppColors.paperOk.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: isCompleted
                    ? AppColors.paperOk
                    : AppColors.inkTertiary,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? '연습 완료!' : '연습 완료로 표시',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.paperOk
                            : AppColors.ink,
                      ),
                    ),
                    Text(
                      isCompleted
                          ? '탭하여 완료 취소'
                          : '탭하여 이 섹션을 완료로 표시하세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    if (!isCompleted &&
                        hasRepresentativeRecording) ...[
                      const SizedBox(height: AppSpacing.space1),
                      _buildShareHint(),
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

  /// N회 반복 mode: Tap to increment, shows x/n progress
  Widget _buildRepeatCountCard(
      BuildContext context, DateTime date, bool hasRepresentativeRecording) {
    final completedCount = section.getRepeatCompletedCount(date);
    final totalCount = section.repeatCount!;
    final isAllCompleted = completedCount >= totalCount;

    return Card(
      color: isAllCompleted ? AppColors.paperOk.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            children: [
              // Paw stamps row showing progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalCount, (index) {
                  final isCompleted = index < completedCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
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

              // Progress text (x/n format)
              Text(
                isAllCompleted
                    ? '오늘 연습 완료! ($completedCount/$totalCount회)'
                    : '탭하여 연습 기록 ($completedCount/$totalCount회)',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAllCompleted
                      ? AppColors.paperOk
                      : AppColors.ink,
                ),
              ),
              Text(
                isAllCompleted ? '탭하여 초기화' : '하루 $totalCount회 반복',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),

              if (isAllCompleted && hasRepresentativeRecording) ...[
                const SizedBox(height: AppSpacing.space2),
                _buildShareHint(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.share,
          size: 12,
          color: AppColors.ink,
        ),
        const SizedBox(width: AppSpacing.space1),
        Text(
          '완료 시 대표녹음이 선생님께 공유됩니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
