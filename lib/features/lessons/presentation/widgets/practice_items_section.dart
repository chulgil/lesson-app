import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_item.dart';
import '../../../../models/practice_repertoire.dart';
import '../../../../providers/providers.dart';

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

/// Bottom sheet for adding new practice item
class AddPracticeItemSheet extends ConsumerStatefulWidget {
  final String lessonId;
  final String studentId;

  const AddPracticeItemSheet({
    super.key,
    required this.lessonId,
    required this.studentId,
  });

  @override
  ConsumerState<AddPracticeItemSheet> createState() => _AddPracticeItemSheetState();
}

class _AddPracticeItemSheetState extends ConsumerState<AddPracticeItemSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pieceNameController = TextEditingController();
  final _startMeasureController = TextEditingController();
  final _endMeasureController = TextEditingController();
  final _newRepertoireNameController = TextEditingController();

  PracticeType _selectedType = PracticeType.repertoire;
  PracticePriority _selectedPriority = PracticePriority.should;
  bool _isSubmitting = false;

  // Repertoire selection state
  PracticeRepertoire? _selectedRepertoire;
  bool _isCreatingNewRepertoire = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pieceNameController.dispose();
    _startMeasureController.dispose();
    _endMeasureController.dispose();
    _newRepertoireNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch student's existing repertoires
    final repertoiresAsync = ref.watch(studentRepertoiresProvider(widget.studentId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('연습 추가', style: AppTypography.headingMedium),
              const SizedBox(height: AppSpacing.space4),

              // Type selector
              Text('유형', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                children: PracticeType.values.map((type) {
                  final selected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      _selectedType = type;
                      // Reset repertoire selection when type changes
                      if (type != PracticeType.repertoire) {
                        _selectedRepertoire = null;
                        _isCreatingNewRepertoire = false;
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Priority selector
              Text('우선순위', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                children: PracticePriority.values.map((priority) {
                  final selected = priority == _selectedPriority;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(priority.emoji),
                        const SizedBox(width: 4),
                        Text(priority.label),
                      ],
                    ),
                    selected: selected,
                    selectedColor: priority.color.withValues(alpha: 0.2),
                    onSelected: (value) => setState(() => _selectedPriority = priority),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Repertoire selection (only for repertoire type)
              if (_selectedType == PracticeType.repertoire)
                _buildRepertoireSection(repertoiresAsync),

              // Title (for non-repertoire types or manual input)
              if (_selectedType != PracticeType.repertoire) ...[
                Text('제목', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.space2),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: _getTitleHint(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Description
              Text('설명 (선택)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '예: 메트로놈 60으로 정확하게!',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('추가'),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleHint() {
    switch (_selectedType) {
      case PracticeType.technique:
        return '예: G Major 스케일 3옥타브';
      case PracticeType.theory:
        return '예: 음정 퀴즈 복습';
      case PracticeType.custom:
        return '예: 손목 스트레칭';
      default:
        return '예: 도레미송 1-8마디';
    }
  }

  Widget _buildRepertoireSection(AsyncValue<List<PracticeRepertoire>> repertoiresAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Repertoire selection
        Text('레퍼토리', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.space2),

        repertoiresAsync.when(
          data: (repertoires) => _buildRepertoireSelector(repertoires),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text(
              '레퍼토리를 불러올 수 없습니다',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // New repertoire name input (if creating new)
        if (_isCreatingNewRepertoire) ...[
          Text('새 레퍼토리 이름', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _newRepertoireNameController,
            decoration: InputDecoration(
              hintText: '예: 스즈키 5권',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Piece name and measure range
        Text('곡 정보', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _pieceNameController,
          decoration: InputDecoration(
            hintText: '곡명 (예: 라폴리아)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _startMeasureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '시작 마디',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
              child: Text('~', style: AppTypography.bodyLarge),
            ),
            Expanded(
              child: TextField(
                controller: _endMeasureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '끝 마디',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildRepertoireSelector(List<PracticeRepertoire> repertoires) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          // Existing repertoires
          ...repertoires.map((repertoire) {
            final isSelected = _selectedRepertoire?.id == repertoire.id && !_isCreatingNewRepertoire;
            return InkWell(
              onTap: () => setState(() {
                _selectedRepertoire = repertoire;
                _isCreatingNewRepertoire = false;
              }),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          width: 2,
                        ),
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repertoire.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (repertoire.sections.isNotEmpty)
                            Text(
                              '${repertoire.sections.length}개 섹션',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Create new repertoire option
          InkWell(
            onTap: () => setState(() {
              _selectedRepertoire = null;
              _isCreatingNewRepertoire = true;
            }),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: _isCreatingNewRepertoire ? AppColors.secondary.withValues(alpha: 0.1) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isCreatingNewRepertoire ? AppColors.secondary : AppColors.borderLight,
                        width: 2,
                      ),
                      color: _isCreatingNewRepertoire ? AppColors.secondary : Colors.transparent,
                    ),
                    child: _isCreatingNewRepertoire
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: _isCreatingNewRepertoire ? AppColors.secondary : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '새 레퍼토리 만들기',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _isCreatingNewRepertoire ? AppColors.secondary : AppColors.textSecondaryLight,
                      fontWeight: _isCreatingNewRepertoire ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Validate based on type
    if (_selectedType == PracticeType.repertoire) {
      if (!_isCreatingNewRepertoire && _selectedRepertoire == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('레퍼토리를 선택해주세요')),
        );
        return;
      }
      if (_isCreatingNewRepertoire && _newRepertoireNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새 레퍼토리 이름을 입력해주세요')),
        );
        return;
      }
      if (_pieceNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('곡명을 입력해주세요')),
        );
        return;
      }
      final startMeasure = int.tryParse(_startMeasureController.text.trim());
      final endMeasure = int.tryParse(_endMeasureController.text.trim());
      if (startMeasure == null || endMeasure == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마디 번호를 입력해주세요')),
        );
        return;
      }
      if (startMeasure > endMeasure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시작 마디가 끝 마디보다 클 수 없습니다')),
        );
        return;
      }
    } else {
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제목을 입력해주세요')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final teacherId = ref.read(currentTeacherIdProvider);

      String title;
      String? repertoireId;
      String? sectionId;

      if (_selectedType == PracticeType.repertoire) {
        // Handle repertoire type
        final pieceName = _pieceNameController.text.trim();
        final startMeasure = int.parse(_startMeasureController.text.trim());
        final endMeasure = int.parse(_endMeasureController.text.trim());

        // Create or get repertoire
        PracticeRepertoire repertoire;
        if (_isCreatingNewRepertoire) {
          repertoire = await ref.read(repertoireCrudProvider.notifier).createRepertoire(
            studentId: widget.studentId,
            name: _newRepertoireNameController.text.trim(),
          );
        } else {
          repertoire = _selectedRepertoire!;
        }
        repertoireId = repertoire.id;

        // Create section in repertoire
        final section = await ref.read(sectionCrudProvider.notifier).createSection(
          repertoireId: repertoireId,
          pieceName: pieceName,
          startMeasure: startMeasure,
          endMeasure: endMeasure,
        );
        sectionId = section.id;

        // Build title: "곡명 - 시작~끝 마디"
        title = '$pieceName $startMeasure~$endMeasure마디';
      } else {
        title = _titleController.text.trim();
      }

      // Create practice item
      await ref.read(practiceItemsNotifierProvider(widget.lessonId).notifier).addItem(
        studentId: widget.studentId,
        teacherId: teacherId,
        type: _selectedType,
        title: title,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        priority: _selectedPriority,
        repertoireId: repertoireId,
        sectionId: sectionId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedType == PracticeType.repertoire
                ? '연습이 추가되고 학생 연습장에 등록되었습니다'
                : '연습이 추가되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Bottom sheet for editing practice item
class EditPracticeItemSheet extends ConsumerStatefulWidget {
  final PracticeItem item;
  final String lessonId;
  final String studentId;

  const EditPracticeItemSheet({
    super.key,
    required this.item,
    required this.lessonId,
    required this.studentId,
  });

  @override
  ConsumerState<EditPracticeItemSheet> createState() => _EditPracticeItemSheetState();
}

class _EditPracticeItemSheetState extends ConsumerState<EditPracticeItemSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late PracticeType _selectedType;
  late PracticePriority _selectedPriority;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _selectedType = widget.item.type;
    _selectedPriority = widget.item.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Text('연습 수정', style: AppTypography.headingMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : _delete,
                    child: Text(
                      '삭제',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),

              // Type selector
              Text('유형', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                children: PracticeType.values.map((type) {
                  final selected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (value) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Priority selector
              Text('우선순위', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                children: PracticePriority.values.map((priority) {
                  final selected = priority == _selectedPriority;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(priority.emoji),
                        const SizedBox(width: 4),
                        Text(priority.label),
                      ],
                    ),
                    selected: selected,
                    selectedColor: priority.color.withValues(alpha: 0.2),
                    onSelected: (value) => setState(() => _selectedPriority = priority),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Title
              Text('제목', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Description
              Text('설명 (선택)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장'),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updatedItem = widget.item.copyWith(
        type: _selectedType,
        priority: _selectedPriority,
        title: title,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      await ref
          .read(practiceItemsNotifierProvider(widget.lessonId).notifier)
          .updateItem(updatedItem);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연습이 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연습 삭제'),
        content: const Text('이 연습을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(practiceItemsNotifierProvider(widget.lessonId).notifier)
          .deleteItem(widget.item.id, widget.studentId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연습이 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
