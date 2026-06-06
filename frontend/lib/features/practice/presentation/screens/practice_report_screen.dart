import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../domain/entities/practice_report.dart';
import '../providers/practice_report_provider.dart';
import '../widgets/report/practice_chart.dart';
import '../widgets/report/repertoire_ratio_bar.dart';

/// Practice report screen — toggles between weekly and monthly view.
class PracticeReportScreen extends ConsumerWidget {
  final String studentId;

  const PracticeReportScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(practiceReportPeriodControllerProvider);
    final dateState = ref.watch(reportDateProvider);

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.practiceReportTitle,
      body: Column(
        children: [
          _PeriodToggle(period: period),
          Expanded(
            child: period == PracticeReportPeriod.weekly
                ? _WeeklyBody(
                    studentId: studentId,
                    weekStart: dateState.weekStart,
                  )
                : _MonthlyBody(
                    studentId: studentId,
                    year: dateState.year,
                    month: dateState.month,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends ConsumerWidget {
  final PracticeReportPeriod period;

  const _PeriodToggle({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: SegmentedButton<PracticeReportPeriod>(
        segments: const [
          ButtonSegment(
            value: PracticeReportPeriod.weekly,
            label: Text(AppStrings.practiceReportWeekly),
          ),
          ButtonSegment(
            value: PracticeReportPeriod.monthly,
            label: Text(AppStrings.practiceReportMonthly),
          ),
        ],
        selected: {period},
        onSelectionChanged: (set) {
          ref
              .read(practiceReportPeriodControllerProvider.notifier)
              .select(set.first);
        },
      ),
    );
  }
}

class _WeeklyBody extends ConsumerWidget {
  final String studentId;
  final DateTime weekStart;

  const _WeeklyBody({required this.studentId, required this.weekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      practiceWeeklyReportProvider((
        studentId: studentId,
        weekStart: weekStart,
      )),
    );
    return reportAsync.when(
      data: (report) => _WeeklyContent(report: report),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorView(),
    );
  }
}

class _WeeklyContent extends StatelessWidget {
  final WeeklyReport report;

  const _WeeklyContent({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report.isEmpty) {
      return const _EmptyReport();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            totalMinutes: report.totalMinutes,
            practiceDays: report.practiceDayCount,
            avgMinutes: report.averageDailyMinutes,
          ),
          const SizedBox(height: AppSpacing.space4),
          PracticeChart(dailyEntries: report.dailyEntries),
          const SizedBox(height: AppSpacing.space4),
          RepertoireRatioBar(ratios: report.repertoireRatios),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }
}

class _MonthlyBody extends ConsumerWidget {
  final String studentId;
  final int year;
  final int month;

  const _MonthlyBody({
    required this.studentId,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      practiceMonthlyReportProvider((
        studentId: studentId,
        year: year,
        month: month,
      )),
    );
    return reportAsync.when(
      data: (report) => _MonthlyContent(report: report),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorView(),
    );
  }
}

class _MonthlyContent extends StatelessWidget {
  final MonthlyReport report;

  const _MonthlyContent({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report.isEmpty) {
      return const _EmptyReport();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            totalMinutes: report.totalMinutes,
            practiceDays: report.practiceDayCount,
            avgMinutes: report.averageDailyMinutes,
          ),
          const SizedBox(height: AppSpacing.space4),
          PracticeChart(dailyEntries: report.dailyEntries),
          const SizedBox(height: AppSpacing.space4),
          RepertoireRatioBar(ratios: report.repertoireRatios),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalMinutes;
  final int practiceDays;
  final int avgMinutes;

  const _SummaryRow({
    required this.totalMinutes,
    required this.practiceDays,
    required this.avgMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: AppStrings.practiceReportTotalMinutes,
            value: '$totalMinutes${AppStrings.practiceReportMinutesUnit}',
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _SummaryTile(
            label: AppStrings.practiceReportPracticeDays,
            value: '$practiceDays${AppStrings.practiceReportDaysUnit}',
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _SummaryTile(
            label: AppStrings.practiceReportAvgMinutes,
            value: '$avgMinutes${AppStrings.practiceReportMinutesUnit}',
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Text(
          AppStrings.practiceReportEmpty,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.inkSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.practiceReportEmpty,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }
}
