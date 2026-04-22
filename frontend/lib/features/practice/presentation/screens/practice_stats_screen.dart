import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/time_format_utils.dart';
import '../../domain/entities/entities.dart';
import '../providers/practice_report_provider.dart';
import '../widgets/stats/daily_bar_chart.dart';
import '../widgets/stats/repertoire_stats_list.dart';
import '../widgets/stats/stats_summary_card.dart';
import '../widgets/stats/weekly_trend_chart.dart';

/// Main screen for viewing practice statistics
class PracticeStatsScreen extends ConsumerStatefulWidget {
  final String studentId;

  const PracticeStatsScreen({super.key, required this.studentId});

  @override
  ConsumerState<PracticeStatsScreen> createState() =>
      _PracticeStatsScreenState();
}

class _PracticeStatsScreenState extends ConsumerState<PracticeStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연습 통계'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '주간'), Tab(text: '월간')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeeklyReportTab(studentId: widget.studentId),
          _MonthlyReportTab(studentId: widget.studentId),
        ],
      ),
    );
  }
}

/// Weekly report tab
class _WeeklyReportTab extends ConsumerWidget {
  final String studentId;

  const _WeeklyReportTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateState = ref.watch(reportDateProvider);
    final reportAsync = ref.watch(
      weeklyReportProvider((
        studentId: studentId,
        weekStart: dateState.weekStart,
      )),
    );

    return Column(
      children: [
        // Date navigation
        _DateNavigator(
          title:
              dateState.weekStart.year == DateTime.now().year
                  ? '${dateState.weekStart.month}월 ${getWeekOfMonth(dateState.weekStart)}주차'
                  : '${dateState.weekStart.year}년 ${dateState.weekStart.month}월 ${getWeekOfMonth(dateState.weekStart)}주차',
          onPrevious:
              () => ref.read(reportDateProvider.notifier).previousWeek(),
          onNext:
              dateState.canNavigateNextWeek
                  ? () => ref.read(reportDateProvider.notifier).nextWeek()
                  : null,
        ),

        // Report content
        Expanded(
          child: reportAsync.when(
            data: (report) => _buildWeeklyContent(report),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyContent(PracticeStatsReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          StatsSummaryCard(report: report),
          const SizedBox(height: AppSpacing.space4),
          DailyBarChart(dailyStats: report.dailyStats),
          const SizedBox(height: AppSpacing.space4),
          RepertoireStatsList(repertoireStats: report.repertoireStats),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '통계를 불러올 수 없습니다',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.paperAccent),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextButton(
            onPressed: () => ref.invalidate(weeklyReportProvider),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

/// Monthly report tab
class _MonthlyReportTab extends ConsumerWidget {
  final String studentId;

  const _MonthlyReportTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateState = ref.watch(reportDateProvider);
    final reportAsync = ref.watch(
      monthlyReportProvider((
        studentId: studentId,
        year: dateState.year,
        month: dateState.month,
      )),
    );

    return Column(
      children: [
        // Date navigation
        _DateNavigator(
          title: '${dateState.year}년 ${dateState.month}월',
          onPrevious:
              () => ref.read(reportDateProvider.notifier).previousMonth(),
          onNext:
              dateState.canNavigateNextMonth
                  ? () => ref.read(reportDateProvider.notifier).nextMonth()
                  : null,
        ),

        // Report content
        Expanded(
          child: reportAsync.when(
            data: (report) => _buildMonthlyContent(report),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyContent(PracticeStatsReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          StatsSummaryCard(report: report),
          const SizedBox(height: AppSpacing.space4),
          if (report.weeklyStats.isNotEmpty) ...[
            WeeklyTrendChart(weeklyStats: report.weeklyStats),
            const SizedBox(height: AppSpacing.space4),
          ],
          RepertoireStatsList(repertoireStats: report.repertoireStats),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '통계를 불러올 수 없습니다',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.paperAccent),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextButton(
            onPressed: () => ref.invalidate(monthlyReportProvider),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

/// Date navigation widget
class _DateNavigator extends StatelessWidget {
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _DateNavigator({
    required this.title,
    required this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: '이전',
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right,
              color:
                  onNext != null
                      ? AppColors.ink
                      : AppColors.inkTertiary,
            ),
            tooltip: '다음',
          ),
        ],
      ),
    );
  }
}
