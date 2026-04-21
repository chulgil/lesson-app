import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';

/// Displays subscription history summary for a student.
///
/// Like a loyalty card history — shows total duration, completed lessons,
/// and attendance rate to help the student feel confident about renewing.
class SubscriptionHistorySection extends ConsumerWidget {
  final String studentId;

  const SubscriptionHistorySection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(
      studentSubscriptionsProvider(studentId),
    );

    return subscriptionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subscriptions) {
        if (subscriptions.isEmpty) return const SizedBox.shrink();

        final stats = _calculateStats(subscriptions);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '수강 이력',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              _buildStatRow('수강 기간', stats.periodText),
              const SizedBox(height: AppSpacing.space2),
              _buildStatRow('총 수강', stats.totalText),
              if (stats.attendanceRate > 0) ...[
                const SizedBox(height: AppSpacing.space2),
                _buildStatRow(
                  '출석률',
                  '${stats.attendanceRate}%',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  _HistoryStats _calculateStats(List<Subscription> subscriptions) {
    // Only count non-trial subscriptions
    final regularSubs = subscriptions
        .where((s) => s.type != SubscriptionType.trial)
        .toList();

    if (regularSubs.isEmpty) {
      return _HistoryStats(
        periodText: '-',
        totalText: '-',
        attendanceRate: 0,
      );
    }

    // Calculate period (filter out subs without dates)
    final datedSubs = regularSubs.where((s) => s.startDate != null).toList();
    if (datedSubs.isEmpty) {
      final totalUsed = regularSubs.fold<int>(0, (sum, s) => sum + s.usedLessons);
      return _HistoryStats(
        periodText: '-',
        totalText: '$totalUsed회 완료',
        attendanceRate: 0,
      );
    }

    final startDates = datedSubs.map((s) => s.startDate!).toList();
    final endDates = datedSubs
        .map((s) => s.endDate ?? s.startDate!)
        .toList();

    final earliest = startDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = endDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final months = _monthsBetween(earliest, latest);
    final periodText = '${earliest.year}.${earliest.month.toString().padLeft(2, '0')}'
        ' ~ ${latest.year}.${latest.month.toString().padLeft(2, '0')}';

    // Calculate total lessons
    final totalUsed = regularSubs.fold<int>(0, (sum, s) => sum + s.usedLessons);
    final totalText = months > 0
        ? '$months개월 · $totalUsed회 완료'
        : '$totalUsed회 완료';

    // Calculate attendance rate (used / total available)
    final totalAvailable = regularSubs.fold<int>(
      0,
      (sum, s) => sum + (s.totalLessons ?? s.lessonsPerMonth ?? 0) + s.bonusCount,
    );
    final attendanceRate = totalAvailable > 0
        ? (totalUsed / totalAvailable * 100).round()
        : 0;

    return _HistoryStats(
      periodText: periodText,
      totalText: totalText,
      attendanceRate: attendanceRate,
    );
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }
}

class _HistoryStats {
  final String periodText;
  final String totalText;
  final int attendanceRate;

  const _HistoryStats({
    required this.periodText,
    required this.totalText,
    required this.attendanceRate,
  });
}
