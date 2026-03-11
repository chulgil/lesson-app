import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/assignment_summary_provider.dart';

/// Assignment progress summary section for home dashboard.
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
    final color = rate >= 0.8
        ? AppColors.success
        : rate >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.assignment_outlined, size: 20, color: color),
            const SizedBox(width: AppSpacing.space2),
            Text('이번 주 과제', style: AppTypography.headingSmall),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  context.push(AppRoutes.assignmentDashboard),
              child: const Text('전체보기'),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space3),

        // Progress card
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar with label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '완료율',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '${(rate * 100).round()}% (${summary.completedItems}/${summary.totalItems})',
                    style: AppTypography.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rate,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),

              // Incomplete students list (max 3)
              if (summary.incompleteStudents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '미완료 학생',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                ...summary.incompleteStudents.take(3).map(
                  (s) => _buildStudentRow(context, s),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(BuildContext context, StudentAssignmentStatus status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: InkWell(
        onTap: () => context.push(AppRoutes.studentDetail.replaceFirst(':id', status.studentId)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space1,
            horizontal: AppSpacing.space1,
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  status.studentName.isNotEmpty
                      ? status.studentName.substring(0, 1)
                      : '?',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),

              // Name + task
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.studentName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (status.mostUrgentItem != null)
                      Text(
                        status.mostUrgentItem!.title,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Completion status
              Text(
                '${status.completedItems}/${status.totalItems}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
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
