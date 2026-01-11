// Section info card widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice_repertoire.dart';
import '../../../domain/entities/practice_repertoire.dart';

/// Section info card showing piece name, measure range, repeat settings, and period
class SectionInfoCard extends StatelessWidget {
  final PracticeSection section;
  final DateTime? repertoireStartDate; // Fallback for section start date
  final DateTime? selectedDate; // Currently selected date from calendar

  const SectionInfoCard({
    super.key,
    required this.section,
    this.repertoireStartDate,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected date badge (if viewing from calendar)
            if (selectedDate != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      _formatSelectedDate(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            // Header: Piece name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.pieceName,
                        style: AppTypography.headingMedium,
                      ),
                      if (section.sectionName != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondaryLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          child: Text(
                            section.sectionName!,
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space4),

            // Section details - range info (only if not "전체")
            if (section.rangeType != SectionRangeType.full) ...[
              _buildInfoRow(
                icon: Icons.straighten,
                label: section.rangeText,
              ),
              const SizedBox(height: AppSpacing.space2),
            ],

            // N회 반복 (repeatCount)
            if (section.hasRepeatCount) ...[
              _buildInfoRow(
                emoji: '🐾',
                label: '${section.repeatCount}회 반복',
              ),
              const SizedBox(height: AppSpacing.space2),
            ],

            // Period (startDate ~ endDate)
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: _formatPeriod(),
            ),

            const SizedBox(height: AppSpacing.space4),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space4),

            // Practice stats
            Text(
              '연습 통계',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Stats row
            Row(
              children: [
                // Practice count
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.repeat,
                    label: '연습 횟수',
                    value: '${section.practiceCount}회',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                // Total practice time
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    label: '총 연습 시간',
                    value: section.formattedTotalTime,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),

            // Target progress (if set)
            if (section.hasTargetPracticeTime) ...[
              const SizedBox(height: AppSpacing.space3),
              _buildProgressBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.space1),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = section.practiceProgress.clamp(0.0, 1.0);
    final isAchieved = section.isTargetAchieved;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: isAchieved
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: isAchieved
            ? Border.all(color: AppColors.success.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAchieved ? Icons.check_circle : Icons.flag,
                    size: 14,
                    color: isAchieved ? AppColors.success : AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    '목표 연습시간',
                    style: AppTypography.caption.copyWith(
                      color: isAchieved
                          ? AppColors.success
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Text(
                section.practiceProgressText,
                style: AppTypography.caption.copyWith(
                  color: isAchieved
                      ? AppColors.success
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation(
                isAchieved ? AppColors.success : AppColors.secondary,
              ),
              minHeight: 8,
            ),
          ),
          if (isAchieved) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '🎉 목표 달성!',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    IconData? icon,
    String? emoji,
    required String label,
    Color? iconColor,
  }) {
    return Row(
      children: [
        if (emoji != null) ...[
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.space2),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: iconColor ?? AppColors.textSecondaryLight,
          ),
          const SizedBox(width: AppSpacing.space2),
        ],
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  String _formatPeriod() {
    // Use section's startDate, fallback to repertoire's startDate
    final effectiveStartDate = section.startDate ?? repertoireStartDate;
    final startStr = effectiveStartDate != null
        ? '${effectiveStartDate.year}.${effectiveStartDate.month.toString().padLeft(2, '0')}.${effectiveStartDate.day.toString().padLeft(2, '0')}'
        : '시작일 미정';

    if (section.endDate == null) {
      // Show "진행중 (매일반복)" when section repeats daily
      final suffix = section.isRepeat ? '진행중 (매일반복)' : '진행중';
      return '$startStr ~ $suffix';
    }

    final endStr =
        '${section.endDate!.year}.${section.endDate!.month.toString().padLeft(2, '0')}.${section.endDate!.day.toString().padLeft(2, '0')}';
    return '$startStr ~ $endStr';
  }

  String _formatSelectedDate() {
    if (selectedDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    );

    final difference = today.difference(selected).inDays;

    final dateStr =
        '${selectedDate!.month}월 ${selectedDate!.day}일';

    if (difference == 0) {
      return '$dateStr (오늘)';
    } else if (difference == 1) {
      return '$dateStr (어제)';
    } else if (difference == -1) {
      return '$dateStr (내일)';
    } else if (difference > 0) {
      return '$dateStr ($difference일 전)';
    } else {
      return '$dateStr (${-difference}일 후)';
    }
  }
}
