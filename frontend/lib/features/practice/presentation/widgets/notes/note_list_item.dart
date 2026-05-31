import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/swipe_action_tile.dart';
import '../../../domain/entities/entities.dart';

/// List item widget for displaying a practice note
class NoteListItem extends StatelessWidget {
  final PracticeNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.swipeActionEdit,
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        SwipeAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: onDelete,
        ),
      ],
      child: InkWell(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Time badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                    child: Text(
                      note.timeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (note.isEdited) ...[
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '(수정됨)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              // 연습노트 본문 = 학생 자필 → Tier 1 Gaegu hand
              // (README §1.1.1, §7.129 사용자 입력 정렬).
              Text(
                note.content,
                style: NotebookTypography.hand.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
