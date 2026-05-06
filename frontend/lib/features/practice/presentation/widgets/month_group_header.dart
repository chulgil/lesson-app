// Month group header widget for repertoire timeline

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/staff_divider.dart';
import '../../domain/entities/repertoire_timeline.dart';
import '../extensions/practice_display_extensions.dart';

/// Divider-style header for a month group in the timeline
class MonthGroupHeader extends StatelessWidget {
  final MonthGroup monthGroup;

  const MonthGroupHeader({super.key, required this.monthGroup});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Notebook × Score: 새 월 그룹 = 새 악장 시작.
          const StaffDivider(),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(color: AppColors.paperAccent),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                monthGroup.label,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
              if (monthGroup.hasInProgress) ...[
                const SizedBox(width: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                  // "진행 중" = 시스템 자동 인디케이터 → Tier 4 Pretendard italic
                  // (README §1.1 4계층, §7.127 Gaegu 회피).
                  child: Text(
                    AppStrings.practiceInProgress,
                    style: NotebookTypography.indicatorLabel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
