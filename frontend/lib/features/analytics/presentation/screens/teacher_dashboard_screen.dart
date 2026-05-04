// Teacher analytics dashboard screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../domain/entities/teacher_stats.dart';
import '../providers/analytics_providers.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/practice_ranking_list.dart';

/// Teacher analytics dashboard with monthly statistics.
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(teacherMonthlyStatsProvider(_selectedMonth));
    final monthLabel = formatYearMonth(_selectedMonth);

    return NotebookScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(AppStrings.analyticsAppBarTitle),
      ),
      body: Column(
        children: [
          // Month selector
          _buildMonthSelector(monthLabel),

          // Content
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.inkTertiary,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        Text(
                          AppStrings.cannotLoadData,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        OutlinedButton(
                          onPressed:
                              () => ref.invalidate(
                                teacherMonthlyStatsProvider(_selectedMonth),
                              ),
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
              data: (stats) => _buildDashboard(stats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(String label) {
    final isCurrentMonth =
        _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
          ),
          Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(TeacherMonthlyStats stats) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherMonthlyStatsProvider(_selectedMonth));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Stat cards grid (2x2)
          _buildStatCardGrid(stats),

          const SizedBox(height: AppSpacing.space5),

          // Revenue section
          _buildRevenueCard(stats),

          const SizedBox(height: AppSpacing.space5),

          // Lesson trend chart
          MonthlyTrendChart(trendData: stats.lessonTrend),

          const SizedBox(height: AppSpacing.space5),

          // Student stats
          _buildStudentSection(stats),

          const SizedBox(height: AppSpacing.space5),

          // Practice ranking
          PracticeRankingList(rankings: stats.practiceRanking),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildStatCardGrid(TeacherMonthlyStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: AppStrings.analyticsTotalLessons,
                value: AppStrings.usageCountShort(stats.totalLessons),
                subtitle: AppStrings.analyticsCompletedFormat(
                  stats.completedLessons,
                ),
                color: AppColors.paperAccent,
                icon: Icons.school,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: StatCard(
                title: AppStrings.subscriptionAttendanceRateLabel,
                value: '${stats.attendanceRate.toStringAsFixed(1)}%',
                subtitle: AppStrings.analyticsCancelledFormat(
                  stats.cancelledLessons,
                ),
                color: AppColors.paperOk,
                icon: Icons.check_circle_outline,
                onTap: () => context.push(AppRoutes.teacherAttendance),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: AppStrings.analyticsStudentCountLabel,
                value: AppStrings.peopleCount(stats.totalStudents),
                subtitle: AppStrings.analyticsNewStudentsFormat(
                  stats.newStudents,
                ),
                color: AppColors.ink,
                icon: Icons.people_outline,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: StatCard(
                title: AppStrings.analyticsMonthlyRevenue,
                value: formatWonWithComma(stats.totalRevenue),
                color: AppColors.paperAccent,
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(TeacherMonthlyStats stats) {
    final isPositive = stats.revenueChangePercent >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 교사 대시보드 섹션 헤더도 Playfair sectionTitle 로 통일.
        Text(
          AppStrings.analyticsRevenueSection,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.analyticsThisMonthRevenue,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      formatWonWithComma(stats.totalRevenue),
                      style: AppTypography.headingLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? AppColors.paperOk
                          : AppColors.paperAccent)
                      .withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color:
                          isPositive
                              ? AppColors.paperOk
                              : AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      AppStrings.analyticsRevenueChangeFormat(
                        stats.revenueChangePercent,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            isPositive
                                ? AppColors.paperOk
                                : AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSection(TeacherMonthlyStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.analyticsStudentSection,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Row(
            children: [
              _buildStudentStatItem(
                AppStrings.analyticsTotalStudentsLabel,
                AppStrings.peopleCount(stats.totalStudents),
                AppColors.ink,
              ),
              _buildDivider(),
              _buildStudentStatItem(
                AppStrings.analyticsNewLabel,
                AppStrings.analyticsNewCountFormat(stats.newStudents),
                AppColors.paperOk,
              ),
              _buildDivider(),
              _buildStudentStatItem(
                AppStrings.analyticsChurnedLabel,
                stats.churnedStudents > 0
                    ? AppStrings.analyticsChurnedCountFormat(
                      stats.churnedStudents,
                    )
                    : AppStrings.peopleCount(0),
                stats.churnedStudents > 0
                    ? AppColors.paperAccent
                    : AppColors.inkTertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentStatItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.inkQuaternary);
  }
}
