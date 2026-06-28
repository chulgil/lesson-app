// Completion toggle widget

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../../core/l10n/app_strings.dart';
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
    BuildContext context,
    DateTime date,
    bool hasRepresentativeRecording,
  ) {
    // Use date-specific completion status instead of global isCompleted
    final isCompleted = section.isCompletedForDate(date);

    return NotebookCard(
      color: isCompleted ? AppColors.paperOkSoft : null,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: isCompleted ? AppColors.paperOk : AppColors.inkTertiary,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted
                          ? AppStrings.practiceCompleteLabel
                          : AppStrings.practiceCompleteMarkLabel,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? AppColors.paperOk : AppColors.ink,
                      ),
                    ),
                    Text(
                      isCompleted
                          ? AppStrings.practiceCompleteUndoLabel
                          : AppStrings.practiceCompleteHintLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    if (!isCompleted && hasRepresentativeRecording) ...[
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
    BuildContext context,
    DateTime date,
    bool hasRepresentativeRecording,
  ) {
    final completedCount = section.getRepeatCompletedCount(date);
    final totalCount = section.repeatCount!;
    final isAllCompleted = completedCount >= totalCount;

    return NotebookCard(
      color: isAllCompleted ? AppColors.paperOkSoft : null,
      child: InkWell(
        onTap: onToggle,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space1,
                    ),
                    child: Opacity(
                      opacity: isCompleted ? 1.0 : 0.3,
                      child: Icon(
                        Icons.pets,
                        size: totalCount <= 5 ? 32 : 24,
                        color: isCompleted
                            ? AppColors.paperOk
                            : AppColors.inkTertiary,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Progress text (x/n format)
              Text(
                isAllCompleted
                    ? AppStrings.practiceRepeatAllDone(
                        completedCount,
                        totalCount,
                      )
                    : AppStrings.practiceRepeatTap(completedCount, totalCount),
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAllCompleted ? AppColors.paperOk : AppColors.ink,
                ),
              ),
              Text(
                isAllCompleted
                    ? AppStrings.practiceRepeatReset
                    : AppStrings.practiceRepeatDailyCount(totalCount),
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
        Icon(Icons.share, size: 12, color: AppColors.ink),
        const SizedBox(width: AppSpacing.space1),
        Text(
          AppStrings.practiceJournalShareHint,
          style: AppTypography.caption.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}
