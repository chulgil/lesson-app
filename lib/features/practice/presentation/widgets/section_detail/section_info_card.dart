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
  final String? repertoireName; // Repertoire name to display above piece name
  final DateTime? repertoireStartDate; // Fallback for section start date
  final DateTime? selectedDate; // Currently selected date from calendar

  const SectionInfoCard({
    super.key,
    required this.section,
    this.repertoireName,
    this.repertoireStartDate,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final rangeText = section.rangeType != SectionRangeType.full
        ? section.rangeText
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
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
                  // Repertoire name + date info (same line)
                  if (repertoireName != null) ...[
                    Text(
                      '$repertoireName · ${_formatPeriodShort()}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ] else ...[
                    Text(
                      _formatPeriodShort(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Piece name + range info (same line)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          section.pieceName,
                          style: AppTypography.headingMedium,
                        ),
                      ),
                      if (rangeText != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          rangeText,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Section name (if exists)
                  if (section.sectionName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      section.sectionName!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriodShort() {
    // Use section's startDate, fallback to repertoire's startDate
    final effectiveStartDate = section.startDate ?? repertoireStartDate;
    final startStr = effectiveStartDate != null
        ? '${effectiveStartDate.year}.${effectiveStartDate.month.toString().padLeft(2, '0')}.${effectiveStartDate.day.toString().padLeft(2, '0')}'
        : '시작일 미정';

    if (section.endDate == null) {
      return '$startStr ~ 진행중';
    }

    final endStr =
        '${section.endDate!.year}.${section.endDate!.month.toString().padLeft(2, '0')}.${section.endDate!.day.toString().padLeft(2, '0')}';
    return '$startStr ~ $endStr';
  }
}
