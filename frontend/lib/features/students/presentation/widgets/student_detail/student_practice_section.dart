// Student practice section widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../features/practice/domain/entities/practice_log.dart';
import '../../../../practice/presentation/providers/practice_crud_provider.dart';

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
            // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
            Text(
              AppStrings.studentWeeklyPractice,
              style: NotebookTypography.sectionTitle,
            ),
            weeklyPracticeAsync.when(
              data:
                  (practiced) => Text(
                    '${practiced.where((p) => p).length}/7일',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
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
          data:
              (practiced) => Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.inkQuaternary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final isPracticed =
                        index < practiced.length && practiced[index];
                    return Column(
                      children: [
                        Text(
                          days[index],
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                isPracticed
                                    ? AppColors.paperOk.withValues(alpha: 0.15)
                                    : AppColors.paperDark,
                            borderRadius: BorderRadius.zero,
                            border:
                                isPracticed
                                    ? Border.all(
                                      color: AppColors.paperOk,
                                      width: 2,
                                    )
                                    : null,
                          ),
                          child: Icon(
                            isPracticed ? Icons.check : Icons.remove,
                            size: 18,
                            color:
                                isPracticed
                                    ? AppColors.paperOk
                                    : AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
          loading:
              () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
          error:
              (_, __) => Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                child: const Text(AppStrings.studentPracticeLoadError),
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
              children:
                  practiceLog.tasks.map((task) => _buildTaskRow(task)).toList(),
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
            color: task.isCompleted ? AppColors.paperOk : AppColors.inkTertiary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              task.title,
              style: AppTypography.bodyMedium.copyWith(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? AppColors.inkTertiary : AppColors.ink,
              ),
            ),
          ),
          Text(
            '${task.targetMinutes}분',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
