// Student practice section widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice.dart';
import '../../../../../providers/providers.dart';

/// Practice section for student detail screen
class StudentPracticeSection extends ConsumerWidget {
  final String studentId;

  const StudentPracticeSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final weeklyPracticeAsync = ref.watch(weeklyPracticeProvider(studentId));
    final todayPracticeAsync = ref.watch(todayPracticeProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('이번 주 연습', style: AppTypography.headingSmall),
            weeklyPracticeAsync.when(
              data: (practiced) => Text(
                '${practiced.where((p) => p).length}/7일',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Practice calendar
        weeklyPracticeAsync.when(
          data: (practiced) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isPracticed = index < practiced.length && practiced[index];
                return Column(
                  children: [
                    Text(
                      days[index],
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPracticed
                            ? AppColors.practiceGood.withValues(alpha: 0.15)
                            : AppColors.surfaceSecondaryLight,
                        shape: BoxShape.circle,
                        border: isPracticed
                            ? Border.all(color: AppColors.practiceGood, width: 2)
                            : null,
                      ),
                      child: Icon(
                        isPracticed ? Icons.check : Icons.remove,
                        size: 18,
                        color: isPracticed
                            ? AppColors.practiceGood
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: const Text('연습 정보를 불러올 수 없습니다'),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Today's practice tasks
        todayPracticeAsync.when(
          data: (practiceLog) {
            if (practiceLog == null || practiceLog.tasks.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: practiceLog.tasks.map((task) => _buildTaskRow(task)).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTaskRow(PracticeTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 20,
            color: task.isCompleted
                ? AppColors.practiceGood
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              task.title,
              style: AppTypography.bodyMedium.copyWith(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted
                    ? AppColors.textTertiaryLight
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            '${task.targetMinutes}분',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
