import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_item.dart';
import '../../../../providers/providers.dart';
import 'add_practice_item_sheet.dart';
import 'edit_practice_item_sheet.dart';

/// Practice items section for lesson detail (teacher view)
class PracticeItemsSection extends ConsumerWidget {
  final String lessonId;
  final String studentId;
  final bool isTeacher;

  const PracticeItemsSection({
    super.key,
    required this.lessonId,
    required this.studentId,
    this.isTeacher = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(practiceItemsNotifierProvider(lessonId));

    return itemsAsync.when(
      data: (items) => _buildContent(context, ref, items),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space6),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space3),
              Text(
                '데이터를 불러오는데 실패했습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              TextButton.icon(
                onPressed: () => ref.invalidate(practiceItemsNotifierProvider(lessonId)),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<PracticeItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    final grouped = items.groupByPriority();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar
        _buildSummaryBar(items),
        const SizedBox(height: AppSpacing.space4),

        // Priority sections
        for (final priority in PracticePriority.values)
          if (grouped[priority]?.isNotEmpty == true) ...[
            _buildPrioritySection(context, ref, priority, grouped[priority]!),
            const SizedBox(height: AppSpacing.space4),
          ],

        // Add button (teacher only)
        if (isTeacher) ...[
          const SizedBox(height: AppSpacing.space2),
          _buildAddButton(context, ref),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            isTeacher ? '이번 주 연습 과제를 추가해보세요' : '아직 연습 과제가 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (isTeacher) ...[
            const SizedBox(height: AppSpacing.space4),
            FilledButton.icon(
              onPressed: () => _showAddItemDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('연습 추가'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBar(List<PracticeItem> items) {
    final completed = items.where((i) => i.isCompleted).length;
    final total = items.length;
    final rate = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          // Progress indicator
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    rate >= 1.0 ? AppColors.practiceGood : AppColors.primary,
                  ),
                  strokeWidth: 4,
                ),
                Text(
                  '${(rate * 100).toInt()}%',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 주 연습',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$completed / $total 완료',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Priority counts
          Row(
            children: [
              _buildPriorityDot(PracticePriority.must, items),
              const SizedBox(width: AppSpacing.space2),
              _buildPriorityDot(PracticePriority.should, items),
              const SizedBox(width: AppSpacing.space2),
              _buildPriorityDot(PracticePriority.could, items),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDot(PracticePriority priority, List<PracticeItem> items) {
    final count = items.where((i) => i.priority == priority).length;
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priority.color,
              shape: BoxShape.circle,
            ),
          ),
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

  Widget _buildPrioritySection(
    BuildContext context,
    WidgetRef ref,
    PracticePriority priority,
    List<PracticeItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              priority.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              priority.label,
              style: AppTypography.bodyMedium.copyWith(
                color: priority.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '${items.length}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        // Items
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: _buildPracticeItemCard(context, ref, item),
            )),
      ],
    );
  }

  Widget _buildPracticeItemCard(
    BuildContext context,
    WidgetRef ref,
    PracticeItem item,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: item.isCompleted
              ? AppColors.practiceGood.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          onTap: isTeacher ? () => _showEditItemDialog(context, ref, item) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Row(
              children: [
                // Completion checkbox
                _buildCompletionCheckbox(ref, item),
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
                              color: _getTypeColor(item.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.type.label,
                              style: AppTypography.caption.copyWith(
                                color: _getTypeColor(item.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          // Priority dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.priority.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        item.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          color: item.isCompleted
                              ? AppColors.textTertiaryLight
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          item.description!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Practice count & teacher feedback
                Column(
                  children: [
                    if (item.practiceCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.practiceCount}회',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (item.hasLike) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Icon(
                        Icons.favorite,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),

                // Teacher actions
                if (isTeacher && item.isCompleted && !item.hasLike)
                  IconButton(
                    onPressed: () => _toggleLike(ref, item),
                    icon: const Icon(Icons.favorite_border),
                    iconSize: 22,
                    color: AppColors.textTertiaryLight,
                    tooltip: '좋아요',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCheckbox(WidgetRef ref, PracticeItem item) {
    return GestureDetector(
      onTap: () => _toggleComplete(ref, item),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: item.isCompleted ? AppColors.practiceGood : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: item.isCompleted ? AppColors.practiceGood : AppColors.borderLight,
            width: 2,
          ),
        ),
        child: item.isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
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

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showAddItemDialog(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('연습 추가'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _toggleComplete(WidgetRef ref, PracticeItem item) async {
    await ref
        .read(practiceItemsNotifierProvider(lessonId).notifier)
        .toggleComplete(item.id, studentId);
  }

  Future<void> _toggleLike(WidgetRef ref, PracticeItem item) async {
    await ref
        .read(practiceItemsNotifierProvider(lessonId).notifier)
        .toggleLike(item.id, studentId);
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPracticeItemSheet(
        lessonId: lessonId,
        studentId: studentId,
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, WidgetRef ref, PracticeItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPracticeItemSheet(
        item: item,
        lessonId: lessonId,
        studentId: studentId,
      ),
    );
  }
}
