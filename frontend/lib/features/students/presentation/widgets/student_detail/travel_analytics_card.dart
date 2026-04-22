import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../providers/travel_analytics_provider.dart';

/// Monthly travel analytics summary card for the teacher's profile/dashboard.
class TravelAnalyticsCard extends ConsumerWidget {
  final String teacherId;

  const TravelAnalyticsCard({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(monthlyTravelAnalyticsProvider(teacherId));

    return analyticsAsync.when(
      data: (analytics) {
        if (analytics.totalMinutes == 0) return const SizedBox.shrink();

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppColors.paperDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 18,
                      color: AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '월간 이동 리포트',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Row(
                  children: [
                    _buildStat(context, '총 이동시간', analytics.formattedTotal),
                    const SizedBox(width: AppSpacing.space6),
                    _buildStat(context, '방문 횟수', '${analytics.visitCount}회'),
                    const SizedBox(width: AppSpacing.space6),
                    _buildStat(context, '평균', '${analytics.averageMinutes}분'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.paperAccent,
          ),
        ),
      ],
    );
  }
}
