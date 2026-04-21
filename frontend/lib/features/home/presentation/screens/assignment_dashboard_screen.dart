// Full assignment dashboard screen showing all students' weekly progress.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/assignment_summary_provider.dart';

/// Full assignment dashboard with all students' weekly progress.
class AssignmentDashboardScreen extends ConsumerWidget {
  const AssignmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklyAssignmentSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('이번 주 과제'),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.inkTertiary,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text('데이터를 불러올 수 없습니다', style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.space3),
                  OutlinedButton(
                    onPressed:
                        () => ref.invalidate(weeklyAssignmentSummaryProvider),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
        data: (summary) => _buildContent(context, summary),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeeklyAssignmentSummary summary) {
    if (summary.totalItems == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '이번 주 과제가 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final rate = summary.completionRate;
    final completedStudents =
        summary.incompleteStudents
            .where((s) => s.completedItems == s.totalItems)
            .toList();
    final incompleteStudents =
        summary.incompleteStudents
            .where((s) => s.completedItems < s.totalItems)
            .toList();

    return RefreshIndicator(
      onRefresh: () async {
        // Provider will be re-fetched on next build
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Overall progress card
          _buildOverallProgressCard(summary, rate),

          const SizedBox(height: AppSpacing.space5),

          // Stat cards row
          _buildStatCards(summary, incompleteStudents.length),

          const SizedBox(height: AppSpacing.space5),

          // Incomplete students section
          if (incompleteStudents.isNotEmpty) ...[
            _buildSectionHeader(
              '미완료 학생',
              '${incompleteStudents.length}명',
              AppColors.paperAccent,
            ),
            const SizedBox(height: AppSpacing.space3),
            ...incompleteStudents.map(
              (s) => _buildStudentCard(context, s, false),
            ),
          ],

          // Completed students section
          if (completedStudents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space5),
            _buildSectionHeader(
              '완료한 학생',
              '${completedStudents.length}명',
              AppColors.paperOk,
            ),
            const SizedBox(height: AppSpacing.space3),
            ...completedStudents.map(
              (s) => _buildStudentCard(context, s, true),
            ),
          ],

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(
    WeeklyAssignmentSummary summary,
    double rate,
  ) {
    final color =
        rate >= 0.8
            ? AppColors.paperOk
            : rate >= 0.5
            ? AppColors.paperAccent
            : AppColors.paperAccent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          // Circular progress
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: rate,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(rate * 100).round()}%',
                      style: AppTypography.headingLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '이번 주 완료율',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '${summary.completedItems} / ${summary.totalItems} 과제 완료',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(WeeklyAssignmentSummary summary, int incompleteCount) {
    final allStudentCount = summary.incompleteStudents.length;
    final completedCount = allStudentCount - incompleteCount;

    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            '전체 과제',
            '${summary.totalItems}',
            Icons.assignment_outlined,
            AppColors.ink,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _buildMiniStatCard(
            '완료 학생',
            '$completedCount',
            Icons.check_circle_outline,
            AppColors.paperOk,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _buildMiniStatCard(
            '미완료',
            '$incompleteCount',
            Icons.pending_outlined,
            incompleteCount > 0 ? AppColors.paperAccent : AppColors.paperOk,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(title, style: AppTypography.headingSmall),
        const SizedBox(width: AppSpacing.space2),
        Text(
          count,
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    StudentAssignmentStatus status,
    bool isCompleted,
  ) {
    final rate =
        status.totalItems > 0 ? status.completedItems / status.totalItems : 0.0;
    final color =
        isCompleted
            ? AppColors.paperOk
            : rate >= 0.5
            ? AppColors.paperAccent
            : AppColors.paperAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Material(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: InkWell(
          onTap:
              () => context.push(
                AppRoutes.studentDetail.replaceFirst(':id', status.studentId),
              ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(
                    status.studentName.isNotEmpty
                        ? status.studentName.substring(0, 1)
                        : '?',
                    style: AppTypography.bodyLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Name + task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.studentName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (status.mostUrgentItem != null && !isCompleted)
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

                // Progress indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${status.completedItems}/${status.totalItems}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: rate,
                          minHeight: 4,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: AppSpacing.space2),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.inkTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
