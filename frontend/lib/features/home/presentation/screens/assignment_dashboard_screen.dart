// Full assignment dashboard screen showing all students' weekly progress.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../providers/assignment_summary_provider.dart';

/// Full assignment dashboard with all students' weekly progress.
class AssignmentDashboardScreen extends ConsumerWidget {
  const AssignmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklyAssignmentSummaryProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.weeklyAssignmentTitle,
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.inkTertiary),
              const SizedBox(height: AppSpacing.space3),
              Text(AppStrings.cannotLoadData, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.space3),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(weeklyAssignmentSummaryProvider),
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
              AppStrings.weeklyAssignmentEmpty,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.addLesson),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(AppStrings.lessonAddTitle),
            ),
          ],
        ),
      );
    }

    final rate = summary.completionRate;
    final completedStudents = summary.incompleteStudents
        .where((s) => s.completedItems == s.totalItems)
        .toList();
    final incompleteStudents = summary.incompleteStudents
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
              AppStrings.incompleteStudentsLabel,
              AppStrings.peopleCount(incompleteStudents.length),
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
              AppStrings.completedStudentsLabel,
              AppStrings.peopleCount(completedStudents.length),
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
    final color = rate >= 0.8
        ? AppColors.paperOk
        : rate >= 0.5
        ? AppColors.paperAccent
        : AppColors.paperAccent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.paper,
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
            AppStrings.weeklyCompletionRate,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.assignmentCompletionFormat(
              summary.completedItems,
              summary.totalItems,
            ),
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
            AppStrings.totalAssignmentsLabel,
            '${summary.totalItems}',
            Icons.assignment_outlined,
            AppColors.ink,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _buildMiniStatCard(
            AppStrings.completedStudentsShort,
            '$completedCount',
            Icons.check_circle_outline,
            AppColors.paperOk,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _buildMiniStatCard(
            AppStrings.incompleteShort,
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08)),
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
          decoration: BoxDecoration(color: color),
        ),
        const SizedBox(width: AppSpacing.space2),
        // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
        Text(title, style: NotebookTypography.sectionTitle),
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
    final rate = status.totalItems > 0
        ? status.completedItems / status.totalItems
        : 0.0;
    final color = isCompleted
        ? AppColors.paperOk
        : rate >= 0.5
        ? AppColors.paperAccent
        : AppColors.paperAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Material(
        color: AppColors.paper,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.studentDetail.replaceFirst(':id', status.studentId),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
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
                      // §7.130: 선생님 작성 과제 제목 → Tier 1 Gaegu hand.
                      if (status.mostUrgentItem != null && !isCompleted)
                        Text(
                          status.mostUrgentItem!.title,
                          style: NotebookTypography.hand.copyWith(
                            fontSize: 12,
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
