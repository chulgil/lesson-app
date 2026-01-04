// Section info card widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice_repertoire.dart';

/// Section info card showing piece name, measure range, repeat settings, and period
class SectionInfoCard extends StatelessWidget {
  final PracticeSection section;
  final VoidCallback? onEditTap;

  const SectionInfoCard({
    super.key,
    required this.section,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Piece name and edit button
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
                if (onEditTap != null)
                  TextButton(
                    onPressed: onEditTap,
                    child: const Text('편집'),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space4),

            // Section details
            _buildInfoRow(
              icon: Icons.straighten,
              label: section.measureRangeText,
            ),

            // Repeat info (isRepeat)
            if (section.isRepeat) ...[
              const SizedBox(height: AppSpacing.space2),
              _buildInfoRow(
                icon: Icons.repeat,
                label: '매일 반복',
                iconColor: AppColors.success,
              ),
            ],

            // N회 반복 (repeatCount)
            if (section.hasRepeatCount) ...[
              const SizedBox(height: AppSpacing.space2),
              _buildInfoRow(
                emoji: '🐾',
                label: '${section.repeatCount}회 반복',
              ),
            ],

            // Period (startDate ~ endDate)
            const SizedBox(height: AppSpacing.space2),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: _formatPeriod(),
            ),
          ],
        ),
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
    final startStr = section.startDate != null
        ? '${section.startDate!.year}.${section.startDate!.month.toString().padLeft(2, '0')}.${section.startDate!.day.toString().padLeft(2, '0')}'
        : '시작일 미정';

    if (section.endDate == null) {
      return '$startStr ~ 진행중';
    }

    final endStr =
        '${section.endDate!.year}.${section.endDate!.month.toString().padLeft(2, '0')}.${section.endDate!.day.toString().padLeft(2, '0')}';
    return '$startStr ~ $endStr';
  }
}
