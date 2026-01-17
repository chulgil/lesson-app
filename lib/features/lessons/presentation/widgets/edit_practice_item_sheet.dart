import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_item.dart';
import '../../../../providers/providers.dart';

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
