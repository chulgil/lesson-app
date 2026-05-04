import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/roster_summary.dart';
import '../providers/student_roster_summary_provider.dart';

/// 수강 관리 탭 triage 배너 — 만료임박 / 입금대기 / 체험 3칸.
///
/// 선택된 카드에 형광펜(paperHighlight) 배경으로 시각 피드백 제공.
enum RosterTriageCategory { expiring, unpaid, trial }

class RosterTriageBanner extends ConsumerWidget {
  final void Function(RosterTriageCategory category, Set<String> studentIds)
      onFilterSelected;
  final RosterTriageCategory? selectedCategory;

  const RosterTriageBanner({
    super.key,
    required this.onFilterSelected,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(studentRosterSummaryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: summaryAsync.when(
        data: (summary) => _buildRow(summary),
        loading: () => _buildRow(RosterSummary.empty),
        error: (_, __) => _buildRow(RosterSummary.empty),
      ),
    );
  }

  Widget _buildRow(RosterSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _TriageCard(
            label: AppStrings.studentTriageExpiring,
            count: summary.expiringCount,
            isSelected: selectedCategory == RosterTriageCategory.expiring,
            onTap:
                summary.expiringCount > 0
                    ? () => onFilterSelected(
                          RosterTriageCategory.expiring,
                          summary.expiringStudentIds,
                        )
                    : null,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _TriageCard(
            label: AppStrings.studentTriageUnpaid,
            count: summary.unpaidCount,
            isSelected: selectedCategory == RosterTriageCategory.unpaid,
            onTap:
                summary.unpaidCount > 0
                    ? () => onFilterSelected(
                          RosterTriageCategory.unpaid,
                          summary.unpaidStudentIds,
                        )
                    : null,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _TriageCard(
            label: AppStrings.studentTriageTrial,
            count: summary.trialCount,
            isSelected: selectedCategory == RosterTriageCategory.trial,
            onTap:
                summary.trialCount > 0
                    ? () => onFilterSelected(
                          RosterTriageCategory.trial,
                          summary.trialStudentIds,
                        )
                    : null,
          ),
        ),
      ],
    );
  }
}

class _TriageCard extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TriageCard({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final borderColor =
        isSelected
            ? AppColors.paperAccent
            : isDisabled
                ? AppColors.inkQuaternary
                : AppColors.ink;
    final countColor =
        isSelected
            ? AppColors.paperAccent
            : isDisabled
                ? AppColors.inkTertiary
                : AppColors.ink;
    final labelColor =
        isDisabled ? AppColors.inkTertiary : AppColors.inkSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          // 선택 시 형광펜 배경 (Notebook × Score paperHighlight)
          color:
              isSelected
                  ? AppColors.paperHighlight.withValues(alpha: 0.3)
                  : AppColors.paper,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: AppTypography.headingMedium.copyWith(color: countColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
