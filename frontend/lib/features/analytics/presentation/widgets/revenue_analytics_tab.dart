// Analytics Tab 3: 수입 분석.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §2.2 Tab 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/stat_card.dart';
import '../providers/analytics_providers.dart';
import 'revenue_pie_chart.dart';
import 'simple_bar_chart.dart';

// ignore: widget-smoke-test
/// Revenue analytics tab content for AnalyticsDashboardScreen.
class RevenueAnalyticsTab extends ConsumerWidget {
  const RevenueAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(revenueAnalyticsDataProvider(6));

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.inkTertiary),
            const SizedBox(height: AppSpacing.space3),
            Text(AppStrings.cannotLoadData, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.space3),
            OutlinedButton(
              onPressed: () => ref.invalidate(revenueAnalyticsDataProvider(6)),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
      data: (analytics) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(revenueAnalyticsDataProvider(6)),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Top stat cards: this month + pending
            StatCardRow(cards: [
              StatCard(
                title: AppStrings.analyticsRevenueLabel,
                value: formatWonWithComma(analytics.currentMonthRevenue),
                subtitle: AppStrings.analyticsVsPrevMonth(
                  analytics.revenueChangePercent,
                ),
                color: AppColors.paperAccent,
                icon: Icons.account_balance_wallet,
              ),
              StatCard(
                title: AppStrings.analyticsPendingLabel,
                value: formatWonWithComma(analytics.pendingAmount),
                subtitle: AppStrings.analyticsPendingWaiting(analytics.pendingCount),
                color: AppColors.paperTrial,
                icon: Icons.access_time,
              ),
            ]),

            const SizedBox(height: AppSpacing.space5),

            // Monthly revenue bar chart
            Text(
              AppStrings.analyticsMonthlyRevenueTrend,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: SimpleBarChart(
                data: analytics.trend.map((t) {
                  return (
                    label: AppStrings.analyticsMonthLabelFormat(t.month.month),
                    value: t.confirmedRevenue,
                  );
                }).toList(),
                barColor: AppColors.paperAccent,
              ),
            ),

            const SizedBox(height: AppSpacing.space5),

            // Student revenue pie chart
            Text(
              AppStrings.analyticsStudentRevenuePortion,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: RevenuePieChart(breakdown: analytics.breakdown),
            ),

            const SizedBox(height: AppSpacing.space5),

            // Expected revenue card
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.paperDark,
                border: Border(
                  left: BorderSide(color: AppColors.paperOk, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.analyticsExpectedLabel,
                    style: NotebookTypography.sectionLabel,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    formatWonWithComma(analytics.expectedMonthlyRevenue),
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    AppStrings.analyticsExpectedBasis(10),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  if (analytics.expiringSubscriptionCount > 0) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.paperTrial,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          AppStrings.analyticsExpiringThisMonth(
                            analytics.expiringSubscriptionCount,
                          ),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paperTrial,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }
}
