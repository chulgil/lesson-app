import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/practice/domain/entities/practice_item.dart';
import '../../../practice/presentation/providers/practice_item_providers.dart';
import 'resource_attachment_section.dart';

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
  ConsumerState<EditPracticeItemSheet> createState() =>
      _EditPracticeItemSheetState();
}

class _EditPracticeItemSheetState extends ConsumerState<EditPracticeItemSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<String> _resourceIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _resourceIds = List<String>.from(widget.item.resourceIds);
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
        color: AppColors.paper,
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
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
              ),

              Row(
                children: [
                  // Notebook × Score §7.27: 바텀시트 제목 Playfair.
                  Text('연습 수정', style: NotebookTypography.sectionTitle),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : _delete,
                    child: Text(
                      '삭제',
                      style: TextStyle(color: AppColors.paperAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),

              // Completed item warning
              if (widget.item.isCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.ink),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          '학생이 이미 연습한 과제입니다',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Title
              Text(
                '제목',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Description
              Text(
                '설명 (선택)',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Resource attachments
              ResourceAttachmentEditor(
                resourceIds: _resourceIds,
                onChanged: (ids) => setState(() => _resourceIds = ids),
              ),
              const SizedBox(height: AppSpacing.space6),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(AppStrings.save),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updatedItem = widget.item.copyWith(
        title: title,
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        resourceIds: _resourceIds,
      );

      await ref
          .read(practiceItemsNotifierProvider(widget.lessonId).notifier)
          .updateItem(updatedItem);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('연습이 수정되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')));
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
      builder:
          (context) => AlertDialog(
            title: const Text('연습 삭제'),
            content: const Text('이 연습을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(AppStrings.delete),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('연습이 삭제되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
