import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../providers/assignment_summary_provider.dart';

/// Assignment progress summary — **Notebook × Score 스타일**.
///
/// 종이 위의 "주간 과제표":
/// - 섹션 헤더: uppercase + 1px 잉크 rule
/// - 진행률: ink 단색 + paperDark 트랙 (3색 원칙 준수)
/// - 학생 리스트: paperDark 아바타, ink 텍스트
class AssignmentSummarySection extends ConsumerWidget {
  const AssignmentSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklyAssignmentSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (summary.totalItems == 0) return const SizedBox.shrink();
        return _buildContent(context, summary);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context, WeeklyAssignmentSummary summary) {
    final rate = summary.completionRate;
    // 완료율 임계값만 paperAccent 로 경고 (50% 미만), 그 외 ink 단색
    final accentColor = rate < 0.5 ? AppColors.paperAccent : AppColors.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotebookSectionHeader(
          label: '이번 주 과제',
          trailing: TextButton(
            onPressed: () => context.push(AppRoutes.assignmentDashboard),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '전체보기',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        // Progress bar with label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '완료율',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            Text(
              '${(rate * 100).round()}% (${summary.completedItems}/${summary.totalItems})',
              style: AppTypography.bodySmall.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        // Thin linear bar — rectangular (no radius), ink stroke
        SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: rate,
            backgroundColor: AppColors.inkQuaternary,
            valueColor: AlwaysStoppedAnimation(accentColor),
            minHeight: 4,
          ),
        ),
        // Incomplete students list (max 3)
        if (summary.incompleteStudents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            '미완료 학생',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ...summary.incompleteStudents
              .take(3)
              .map((s) => _buildStudentRow(context, s)),
        ],
      ],
    );
  }

  Widget _buildStudentRow(
    BuildContext context,
    StudentAssignmentStatus status,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: InkWell(
        onTap:
            () => context.push(
              AppRoutes.studentDetail.replaceFirst(':id', status.studentId),
            ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space1,
            horizontal: AppSpacing.space1,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.paperDark,
                child: Text(
                  status.studentName.isNotEmpty
                      ? status.studentName.substring(0, 1)
                      : '?',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.studentName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (status.mostUrgentItem != null)
                      Text(
                        status.mostUrgentItem!.title,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                '${status.completedItems}/${status.totalItems}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
