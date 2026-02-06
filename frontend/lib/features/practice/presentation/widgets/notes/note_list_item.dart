import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
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
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
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
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    note.timeText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (note.isEdited) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '(수정됨)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
                const Spacer(),
                // More menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textSecondaryLight,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text('삭제',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            // Note content
            Text(
              note.content,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
