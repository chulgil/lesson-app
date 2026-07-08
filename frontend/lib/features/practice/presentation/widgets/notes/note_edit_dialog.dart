import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
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
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                // Notebook × Score: Dialog 헤더 제목은 Playfair dialogTitle
                // 로 통일. isEditing 분기는 레이블만 교체.
                Text(
                  isEditing
                      ? AppStrings.practiceNoteEditTitle
                      : AppStrings.practiceNoteAddTitle,
                  style: NotebookTypography.dialogTitle,
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
              // 연습노트 = 학생 자필 본문 → Tier 1 Gaegu hand
              // (README §1.1.1, §7.129 사용자 입력 정렬).
              style: NotebookTypography.hand,
              decoration: InputDecoration(
                hintText: AppStrings.practiceNoteHint,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
                filled: true,
                fillColor: AppColors.paperDark,
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.paperAccent,
                    width: 2,
                  ),
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
                  // 테마 FilledButton.minimumSize=Size(∞,h) 가 Row(end) 의
                  // loose 폭과 충돌해 크래시하므로 0 폭으로 override.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeight),
                  ),
                  child: Text(isEditing ? AppStrings.modify : AppStrings.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
