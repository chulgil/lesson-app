import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/practice/practice_facade.dart';

/// Student home — weekly assignments preview card.
///
/// Displays incomplete practice items for the current student.
/// Empty state shows a friendly message. Taps the "more" link to
/// navigate to the practice stats screen (no route available for
/// assignments standalone; reuses practiceStats entry point).
class WeeklyAssignmentsSection extends ConsumerWidget {
  final String studentId;

  const WeeklyAssignmentsSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(weeklyPracticeItemsProvider(studentId));

    return itemsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final incomplete = items.where((i) => !i.isCompleted).toList()
          ..sort(
            (a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Text(
                  AppStrings.weeklyAssignmentTitle,
                  style: NotebookTypography.sectionTitle,
                ),
                const Spacer(),
                if (incomplete.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.paperAccentSoft,
                    ),
                    child: Text(
                      '${incomplete.length}개',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            if (incomplete.isEmpty)
              _EmptyState()
            else
              _AssignmentList(items: incomplete),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_turned_in_outlined,
            size: 20,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            AppStrings.weeklyAssignmentEmpty,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  final List<PracticeItem> items;

  const _AssignmentList({required this.items});

  @override
  Widget build(BuildContext context) {
    // Show at most 3 items in the home card to keep it compact.
    final preview = items.take(3).toList();

    return Column(
      children: [
        for (var i = 0; i < preview.length; i++) ...[
          _AssignmentRow(item: preview[i]),
          if (i < preview.length - 1)
            const Divider(height: 1, color: AppColors.inkQuaternary),
        ],
        if (items.length > 3) ...[
          const Divider(height: 1, color: AppColors.inkQuaternary),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Text(
              '+${items.length - 3}개 더 있습니다',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final PracticeItem item;

  const _AssignmentRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        children: [
          _PriorityDot(priority: item.priority),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              item.title,
              style: NotebookTypography.hand.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final PracticePriority priority;

  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      PracticePriority.must => AppColors.paperAccent,
      PracticePriority.should => AppColors.paperAccentSoft,
      PracticePriority.could => AppColors.inkTertiary,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
