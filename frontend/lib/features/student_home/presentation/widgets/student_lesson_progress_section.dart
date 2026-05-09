import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../domain/entities/student_lesson_progress_item.dart';
import '../providers/student_lesson_progress_provider.dart';
import 'student_lesson_progress_item_row.dart';

class StudentLessonProgressSection extends ConsumerWidget {
  final String studentId;

  const StudentLessonProgressSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(studentLessonProgressProvider(studentId));

    return itemsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final sortedItems = StudentLessonProgressItem.sorted(items);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotebookSectionHeader(
              label:
                  '${AppStrings.studentHomeLessonProgressLabel} · ${sortedItems.length}',
            ),
            const SizedBox(height: AppSpacing.space1),
            _ProgressStats(items: sortedItems),
            const SizedBox(height: AppSpacing.space2),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.inkQuaternary),
                  bottom: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < sortedItems.length; i++) ...[
                    if (i > 0)
                      const ThinRule(),
                    StudentLessonProgressItemRow(
                      item: sortedItems[i],
                      onTap:
                          sortedItems[i].route == null
                              ? null
                              : () => context.push(
                                sortedItems[i].route!,
                                extra: sortedItems[i].routeExtra,
                              ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressStats extends StatelessWidget {
  final List<StudentLessonProgressItem> items;

  const _ProgressStats({required this.items});

  @override
  Widget build(BuildContext context) {
    final actionCount =
        items
            .where(
              (item) =>
                  item.priority == StudentLessonProgressPriority.actionRequired,
            )
            .length;
    final waitingCount =
        items
            .where(
              (item) => item.priority == StudentLessonProgressPriority.waiting,
            )
            .length;
    final completedCount =
        items
            .where(
              (item) =>
                  item.priority == StudentLessonProgressPriority.completed,
            )
            .length;

    final parts = <String>[
      if (actionCount > 0) '내가 할 일 $actionCount',
      if (waitingCount > 0) '대기 $waitingCount',
      if (completedCount > 0) '완료 $completedCount',
    ];

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space2),
      child: Text(
        parts.join(' · '),
        style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }
}
