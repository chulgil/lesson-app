import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../relationship/presentation/providers/relationship_providers.dart';

/// Card widget to display previous schedule for re-enrollment restoration.
///
/// Shows when a student is re-enrolling and has a previous schedule on record.
/// Allows teacher to restore the previous schedule with one tap.
class PreviousScheduleCard extends ConsumerWidget {
  final String teacherId;
  final String studentId;
  final ValueChanged<PreviousSchedule>? onRestore;
  final VoidCallback? onDismiss;

  const PreviousScheduleCard({
    super.key,
    required this.teacherId,
    required this.studentId,
    this.onRestore,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previousScheduleAsync = ref.watch(
      previousScheduleProvider(
        teacherId: teacherId,
        studentId: studentId,
      ),
    );

    return previousScheduleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedule) {
        if (schedule == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.space2,
          ),
          color: AppColors.ink.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            side: BorderSide(
              color: AppColors.ink.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.ink,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '이전 스케줄 복원',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                    ),
                    const Spacer(),
                    if (onDismiss != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppColors.inkSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  '이전에 진행하던 스케줄이 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(
                      color: AppColors.inkQuaternary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatSchedule(schedule),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (schedule.lessonDuration != null)
                              Text(
                                '${schedule.lessonDuration}분 레슨',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.inkSecondary,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        onRestore != null ? () => onRestore!(schedule) : null,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('이 스케줄로 복원'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSchedule(PreviousSchedule schedule) {
    if (schedule.lessonSlots.isEmpty) return '';
    return schedule.lessonSlots
        .map((s) => '매주 ${s.displayLabel}')
        .join(', ');
  }
}
