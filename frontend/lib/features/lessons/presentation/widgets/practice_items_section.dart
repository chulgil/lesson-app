import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/pencil_primitives.dart';
import '../../../../features/practice/domain/entities/practice_item.dart';
import '../../../practice/presentation/providers/practice_item_providers.dart';
import 'add_practice_item_sheet.dart';
import 'edit_practice_item_sheet.dart';
import 'resource_attachment_section.dart';

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
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space6),
              child: CircularProgressIndicator(),
            ),
          ),
      error:
          (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    '데이터를 불러오는데 실패했습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  TextButton.icon(
                    onPressed:
                        () => ref.invalidate(
                          practiceItemsNotifierProvider(lessonId),
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<PracticeItem> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar
        _buildSummaryBar(items),
        const SizedBox(height: AppSpacing.space4),

        // Flat list (no priority grouping)
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: _buildPracticeItemCard(context, ref, item),
          ),
        ),

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
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            isTeacher ? '이번 주 연습 과제를 추가해보세요' : '아직 연습 과제가 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
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
      decoration: BoxDecoration(color: AppColors.paperDark),
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
                  backgroundColor: AppColors.inkQuaternary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    rate >= 1.0 ? AppColors.paperOk : AppColors.paperAccent,
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
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeItemCard(
    BuildContext context,
    WidgetRef ref,
    PracticeItem item,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              isTeacher ? () => _showEditItemDialog(context, ref, item) : null,
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
                      // §7.130: 선생님 작성 과제 제목 → Tier 1 Gaegu hand.
                      Text(
                        item.title,
                        style: NotebookTypography.hand.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              item.isCompleted
                                  ? AppColors.inkTertiary
                                  : AppColors.ink,
                        ),
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.space1),
                        // §7.130: 선생님 작성 과제 설명 → Tier 1 Gaegu hand.
                        Text(
                          item.description!,
                          style: NotebookTypography.hand.copyWith(
                            fontSize: 13,
                            color:
                                item.isCompleted
                                    ? AppColors.inkTertiary
                                    : AppColors.inkSecondary,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Attached teaching resources
                      if (item.resourceIds.isNotEmpty)
                        ResourceAttachmentList(resourceIds: item.resourceIds),
                    ],
                  ),
                ),

                // Practice count
                if (item.practiceCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space2),
                    child: Text(
                      '${item.practiceCount}회',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),

                // Like button (teacher: interactive, student: read-only)
                if (isTeacher)
                  _buildLikeButton(ref, item)
                else if (item.hasLike)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space2),
                    child: const Text('👍', style: TextStyle(fontSize: 18)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCheckbox(WidgetRef ref, PracticeItem item) {
    // Notebook × Score: 연습 완료를 연필 사각 체크박스로 표시. 체크 색은 paperOk(녹색 펜).
    return GestureDetector(
      onTap: () => _toggleComplete(ref, item),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: PencilBox(
            checked: item.isCompleted,
            size: 20,
            checkColor: AppColors.paperOk,
          ),
        ),
      ),
    );
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

  Widget _buildLikeButton(WidgetRef ref, PracticeItem item) {
    return GestureDetector(
      onTap: () => _toggleLike(ref, item),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space1),
        decoration:
            item.hasLike
                ? BoxDecoration(
                  color: AppColors.paperAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                )
                : null,
        child: Text('👍', style: TextStyle(fontSize: item.hasLike ? 20 : 16)),
      ),
    );
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
      builder:
          (context) =>
              AddPracticeItemSheet(lessonId: lessonId, studentId: studentId),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    WidgetRef ref,
    PracticeItem item,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EditPracticeItemSheet(
            item: item,
            lessonId: lessonId,
            studentId: studentId,
          ),
    );
  }
}
