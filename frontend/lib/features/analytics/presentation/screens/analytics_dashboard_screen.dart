// Analytics dashboard screen with 3-tab layout.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §2.2
// Refs: #354

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../widgets/analytics_summary_tab.dart';
import '../widgets/revenue_analytics_tab.dart';
import '../widgets/student_growth_tab.dart';

/// Three-tab analytics dashboard for teachers.
///
/// Tab 1: 월간 요약 — StatCards + lesson trend + student list
/// Tab 2: 학생 성장 — student picker + practice chart + repertoire
/// Tab 3: 수입 분석 — revenue bar chart + pie chart + expected income
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AnalyticsSummaryTab(selectedMonth: _selectedMonth),
                const StudentGrowthTab(),
                const RevenueAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        AppStrings.analyticsTitle,
        style: NotebookTypography.appBarTitle,
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          bottom: BorderSide(color: AppColors.inkQuaternary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            formatYearMonth(_selectedMonth),
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.paper,
      child: TabBar(
        controller: _tabController,
        labelStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.bodySmall,
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.inkTertiary,
        indicatorColor: AppColors.paperAccent,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: AppStrings.analyticsMonthlySummary),
          Tab(text: AppStrings.analyticsStudentGrowth),
          Tab(text: AppStrings.analyticsRevenue),
        ],
      ),
    );
  }
}
