import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/entities.dart';

/// Dialog for adding or editing a practice note
class NoteEditDialog extends StatefulWidget {
  final PracticeNote? existingNote;

  const NoteEditDialog({super.key, this.existingNote});

  @override
  State<NoteEditDialog> createState() => _NoteEditDialogState();

  /// Show the dialog and return the content if saved, null if cancelled
  static Future<String?> show(
    BuildContext context, {
    PracticeNote? existingNote,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => NoteEditDialog(existingNote: existingNote),
    );
  }
}

class _NoteEditDialogState extends State<NoteEditDialog> {
  late final TextEditingController _controller;
  bool _hasContent = false;

  bool get isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
    _hasContent = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasContent = _controller.text.trim().isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  void _save() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    Navigator.of(context).pop(content);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Text(
                  isEditing ? '연습노트 수정' : '연습노트 추가',
                  style: AppTypography.headingSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // Text field
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              autofocus: true,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '연습하면서 느낀 점을 기록하세요...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                filled: true,
                fillColor: AppColors.surfaceSecondaryLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.space3),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                const SizedBox(width: AppSpacing.space2),
                FilledButton(
                  onPressed: _hasContent ? _save : null,
                  child: Text(isEditing ? '수정' : '저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
