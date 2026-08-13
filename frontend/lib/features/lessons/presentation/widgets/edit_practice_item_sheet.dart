import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_alert_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../practice/practice_facade.dart' show PracticeItem;
import '../providers/lesson_widget_support_provider.dart';
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
        borderRadius: BorderRadius.zero,
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
                  Text(
                    AppStrings.editPracticeItemTitle,
                    style: NotebookTypography.sectionTitle,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : _delete,
                    child: Text(
                      AppStrings.delete,
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
                    color: AppColors.inkSoft,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.ink),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          AppStrings.practiceItemAlreadyDoneWarning,
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
                AppStrings.titleLabel,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              // §7.130: 선생님 작성 과제 제목 → Tier 1 Gaegu hand.
              TextField(
                controller: _titleController,
                style: NotebookTypography.hand.copyWith(color: AppColors.ink),
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Description
              Text(
                AppStrings.descriptionOptional,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              // §7.130: 선생님 작성 과제 설명 → Tier 1 Gaegu hand.
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                style: NotebookTypography.hand.copyWith(color: AppColors.ink),
                decoration: InputDecoration(border: OutlineInputBorder()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.enterTitleValidation)),
      );
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
          .read(lessonWidgetPracticeItemActionsProvider(widget.lessonId))
          .updateItem(updatedItem);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.practiceItemUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.errorTryAgain)));
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
          (context) => NotebookAlertDialog(
            title: const Text(AppStrings.deletePracticeItemTitle),
            content: const Text(AppStrings.deletePracticeItemConfirm),
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
          .read(lessonWidgetPracticeItemActionsProvider(widget.lessonId))
          .deleteItem(widget.item.id, widget.studentId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.practiceItemDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.errorTryAgain)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
