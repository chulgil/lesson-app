import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Practice summary section showing streak, weekly stats, and chart.
class PracticeSummarySection extends StatelessWidget {
  final String studentId;

  const PracticeSummarySection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('이번 주 연습', style: AppTypography.headingMedium),
            TextButton(
              onPressed: () {
                context.push('${AppRoutes.practiceStats}?studentId=$studentId');
              },
              child: const Text('상세 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        Row(
          children: [
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.local_fire_department,
                iconColor: AppColors.warning,
                value: '7일',
                label: '연속 연습',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.timer_outlined,
                iconColor: AppColors.info,
                value: '4시간 30분',
                label: '이번 주 총',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                value: '75%',
                label: '목표 달성',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space3),

        _buildCompactWeeklyChart(),
      ],
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
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

  Widget _buildCompactWeeklyChart() {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final progress = [1.0, 0.8, 0.6, 0.4, 0.0, 0.0, 0.0];
    final today = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final isToday = index == today;
          final isFuture = index > today;
          final value = progress[index];

          return Column(
            children: [
              Container(
                width: 24,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 24,
                  height: 40 * value,
                  decoration: BoxDecoration(
                    color:
                        isFuture
                            ? AppColors.borderLight
                            : value >= 0.8
                            ? AppColors.practiceGood
                            : value >= 0.5
                            ? AppColors.practiceNormal
                            : value > 0
                            ? AppColors.practicePoor
                            : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                days[index],
                style: AppTypography.caption.copyWith(
                  color:
                      isToday ? AppColors.primary : AppColors.textTertiaryLight,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
