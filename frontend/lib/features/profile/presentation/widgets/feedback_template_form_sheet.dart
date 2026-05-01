import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/domain/entities/feedback_template.dart';
import '../../../lessons/presentation/providers/feedback_template_providers.dart';

/// Bottom sheet for creating or editing a [FeedbackTemplate].
///
/// `existing` null → add mode; non-null → edit mode.
class FeedbackTemplateFormSheet extends ConsumerStatefulWidget {
  const FeedbackTemplateFormSheet({super.key, this.existing});

  final FeedbackTemplate? existing;

  static Future<bool?> show(
    BuildContext context, {
    FeedbackTemplate? existing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedbackTemplateFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<FeedbackTemplateFormSheet> createState() =>
      _FeedbackTemplateFormSheetState();
}

class _FeedbackTemplateFormSheetState
    extends ConsumerState<FeedbackTemplateFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagsController;
  late FeedbackCategory _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _titleController = TextEditingController(text: t?.title ?? '');
    _bodyController = TextEditingController(text: t?.body ?? '');
    _tagsController = TextEditingController(text: t?.tags.join(', ') ?? '');
    _category = t?.category ?? FeedbackCategory.general;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLarge),
            ),
          ),
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.space2),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Row(
                  children: [
                    Text(
                      isEdit
                          ? AppStrings.feedbackTemplateEditTitle
                          : AppStrings.feedbackTemplateAddTitle,
                      style: AppTypography.headingSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form fields
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    _label(AppStrings.feedbackTemplateTitleLabel),
                    const SizedBox(height: AppSpacing.space2),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: AppStrings.feedbackTemplateTitleHint,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    _label(AppStrings.feedbackTemplateBodyLabel),
                    const SizedBox(height: AppSpacing.space2),
                    TextField(
                      controller: _bodyController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: AppStrings.feedbackTemplateBodyHint,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    _label(AppStrings.feedbackTemplateCategoryLabel),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children:
                          FeedbackCategory.values.map((c) {
                            final selected = _category == c;
                            return ChoiceChip(
                              label: Text(c.label),
                              selected: selected,
                              onSelected: (v) {
                                if (v) setState(() => _category = c);
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    _label(AppStrings.feedbackTemplateTagsLabel),
                    const SizedBox(height: AppSpacing.space2),
                    TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        hintText: AppStrings.feedbackTemplateTagsHint,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space6),
                  ],
                ),
              ),
              // Save button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.space2,
                    AppSpacing.screenPadding,
                    AppSpacing.space4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: FilledButton(
                      onPressed: _saving ? null : _onSave,
                      child: Text(_saving ? '...' : AppStrings.save),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
  );

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      _snack(AppStrings.feedbackTemplateValidateTitle);
      return;
    }
    if (body.isEmpty) {
      _snack(AppStrings.feedbackTemplateValidateBody);
      return;
    }

    final tags =
        _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    setState(() => _saving = true);
    final notifier = ref.read(feedbackTemplatesNotifierProvider.notifier);
    try {
      if (widget.existing == null) {
        await notifier.addTemplate(
          title: title,
          body: body,
          tags: tags,
          category: _category,
        );
        if (mounted) _snack(AppStrings.feedbackTemplateAddedSnack);
      } else {
        await notifier.updateTemplate(
          widget.existing!.copyWith(
            title: title,
            body: body,
            tags: tags,
            category: _category,
          ),
        );
        if (mounted) _snack(AppStrings.feedbackTemplateUpdatedSnack);
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
