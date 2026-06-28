import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../practice/practice_facade.dart';
import '../providers/child_profile_provider.dart';

/// Parent assignments tab for viewing child's assignments
class ParentAssignmentsTab extends ConsumerWidget {
  const ParentAssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProfile = ref.watch(selectedChildProfileProvider);
    final studentId = selectedProfile?.linkedStudentId;

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.parentHomeAssignmentStatus),
        centerTitle: true,
        actions: const [],
      ),
      body:
          studentId == null
              ? const _UnlinkedState()
              : _AssignmentsBody(studentId: studentId),
    );
  }
}

/// Real-data body scoped to the selected child's linked student id.
class _AssignmentsBody extends ConsumerWidget {
  const _AssignmentsBody({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(weeklyPracticeItemsProvider(studentId));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorState(),
      data: (items) {
        final incomplete =
            items.where((i) => !i.isCompleted).toList()
              ..sort(
                (a, b) =>
                    a.priority.sortOrder.compareTo(b.priority.sortOrder),
              );
        final completed = items.where((i) => i.isCompleted).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weeklyPracticeItemsProvider(studentId));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              _ProgressSummary(
                total: items.length,
                completed: completed.length,
                incomplete: incomplete.length,
              ),
              const SizedBox(height: AppSpacing.space6),
              if (items.isEmpty)
                const _EmptyAssignments()
              else ...[
                if (incomplete.isNotEmpty) ...[
                  _SectionHeader(
                    title: AppStrings.parentHomeIncompleteAssignment,
                    count: incomplete.length,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  ..._assignmentCards(incomplete),
                  const SizedBox(height: AppSpacing.space6),
                ],
                if (completed.isNotEmpty) ...[
                  _SectionHeader(
                    title: AppStrings.parentHomeCompletedAssignment,
                    count: completed.length,
                    color: AppColors.paperOk,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  ..._assignmentCards(completed),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _assignmentCards(List<PracticeItem> items) {
    final cards = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      cards.add(
        _AssignmentCard(
          title: item.title,
          description: item.description ?? '',
          dueDate:
              item.isCompleted
                  ? AppStrings.parentHomeCompletedLabel
                  : _priorityLabel(item.priority),
          priority: _mapPriority(item.priority),
          isCompleted: item.isCompleted,
        ),
      );
      if (i < items.length - 1) {
        cards.add(const SizedBox(height: AppSpacing.space3));
      }
    }
    return cards;
  }

  static AssignmentPriority _mapPriority(PracticePriority priority) {
    switch (priority) {
      case PracticePriority.must:
        return AssignmentPriority.must;
      case PracticePriority.should:
        return AssignmentPriority.should;
      case PracticePriority.could:
        return AssignmentPriority.could;
    }
  }

  static String _priorityLabel(PracticePriority priority) {
    switch (priority) {
      case PracticePriority.must:
        return AppStrings.parentHomePriorityMust;
      case PracticePriority.should:
        return AppStrings.parentHomePriorityShould;
      case PracticePriority.could:
        return AppStrings.parentHomePriorityCould;
    }
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.total,
    required this.completed,
    required this.incomplete,
  });

  final int total;
  final int completed;
  final int incomplete;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : completed / total;
    final percent = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.paperAccent, AppColors.paperAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // §7.132: accent 배너 텍스트 white → paper.
              Text(
                AppStrings.parentHomeWeeklyAssignment,
                style: NotebookTypography.sectionTitle.copyWith(
                  color: AppColors.paper,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  '$percent% ${AppStrings.statusCompleted}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.paper.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.paper),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProgressStat(
                label: AppStrings.parentHomeTotal,
                value: '$total',
                color: AppColors.paper,
              ),
              _ProgressStat(
                label: AppStrings.statusCompleted,
                value: '$completed',
                color: AppColors.paperDark,
              ),
              _ProgressStat(
                label: AppStrings.parentHomeInProgress,
                value: '$incomplete',
                color: AppColors.paperAccentSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlinkedState extends StatelessWidget {
  const _UnlinkedState();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.link_off,
      title: AppStrings.parentHomeNotLinked,
      subtitle: AppStrings.parentHomeNotLinkedDesc,
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: AppStrings.parentHomeNoAssignment,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.paperAccent,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.errorOccurred,
              style: NotebookTypography.sectionTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Notebook × Score: 학부모 과제 탭 섹션 헤더도 Playfair sectionTitle 로 통일.
        Text(title, style: NotebookTypography.sectionTitle),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.zero,
          ),
          child: Text(
            '$count개',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.headingMedium.copyWith(color: color)),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.paper.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

enum AssignmentPriority { must, should, could }

class _AssignmentCard extends StatelessWidget {
  final String title;
  final String description;
  final String dueDate;
  final AssignmentPriority priority;
  final bool isCompleted;

  const _AssignmentCard({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color:
              isCompleted
                  ? AppColors.inkQuaternary
                  : _getPriorityColor().withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // §7.132: round → 사각 체크박스. white → paper.
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.paperOk : AppColors.paperDark,
                  border:
                      isCompleted
                          ? null
                          : Border.all(color: AppColors.inkQuaternary),
                ),
                child:
                    isCompleted
                        ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.paper,
                        )
                        : null,
              ),
              const SizedBox(width: AppSpacing.space3),
              // §7.130: 선생님 작성 과제 제목 → Tier 1 Gaegu hand.
              Expanded(
                child: Text(
                  title,
                  style: NotebookTypography.hand.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? AppColors.inkTertiary : AppColors.ink,
                  ),
                ),
              ),
              // Priority badge
              if (!isCompleted) _buildPriorityBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // §7.130: 선생님 작성 과제 설명 → Tier 1 Gaegu hand.
                Text(
                  description,
                  style: NotebookTypography.handSmall.copyWith(
color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      size: 14,
                      color:
                          isCompleted
                              ? AppColors.paperOk
                              : AppColors.inkTertiary,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      dueDate,
                      style: AppTypography.caption.copyWith(
                        color:
                            isCompleted
                                ? AppColors.paperOk
                                : dueDate.contains('내일')
                                ? AppColors.paperAccent
                                : AppColors.inkTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case AssignmentPriority.must:
        return AppColors.paperAccent;
      case AssignmentPriority.should:
        return AppColors.paperAccent;
      case AssignmentPriority.could:
        return AppColors.ink;
    }
  }

  String _getPriorityLabel() {
    switch (priority) {
      case AssignmentPriority.must:
        return '필수';
      case AssignmentPriority.should:
        return '권장';
      case AssignmentPriority.could:
        return '선택';
    }
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        _getPriorityLabel(),
        style: AppTypography.captionSmall.copyWith(
          color: _getPriorityColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
