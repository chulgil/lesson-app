import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../practice/presentation/providers/practice_crud_provider.dart';

/// Practice summary section showing streak, weekly stats, and chart.
class PracticeSummarySection extends ConsumerWidget {
  final String studentId;

  const PracticeSummarySection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practiceLogsAsync = ref.watch(practiceLogsProvider(studentId));

    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    final sundayDate = mondayDate.add(const Duration(days: 6));

    // Default values
    var streakDays = 0;
    var weeklyTotalMinutes = 0;
    var weeklyPracticedDays = 0;
    var weeklyProgress = List.filled(7, 0.0);

    final logs = practiceLogsAsync.valueOrNull;
    if (logs != null && logs.isNotEmpty) {
      // Calculate streak: consecutive days from today going backwards
      final sortedLogs = [...logs]..sort((a, b) => b.date.compareTo(a.date));
      final practicedDates = <String>{};
      for (final log in sortedLogs) {
        if (log.totalMinutes > 0) {
          final d = log.date;
          practicedDates.add('${d.year}-${d.month}-${d.day}');
        }
      }

      var checkDate = DateTime(now.year, now.month, now.day);
      for (var i = 0; i < 100; i++) {
        final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
        if (practicedDates.contains(key)) {
          streakDays++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      // Weekly stats
      for (final log in logs) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        if (!logDate.isBefore(mondayDate) && !logDate.isAfter(sundayDate)) {
          weeklyTotalMinutes += log.totalMinutes;
          if (log.totalMinutes > 0) {
            final dayIndex = logDate.difference(mondayDate).inDays;
            if (dayIndex >= 0 && dayIndex < 7) {
              weeklyProgress[dayIndex] = 1.0;
            }
          }
        }
      }
      weeklyPracticedDays = weeklyProgress.where((v) => v > 0).length;
    }

    final hours = weeklyTotalMinutes ~/ 60;
    final minutes = weeklyTotalMinutes % 60;
    final weeklyTimeStr =
        hours > 0
            ? (minutes > 0 ? '$hours시간 $minutes분' : '$hours시간')
            : '$minutes분';
    final goalPercent = (weeklyPracticedDays / 7 * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Notebook × Score: 섹션 헤더는 Playfair sectionTitle (§7.87-f).
            Text('이번 주 연습', style: NotebookTypography.sectionTitle),
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
                iconColor: AppColors.paperAccent,
                value: '$streakDays일',
                label: '연속 연습',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.timer_outlined,
                iconColor: AppColors.ink,
                value: weeklyTimeStr,
                label: '이번 주 총',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildCompactStatCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.paperOk,
                value: '$goalPercent%',
                label: '목표 달성',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space3),

        _buildCompactWeeklyChart(weeklyProgress),
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
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
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
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWeeklyChart(List<double> progress) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final today = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
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
                  color: AppColors.paperDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 24,
                  height: 40 * value,
                  decoration: BoxDecoration(
                    color:
                        isFuture
                            ? AppColors.inkQuaternary
                            : value >= 0.8
                            ? AppColors.paperOk
                            : value >= 0.5
                            ? AppColors.inkTertiary
                            : value > 0
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                days[index],
                style: AppTypography.caption.copyWith(
                  color: isToday ? AppColors.ink : AppColors.inkTertiary,
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
