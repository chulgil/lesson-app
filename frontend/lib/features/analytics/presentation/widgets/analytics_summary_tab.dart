// Analytics Tab 1: 월간 요약.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §2.2 Tab 1

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../domain/entities/teacher_stats.dart';
import '../providers/analytics_providers.dart';
import 'monthly_trend_chart.dart';
import 'practice_ranking_list.dart';

// ignore: widget-smoke-test
/// Monthly summary tab content for AnalyticsDashboardScreen.
class AnalyticsSummaryTab extends ConsumerWidget {
  const AnalyticsSummaryTab({
    super.key,
    required this.selectedMonth,
    this.onRefresh,
  });

  final DateTime selectedMonth;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(teacherMonthlyStatsProvider(selectedMonth));
    final summaryListAsync = ref.watch(studentSummaryListProvider(selectedMonth));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        onRetry: () => ref.invalidate(teacherMonthlyStatsProvider(selectedMonth)),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherMonthlyStatsProvider(selectedMonth));
          ref.invalidate(studentSummaryListProvider(selectedMonth));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _buildStatCards(stats),
            const SizedBox(height: AppSpacing.space5),
            MonthlyTrendChart(trendData: stats.lessonTrend),
            const SizedBox(height: AppSpacing.space5),
            PracticeRankingList(rankings: stats.practiceRanking),
            const SizedBox(height: AppSpacing.space5),
            _buildStudentSummarySection(summaryListAsync),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(TeacherMonthlyStats stats) {
    final travelH = stats.totalLessons > 0 ? (stats.totalLessons * 12) ~/ 60 : 0;
    final travelM = stats.totalLessons > 0 ? (stats.totalLessons * 12) % 60 : 0;

    return Column(
      children: [
        StatCardRow(cards: [
          StatCard(
            title: AppStrings.analyticsTotalLessons,
            value: AppStrings.usageCountShort(stats.totalLessons),
            subtitle: AppStrings.analyticsCompletedFormat(stats.completedLessons),
            color: AppColors.paperAccent,
            icon: Icons.school,
          ),
          StatCard(
            title: AppStrings.analyticsCompletionRateLabel,
            value: '${stats.attendanceRate.toStringAsFixed(1)}%',
            subtitle: AppStrings.analyticsCompletedFormat(stats.completedLessons),
            color: AppColors.paperOk,
            icon: Icons.check_circle_outline,
          ),
        ]),
        const SizedBox(height: AppSpacing.space3),
        StatCardRow(cards: [
          StatCard(
            title: AppStrings.analyticsMonthlyRevenue,
            value: formatWonWithComma(stats.totalRevenue),
            subtitle: AppStrings.analyticsVsPrevMonth(stats.revenueChangePercent),
            color: AppColors.paperAccent,
            icon: Icons.account_balance_wallet,
          ),
          StatCard(
            title: AppStrings.analyticsStudentCountLabel,
            value: AppStrings.peopleCount(stats.totalStudents),
            subtitle: AppStrings.analyticsNewStudentsFormat(stats.newStudents),
            color: AppColors.ink,
            icon: Icons.people,
          ),
        ]),
        const SizedBox(height: AppSpacing.space3),
        SizedBox(
          width: double.infinity,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.5,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space3 / 2),
              child: StatCard(
                title: AppStrings.analyticsTravelTimeLabel,
                value: travelM > 0 ? '${travelH}h ${travelM}m' : '${travelH}h',
                subtitle: '월 합산',
                color: AppColors.inkTertiary,
                icon: Icons.directions_car,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSummarySection(
    AsyncValue<List<dynamic>> summaryListAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학생별 연습 현황',
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        summaryListAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (list) => list.isEmpty
              ? Text(
                  AppStrings.analyticsNoStudentData,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                )
              : Column(
                  children: list.map((item) => _StudentSummaryRow(item: item)).toList(),
                ),
        ),
      ],
    );
  }
}

class _StudentSummaryRow extends StatelessWidget {
  const _StudentSummaryRow({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final practiceRate = (item.practiceRate as double).clamp(0.0, 1.0);
    final attendanceRate = (item.attendanceRate as double).clamp(0.0, 1.0);
    final pr = (practiceRate * 100).round();
    final ar = (attendanceRate * 100).round();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.paperDark,
                child: Text(
                  item.studentName.substring(0, 1),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              // Name + instrument
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName as String,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (item.instrumentType != null)
                      Text(
                        item.instrumentType as String,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.space1),
                    // Practice bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRect(
                            child: LinearProgressIndicator(
                              value: practiceRate,
                              backgroundColor: AppColors.inkQuaternary,
                              color: AppColors.paperOk,
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          '연습 $pr%',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.paperOk,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              // Attendance %
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '출석 $ar%',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.space1),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.inkQuaternary),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.inkQuaternary),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(AppStrings.cannotLoadData, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space3),
          OutlinedButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
