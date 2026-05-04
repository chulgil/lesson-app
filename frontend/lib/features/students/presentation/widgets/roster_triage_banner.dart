import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/roster_summary.dart';
import '../providers/student_roster_summary_provider.dart';

/// 수강 관리 탭 triage 배너 — 만료임박 / 입금대기 / 체험 3칸.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.1
///
/// 설계 원칙:
/// - 각 칸 탭 시 [onFilterSelected] 콜백으로 해당 카테고리 ID 전달
/// - 카운트 0 → disabled (grey, non-clickable, 공간 유지)
/// - Notebook × Score 각진 원칙 (BorderRadius.zero, strokeAlignInside)
/// - 단일색 ink (Notebook 통일성 — 색상 과다 사용 방지)
enum RosterTriageCategory { expiring, unpaid, trial }

class RosterTriageBanner extends ConsumerWidget {
  final void Function(RosterTriageCategory category, Set<String> studentIds)
  onFilterSelected;

  const RosterTriageBanner({super.key, required this.onFilterSelected});

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
            label: '만료임박',
            count: summary.expiringCount,
            accent: AppColors.ink,
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
            label: '입금대기',
            count: summary.unpaidCount,
            accent: AppColors.ink,
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
            label: '체험중',
            count: summary.trialCount,
            accent: AppColors.ink,
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
  final Color accent;
  final VoidCallback? onTap;

  const _TriageCard({
    required this.label,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final borderColor = isDisabled ? AppColors.inkQuaternary : accent;
    final countColor = isDisabled ? AppColors.inkTertiary : accent;
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
          color: AppColors.paper,
          border: Border.all(
            color: borderColor,
            width: 1,
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
