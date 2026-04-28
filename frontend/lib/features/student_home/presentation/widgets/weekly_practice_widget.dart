import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/practice/domain/entities/practice_item.dart';
import '../../../practice/presentation/providers/practice_item_providers.dart';
import '../../../lessons/presentation/widgets/resource_attachment_section.dart';

/// Widget to display student's weekly practice items (from teacher assignments)
class WeeklyPracticeWidget extends ConsumerWidget {
  final String studentId;
  final bool showHeader;
  final VoidCallback? onViewAll;

  const WeeklyPracticeWidget({
    super.key,
    required this.studentId,
    this.showHeader = true,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(weeklyPracticeItemsProvider(studentId));

    return itemsAsync.when(
      data: (items) => _buildContent(context, ref, items),
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(ref),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: AppColors.paper),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '데이터를 불러오는데 실패했습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton.icon(
            onPressed:
                () => ref.invalidate(weeklyPracticeItemsProvider(studentId)),
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<PracticeItem> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final completed = items.where((i) => i.isCompleted).length;
    final total = items.length;
    final grouped = items.groupByPriority();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notebook × Score: 섹션 헤더는 Playfair sectionTitle (§7.87-f).
              Text('이번 주 연습', style: NotebookTypography.sectionTitle),
              if (onViewAll != null)
                TextButton(onPressed: onViewAll, child: const Text('전체보기')),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        Container(
          decoration: BoxDecoration(color: AppColors.paper),
          child: Column(
            children: [
              // Progress header
              Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLarge),
                    topRight: Radius.circular(AppSpacing.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    // Priority dots
                    Row(
                      children: [
                        for (final priority in PracticePriority.values)
                          if (grouped[priority]?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.space2,
                              ),
                              child: _buildPriorityBadge(
                                priority,
                                grouped[priority]!.length,
                              ),
                            ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '$completed/$total',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: total > 0 ? completed / total : 0,
                        backgroundColor: AppColors.inkQuaternary,
                        valueColor: AlwaysStoppedAnimation(
                          completed == total
                              ? AppColors.paperOk
                              : AppColors.paperAccent,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Practice items grouped by priority
              for (final priority in PracticePriority.values)
                if (grouped[priority]?.isNotEmpty == true)
                  ...grouped[priority]!.map(
                    (item) =>
                        _PracticeItemTile(item: item, studentId: studentId),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text('이번 주 연습', style: NotebookTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space3),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.space6),
          decoration: BoxDecoration(color: AppColors.paper),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: AppColors.inkTertiary,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  '아직 연습 과제가 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '선생님이 과제를 등록하면 여기에 표시됩니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(PracticePriority priority, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(color: priority.color.withValues(alpha: 0.15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(priority.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: AppSpacing.space1),
          Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: priority.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual practice item tile (student view)
class _PracticeItemTile extends ConsumerWidget {
  final PracticeItem item;
  final String studentId;

  const _PracticeItemTile({required this.item, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _toggleComplete(ref),
      // §7.132: 0.5px border → 1px ThinRule 정렬. priority dot/checkbox round → 사각.
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
        ),
        child: Row(
          children: [
            // Priority dot (사각 priority mark)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: item.priority.color),
            ),
            const SizedBox(width: AppSpacing.space2),

            // Checkbox
            GestureDetector(
              onTap: () => _toggleComplete(ref),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      item.isCompleted ? AppColors.paperOk : Colors.transparent,
                  border: Border.all(
                    color:
                        item.isCompleted
                            ? AppColors.paperOk
                            : AppColors.inkQuaternary,
                    width: 2,
                  ),
                ),
                child:
                    item.isCompleted
                        ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.paper,
                        )
                        : null,
              ),
            ),

            const SizedBox(width: AppSpacing.space3),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(
                            item.type,
                          ).withValues(alpha: 0.1),
                        ),
                        child: Text(
                          item.type.label,
                          style: AppTypography.captionSmall.copyWith(
                            color: _getTypeColor(item.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.hasLike) ...[
                        const SizedBox(width: AppSpacing.space2),
                        const Text('👍', style: TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    item.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          item.isCompleted ? TextDecoration.lineThrough : null,
                      color:
                          item.isCompleted
                              ? AppColors.inkTertiary
                              : AppColors.ink,
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.resourceIds.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space1),
                    ResourceAttachmentList(resourceIds: item.resourceIds),
                  ],
                ],
              ),
            ),

            // Practice count & increment/decrement buttons
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.practiceCount > 0 || item.isCompleted)
                      IconButton(
                        onPressed:
                            item.practiceCount > 0
                                ? () => _decrementCount(ref)
                                : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 20,
                        color:
                            item.practiceCount > 0
                                ? AppColors.inkSecondary
                                : AppColors.inkQuaternary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            item.practiceCount > 0
                                ? AppColors.paperAccentSoft
                                : AppColors.paperDark,
                      ),
                      child: Text(
                        '${item.practiceCount}회',
                        style: AppTypography.caption.copyWith(
                          color:
                              item.practiceCount > 0
                                  ? AppColors.paperAccent
                                  : AppColors.inkTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _incrementCount(ref),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 20,
                      color: AppColors.paperAccent,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(PracticeType type) {
    switch (type) {
      case PracticeType.repertoire:
        return AppColors.paperAccent;
      case PracticeType.technique:
        return AppColors.ink;
      case PracticeType.theory:
        return AppColors.paperOk;
      case PracticeType.custom:
        return AppColors.inkSecondary;
    }
  }

  Future<void> _toggleComplete(WidgetRef ref) async {
    await ref
        .read(studentPracticeNotifierProvider(studentId).notifier)
        .toggleComplete(item.id);
  }

  Future<void> _incrementCount(WidgetRef ref) async {
    await ref
        .read(studentPracticeNotifierProvider(studentId).notifier)
        .incrementCount(item.id);
  }

  Future<void> _decrementCount(WidgetRef ref) async {
    await ref
        .read(studentPracticeNotifierProvider(studentId).notifier)
        .decrementCount(item.id);
  }
}
