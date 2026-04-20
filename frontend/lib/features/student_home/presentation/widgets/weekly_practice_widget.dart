import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '데이터를 불러오는데 실패했습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton.icon(
            onPressed:
                () => ref.invalidate(weeklyPracticeItemsProvider(studentId)),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
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
              Text('이번 주 연습', style: AppTypography.headingMedium),
              if (onViewAll != null)
                TextButton(onPressed: onViewAll, child: const Text('전체보기')),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress header
              Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
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
                              padding: const EdgeInsets.only(right: 8),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                        child: LinearProgressIndicator(
                          value: total > 0 ? completed / total : 0,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation(
                            completed == total
                                ? AppColors.practiceGood
                                : AppColors.primary,
                          ),
                          minHeight: 8,
                        ),
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
          Text('이번 주 연습', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.space3),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.space6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  '아직 연습 과제가 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '선생님이 과제를 등록하면 여기에 표시됩니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
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
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(priority.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
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
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Priority dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.priority.color,
                shape: BoxShape.circle,
              ),
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
                      item.isCompleted
                          ? AppColors.practiceGood
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        item.isCompleted
                            ? AppColors.practiceGood
                            : AppColors.borderLight,
                    width: 2,
                  ),
                ),
                child:
                    item.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSmall,
                          ),
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
                              ? AppColors.textTertiaryLight
                              : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
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
                                ? AppColors.textSecondaryLight
                                : AppColors.borderLight,
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
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                      ),
                      child: Text(
                        '${item.practiceCount}회',
                        style: AppTypography.caption.copyWith(
                          color:
                              item.practiceCount > 0
                                  ? AppColors.primary
                                  : AppColors.textTertiaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _incrementCount(ref),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 20,
                      color: AppColors.primary,
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
        return AppColors.primary;
      case PracticeType.technique:
        return AppColors.secondary;
      case PracticeType.theory:
        return AppColors.info;
      case PracticeType.custom:
        return AppColors.textSecondaryLight;
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
