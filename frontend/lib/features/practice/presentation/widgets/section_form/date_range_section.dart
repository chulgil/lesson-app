// Common date range section widget for repertoire and section forms

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import 'date_row.dart';

/// Reusable date range section matching repertoire detail screen style
/// Used in repertoire detail, add section, and edit section screens
class DateRangeSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;
  final VoidCallback? onEndDateClear;

  /// Placeholder for start date when null (e.g., '레퍼토리 시작일 사용')
  final String? startDatePlaceholder;

  /// Placeholder for end date when null (e.g., '설정 안함 (매일 반복)')
  final String endDatePlaceholder;

  /// Whether to show hint message below end date
  final bool showHintMessage;

  /// Custom hint message when end date is null
  final String? endDateNullHint;

  /// Custom hint message when end date is set
  final String? endDateSetHint;

  const DateRangeSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
    this.onEndDateClear,
    this.startDatePlaceholder,
    this.endDatePlaceholder = AppStrings.practiceNotSet,
    this.showHintMessage = false,
    this.endDateNullHint,
    this.endDateSetHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.date_range, color: AppColors.paperAccent),
              const SizedBox(width: AppSpacing.space2),
              // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle
              // 로 통일 (§7.17).
              Text(
                AppStrings.practicePeriodSectionTitle,
                style: NotebookTypography.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // Start Date
          DateRow(
            label: AppStrings.practiceStartDateLabel,
            date: startDate,
            placeholder: startDatePlaceholder,
            onTap: onStartDateTap,
          ),

          const SizedBox(height: AppSpacing.space3),

          // End Date
          DateRow(
            label: AppStrings.practiceEndDateLabel,
            date: endDate,
            placeholder: endDatePlaceholder,
            onTap: onEndDateTap,
            canClear: endDate != null,
            onClear: onEndDateClear,
          ),

          // Hint message
          if (showHintMessage) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Icon(
                  endDate == null ? Icons.repeat : Icons.event_available,
                  size: 16,
                  color: AppColors.inkTertiary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  endDate == null
                      ? (endDateNullHint ?? '종료일 미설정 시 매일 반복됩니다')
                      : (endDateSetHint ?? '종료일까지만 연습 목록에 표시됩니다'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
