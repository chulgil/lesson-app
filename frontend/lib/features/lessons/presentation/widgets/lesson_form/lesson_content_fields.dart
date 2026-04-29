import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Lesson content input fields
class LessonContentFields extends StatelessWidget {
  final TextEditingController pieceController;
  final TextEditingController notesController;

  const LessonContentFields({
    super.key,
    required this.pieceController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Piece/Content
        TextFormField(
          controller: pieceController,
          decoration: InputDecoration(
            labelText: AppStrings.lessonSongLabel,
            hintText: AppStrings.lessonContentHint,
            prefixIcon: const Icon(Icons.music_note),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.paper,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Notes
        TextFormField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: AppStrings.memoLabel,
            hintText: AppStrings.lessonNoteHint,
            prefixIcon: const Icon(Icons.note_alt_outlined),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.paper,
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
