// Teacher analytics dashboard screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
    final monthLabel = DateFormat('yyyy년 M월', 'ko').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('통계'),
      ),
      body: Column(
        children: [
          // Month selector
          _buildMonthSelector(monthLabel),

          // Content
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48,
                        color: AppColors.textTertiaryLight),
                    const SizedBox(height: AppSpacing.space3),
                    Text('데이터를 불러올 수 없습니다',
                        style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.space3),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(
                          teacherMonthlyStatsProvider(_selectedMonth)),
                      child: const Text('다시 시도'),
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
    final isCurrentMonth = _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
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
    final numberFormat = NumberFormat('#,###');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherMonthlyStatsProvider(_selectedMonth));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Stat cards grid (2x2)
          _buildStatCardGrid(stats, numberFormat),

          const SizedBox(height: AppSpacing.space5),

          // Revenue section
          _buildRevenueCard(stats, numberFormat),

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

  Widget _buildStatCardGrid(
      TeacherMonthlyStats stats, NumberFormat numberFormat) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '총 레슨',
                value: '${stats.totalLessons}회',
                subtitle: '완료 ${stats.completedLessons}회',
                color: AppColors.primary,
                icon: Icons.school,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: StatCard(
                title: '출석률',
                value: '${stats.attendanceRate.toStringAsFixed(1)}%',
                subtitle: '취소 ${stats.cancelledLessons}회',
                color: AppColors.success,
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
                title: '학생 수',
                value: '${stats.totalStudents}명',
                subtitle: '신규 +${stats.newStudents}명',
                color: AppColors.info,
                icon: Icons.people_outline,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: StatCard(
                title: '월 수입',
                value: '${numberFormat.format(stats.totalRevenue)}원',
                color: AppColors.secondary,
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
      TeacherMonthlyStats stats, NumberFormat numberFormat) {
    final isPositive = stats.revenueChangePercent >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('수익 현황', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이번 달 수익',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '${numberFormat.format(stats.totalRevenue)}원',
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
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${stats.revenueChangePercent.toStringAsFixed(1)}%',
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            isPositive ? AppColors.success : AppColors.error,
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
        Text('학생 현황', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              _buildStudentStatItem(
                '총 학생',
                '${stats.totalStudents}명',
                AppColors.textPrimaryLight,
              ),
              _buildDivider(),
              _buildStudentStatItem(
                '신규',
                '+${stats.newStudents}명',
                AppColors.success,
              ),
              _buildDivider(),
              _buildStudentStatItem(
                '이탈',
                stats.churnedStudents > 0
                    ? '-${stats.churnedStudents}명'
                    : '0명',
                stats.churnedStudents > 0
                    ? AppColors.error
                    : AppColors.textTertiaryLight,
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
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderLight,
    );
  }
}
