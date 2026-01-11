// Completion toggle widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice_repertoire.dart';

/// Completion toggle widget for marking section as complete
/// Supports:
/// - Standard toggle mode (simple on/off)
/// - N회 반복 mode (tap to increment paw stamps, shows progress x/n)
/// - 목표시간 mode (stepper to set count, then complete)
class CompletionToggle extends StatefulWidget {
  final PracticeSection section;
  final VoidCallback onToggle;
  final void Function(int count)? onCompleteWithCount; // For target time mode
  final DateTime? selectedDate; // For date-specific completion tracking

  const CompletionToggle({
    super.key,
    required this.section,
    required this.onToggle,
    this.onCompleteWithCount,
    this.selectedDate,
  });

  @override
  State<CompletionToggle> createState() => _CompletionToggleState();
}

class _CompletionToggleState extends State<CompletionToggle> {
  int _practiceCount = 1; // Default count for target time mode

  @override
  Widget build(BuildContext context) {
    final hasRepresentativeRecording =
        widget.section.representativeRecording != null;
    final today = widget.selectedDate ?? DateTime.now();

    // Priority: N회 반복 > 목표시간 > 일반
    if (widget.section.hasRepeatCount) {
      return _buildRepeatCountCard(context, today, hasRepresentativeRecording);
    }

    if (widget.section.hasTargetPracticeTime) {
      return _buildTargetTimeCard(context, hasRepresentativeRecording);
    }

    return _buildStandardCard(context, hasRepresentativeRecording);
  }

  /// Standard mode: Simple toggle
  Widget _buildStandardCard(
      BuildContext context, bool hasRepresentativeRecording) {
    return Card(
      color: widget.section.isCompleted
          ? AppColors.success.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: widget.onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Icon(
                widget.section.isCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: widget.section.isCompleted
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
                      widget.section.isCompleted ? '연습 완료!' : '연습 완료로 표시',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.section.isCompleted
                            ? AppColors.success
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      widget.section.isCompleted
                          ? '탭하여 완료 취소'
                          : '탭하여 이 섹션을 완료로 표시하세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    if (!widget.section.isCompleted &&
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
    final completedCount = widget.section.getRepeatCompletedCount(date);
    final totalCount = widget.section.repeatCount!;
    final isAllCompleted = completedCount >= totalCount;

    return Card(
      color: isAllCompleted ? AppColors.success.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: widget.onToggle,
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

              // Progress text (x/n format)
              Text(
                isAllCompleted
                    ? '오늘 연습 완료! ($completedCount/$totalCount회)'
                    : '탭하여 연습 기록 ($completedCount/$totalCount회)',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAllCompleted
                      ? AppColors.success
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                isAllCompleted ? '탭하여 초기화' : '하루 $totalCount회 반복',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
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

  /// 목표시간 mode: Stepper + complete button
  Widget _buildTargetTimeCard(
      BuildContext context, bool hasRepresentativeRecording) {
    final targetMinutes = (widget.section.targetPracticeSeconds! / 60).round();
    final totalMinutes = targetMinutes * _practiceCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          children: [
            // Header with target info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  '1회 연습시간: $targetMinutes분',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // Stepper row: - [count] +
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus button
                _buildStepperButton(
                  icon: Icons.remove,
                  enabled: _practiceCount > 1,
                  onPressed: () => setState(() => _practiceCount--),
                ),
                const SizedBox(width: AppSpacing.space4),

                // Count display with paw
                Column(
                  children: [
                    Text(
                      '🐾',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '$_practiceCount회',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.space4),

                // Plus button
                _buildStepperButton(
                  icon: Icons.add,
                  enabled: _practiceCount < 10,
                  onPressed: () => setState(() => _practiceCount++),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // Complete button with total time
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (widget.onCompleteWithCount != null) {
                    widget.onCompleteWithCount!(_practiceCount);
                  } else {
                    widget.onToggle();
                  }
                  setState(() => _practiceCount = 1);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space3,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 20),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '연습 완료',
                      style: AppTypography.button,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Text(
                        '+$totalMinutes분',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (hasRepresentativeRecording) ...[
              const SizedBox(height: AppSpacing.space2),
              _buildShareHint(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surfaceSecondaryLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? AppColors.primary : AppColors.textTertiaryLight,
            size: 24,
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
          color: AppColors.info,
        ),
        const SizedBox(width: 4),
        Text(
          '완료 시 대표녹음이 선생님께 공유됩니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}
